import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

/// Alias to preserve compatibility with task names and docs.
typedef TotalParser = TotalsParser;

/// Extraction result of totals from a receipt.
final class TotalsResult {
  /// Valor subtotal (soma dos itens antes de descontos), se presente.
  final Money? subtotal;

  /// Valor do desconto total concedido, se presente (sempre positivo).
  final Money? discount;

  /// Valor total a pagar / pago no cupom fiscal.
  final Money? total;

  /// Payment method used (e.g. "DINHEIRO", "CARTAO DE DEBITO", "CARTAO DE CREDITO", "PIX", "VALE ALIMENTACAO").
  final String? paymentMethod;

  /// Mean confidence of elements/lines used in extracting totals.
  /// Returns 0.0 if no total is found or document is empty.
  final double confidence;

  const TotalsResult({
    this.subtotal,
    this.discount,
    this.total,
    this.paymentMethod,
    this.confidence = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TotalsResult &&
          runtimeType == other.runtimeType &&
          subtotal == other.subtotal &&
          discount == other.discount &&
          total == other.total &&
          paymentMethod == other.paymentMethod &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      Object.hash(subtotal, discount, total, paymentMethod, confidence);

  @override
  String toString() =>
      'TotalsResult(subtotal: $subtotal, discount: $discount, total: $total, '
      'paymentMethod: $paymentMethod, confidence: ${confidence.toStringAsFixed(2)})';
}

/// Pure parser responsible for identifying and extracting totals (subtotal,
/// desconto, total pago) e a forma de pagamento de cupons fiscais
/// (RF-041, RN-193, CA-2.4).
final class TotalsParser {
  const TotalsParser();

  /// Extrai os totais a partir de um [OcrDocument].
  TotalsResult parseDocument(OcrDocument doc) {
    if (doc.lines.isEmpty) return const TotalsResult(confidence: 0.0);
    const detector = ColumnDetector();
    final rows = detector.detectRows(doc);
    return parseRows(rows);
  }

  /// Extrai os totais a partir de uma lista de linhas visuais ([OcrRow]).
  TotalsResult parseRows(List<OcrRow> rows) {
    if (rows.isEmpty) return const TotalsResult(confidence: 0.0);

    Money? subtotal;
    Money? discount;
    Money? total;
    String? paymentMethod;

    final confidences = <double>[];

    // Candidate selection for Total
    _TotalCandidate? totalCandidate;
    _SubtotalCandidate? subtotalCandidate;
    _DiscountCandidate? discountCandidate;
    _PaymentCandidate? paymentCandidate;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final text = row.text.trim();
      if (text.isEmpty) continue;

      final upperText = text.toUpperCase();

      // 1. Verificar Desconto
      if (_isDiscountLine(upperText)) {
        final extracted = _extractMoneyFromRow(row);
        if (extracted != null) {
          final absMoney = Money(extracted.cents.abs());
          final score = _scoreDiscountLine(upperText);
          if (discountCandidate == null || score > discountCandidate.score) {
            discountCandidate = _DiscountCandidate(
              money: absMoney,
              confidence: row.averageConfidence,
              score: score,
            );
          }
        }
      }

      // 2. Verificar Subtotal
      if (_isSubtotalLine(upperText)) {
        final extracted = _extractMoneyFromRow(row);
        if (extracted != null) {
          final score = _scoreSubtotalLine(upperText);
          if (subtotalCandidate == null || score > subtotalCandidate.score) {
            subtotalCandidate = _SubtotalCandidate(
              money: extracted,
              confidence: row.averageConfidence,
              score: score,
            );
          }
        }
      }

      // 3. Verificar Total
      if (_isTotalLine(upperText)) {
        var extracted = _extractMoneyFromRow(row);
        if (extracted == null && i + 1 < rows.length) {
          final nextRow = rows[i + 1];
          final nextUpper = nextRow.text.toUpperCase();
          if (!_isNegatedTotalLine(nextUpper) &&
              !_isDiscountLine(nextUpper) &&
              !_isSubtotalLine(nextUpper)) {
            extracted = _extractMoneyFromRow(nextRow);
          }
        }
        if (extracted != null && extracted.cents > 0) {
          final score = _scoreTotalLine(upperText);
          if (totalCandidate == null ||
              score > totalCandidate.score ||
              (score >= totalCandidate.score - 20 &&
                  extracted.cents > totalCandidate.money.cents &&
                  extracted.cents % 100 == totalCandidate.money.cents % 100)) {
            totalCandidate = _TotalCandidate(
              money: extracted,
              confidence: row.averageConfidence,
              score: score,
              lineIndex: i,
            );
          }
        }
      }

      // 4. Verificar Forma de Pagamento
      final method = _extractPaymentMethod(upperText);
      if (method != null) {
        final score = _scorePaymentLine(upperText);
        if (paymentCandidate == null || score > paymentCandidate.score) {
          paymentCandidate = _PaymentCandidate(
            method: method,
            confidence: row.averageConfidence,
            score: score,
          );
        }
        if (totalCandidate == null) {
          final paidAmount = _extractMoneyFromRow(row);
          if (paidAmount != null && paidAmount.cents > 0) {
            totalCandidate = _TotalCandidate(
              money: paidAmount,
              confidence: row.averageConfidence,
              score: 50,
              lineIndex: i,
            );
          }
        }
      }
    }

    // Fallback for Total if there is a value line right after discount or at end of totals
    if (totalCandidate == null && discountCandidate != null) {
      for (var i = rows.length - 1; i >= 0; i--) {
        final row = rows[i];
        final upperText = row.text.toUpperCase();
        if (_isNegatedTotalLine(upperText)) continue;
        final extracted = _extractMoneyFromRow(row);
        if (extracted != null) {
          totalCandidate = _TotalCandidate(
            money: extracted,
            confidence: row.averageConfidence,
            score: 10,
            lineIndex: i,
          );
          break;
        }
      }
    }

    if (subtotalCandidate != null) {
      subtotal = subtotalCandidate.money;
      confidences.add(subtotalCandidate.confidence);
    }

    if (discountCandidate != null) {
      discount = discountCandidate.money;
      confidences.add(discountCandidate.confidence);
    }

    if (totalCandidate != null) {
      total = totalCandidate.money;
      confidences.add(totalCandidate.confidence);
    }

    if (paymentCandidate != null) {
      paymentMethod = paymentCandidate.method;
      confidences.add(paymentCandidate.confidence);
    }

    final double confidence = confidences.isNotEmpty
        ? confidences.reduce((a, b) => a + b) / confidences.length
        : 0.0;

    return TotalsResult(
      subtotal: subtotal,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      confidence: confidence,
    );
  }

  /// Extrai os totais a partir de uma lista de [OcrTextLine]s.
  TotalsResult parseLines(List<OcrTextLine> lines) {
    if (lines.isEmpty) return const TotalsResult(confidence: 0.0);
    const detector = ColumnDetector();
    final rows = detector.groupLinesIntoRows(lines);
    return parseRows(rows);
  }

  /// Extrai os totais a partir de um texto puro.
  TotalsResult parseText(String text) {
    if (text.trim().isEmpty) return const TotalsResult(confidence: 0.0);
    final rawLines = text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final lines = <OcrTextLine>[];
    for (var i = 0; i < rawLines.length; i++) {
      lines.add(
        OcrTextLine(
          text: rawLines[i],
          boundingBox: OcrBoundingBox(
            top: i * 30.0,
            left: 10.0,
            right: 300.0,
            bottom: (i * 30.0) + 20.0,
          ),
          confidence: 1.0,
        ),
      );
    }
    return parseLines(lines);
  }

  // ---------------------------------------------------------------------------
  // Auxiliares de parsing de Money
  // ---------------------------------------------------------------------------

  static Money? _extractMoneyFromRow(OcrRow row) {
    // 1. Tentar primeiro no segmento da direita, se existir
    final rightSeg = row.rightSegment;
    if (rightSeg != null) {
      final m = _extractMoney(rightSeg.text);
      if (m != null) return m;
    }

    // 2. Tentar no texto completo da linha
    return _extractMoney(row.text);
  }

  static Money? _extractMoney(String rawText) {
    if (rawText.trim().isEmpty) return null;
    final text = rawText.replaceAllMapped(
      RegExp(r'(?<![A-Za-z])[Zz](?=\d+[,\.]\d{2})'),
      (_) => '2',
    );

    // 1. pt-BR format with comma (e.g. R$ 87.40 | 87,40 | 1.234,56 | -3,00 | 3,00-)
    final brRegex = RegExp(
      r'(\-?\s*\(?\s*(?:R\$\s*)?(\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{2})\s*\)?\-?)',
      caseSensitive: false,
    );
    final match = brRegex.firstMatch(text);
    if (match != null) {
      final rawMatch = match.group(1)!;
      final isNegative =
          rawMatch.contains('-') ||
          (rawMatch.startsWith('(') && rawMatch.endsWith(')'));

      final clean = rawMatch
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll(RegExp(r'R\$\s*'), '')
          .trim();

      final parsed = Money.tryParsePtBr(clean);
      if (parsed != null) {
        return isNegative ? Money(-parsed.cents) : parsed;
      }
    }

    // 2. Fallback to period as decimal separator if no comma (e.g. 87.40)
    final dotRegex = RegExp(
      r'(\-?\s*(?:R\$\s*)?(\d+\.\d{2}))\b',
      caseSensitive: false,
    );
    final dotMatch = dotRegex.firstMatch(text);
    if (dotMatch != null) {
      final rawMatch = dotMatch.group(1)!;
      final isNegative = rawMatch.contains('-');
      var clean = rawMatch
          .replaceAll('-', '')
          .replaceAll(RegExp(r'R\$\s*'), '')
          .trim();
      clean = clean.replaceAll('.', ',');
      final parsed = Money.tryParsePtBr(clean);
      if (parsed != null) {
        return isNegative ? Money(-parsed.cents) : parsed;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Line Checks and Scores
  // ---------------------------------------------------------------------------

  static bool _isTotalLine(String text) {
    if (_isNegatedTotalLine(text)) return false;
    return text.contains('TOTAL') ||
        text.contains('VALOR A PAGAR') ||
        text.contains('UALOR A PAGAR') ||
        text.contains('A PAGAR R\$') ||
        text.contains('PAGAR R\$') ||
        text.contains('PASUR') ||
        text.contains('PAGUR') ||
        text.contains('VALOR PAGO') ||
        text.contains('UALOR PAGO') ||
        text.contains('URLOR PAGO') ||
        text.contains('UALUR PAGO') ||
        text.contains('VALOH PALC') ||
        text.contains('VALOR TOAL') ||
        text.contains('VL. PAGO') ||
        text.contains('VL PAGO') ||
        text.contains('VLR PAGO') ||
        text.contains('VLR. PAGO') ||
        text.contains('VALOR RECEBIDO') ||
        text.contains('VALOR FINAL') ||
        text.contains('TTL R\$') ||
        text.contains('VLR TOTAL');
  }

  static bool _isNegatedTotalLine(String text) {
    return text.contains('SUBTOTAL') ||
        text.contains('SUB TOTAL') ||
        text.contains('SUB-TOTAL') ||
        text.contains('TOTAL BRUTO') ||
        text.contains('DESCONTO') ||
        text.contains('DESC.') ||
        text.contains('QTD') ||
        text.contains('QUANTIDADE') ||
        text.contains('ITENS') ||
        text.contains('TROCO') ||
        text.contains('CANCELADO') ||
        text.contains('TRIBUTO') ||
        text.contains('IMPOSTO') ||
        text.contains('IBPT');
  }

  static int _scoreTotalLine(String text) {
    var score = 10;
    if (text.contains('VALOR A PAGAR') ||
        text.contains('UALOR A PAGAR') ||
        text.contains('A PAGAR R\$') ||
        text.contains('PAGAR R\$') ||
        text.contains('TOTAL A PAGAR') ||
        text.contains('TOTAL LIQUIDO') ||
        text.contains('TOTAL LÍQUIDO') ||
        text.contains('VALOR LIQUIDO') ||
        text.contains('VALOR LÍQUIDO')) {
      score += 100;
    } else if (text.contains('VALOR PAGO') ||
        text.contains('UALOR PAGO') ||
        text.contains('URLOR PAGO') ||
        text.contains('UALUR PAGO') ||
        text.contains('VALOH PALC') ||
        text.contains('VL. PAGO') ||
        text.contains('VL PAGO') ||
        text.contains('VLR PAGO') ||
        text.contains('VLR. PAGO') ||
        text.contains('VALOR RECEBIDO') ||
        text.contains('VALOR TOTAL') ||
        text.contains('VALOR TOAL')) {
      score += 80;
    } else if (text.contains('TOTAL R\$') || text.contains('TOTAL:')) {
      score += 60;
    } else if (text.contains('TOTAL')) {
      score += 40;
    }
    return score;
  }

  static bool _isSubtotalLine(String text) {
    if (text.contains('DESCONTO') || text.contains('DESC.')) return false;
    return text.contains('SUBTOTAL') ||
        text.contains('SUB TOTAL') ||
        text.contains('SUB-TOTAL') ||
        text.contains('TOTAL BRUTO') ||
        text.contains('VALOR BRUTO') ||
        text.contains('TOTAL DOS ITENS') ||
        text.contains('SOMA DOS ITENS') ||
        text.contains('SOMA R\$');
  }

  static int _scoreSubtotalLine(String text) {
    var score = 10;
    if (text.contains('SUBTOTAL') ||
        text.contains('SUB TOTAL') ||
        text.contains('SUB-TOTAL')) {
      score += 100;
    } else if (text.contains('TOTAL BRUTO') || text.contains('VALOR BRUTO')) {
      score += 80;
    } else if (text.contains('TOTAL DOS ITENS')) {
      score += 60;
    }
    return score;
  }

  static bool _isDiscountLine(String text) {
    if (text.contains('SEM DESCONTO')) return false;
    return text.contains('DESCONTO') ||
        text.contains('DESC.') ||
        text.contains('DESC ') ||
        text.contains('DESC:') ||
        text.contains('ABATIMENTO') ||
        text.contains('(-) DESCONTO') ||
        text.contains('DESC TOTAL');
  }

  static int _scoreDiscountLine(String text) {
    var score = 10;
    if (text.contains('DESCONTO TOTAL') ||
        text.contains('DESC TOTAL') ||
        text.contains('DESCONTO R\$') ||
        text.contains('(-) DESCONTO')) {
      score += 100;
    } else if (text.contains('DESCONTO') || text.contains('ABATIMENTO')) {
      score += 80;
    } else if (text.contains('DESC.')) {
      score += 50;
    }
    return score;
  }

  static String? _extractPaymentMethod(String text) {
    // 1. Debit
    if (text.contains('CARTAO DE DEBITO') ||
        text.contains('CARTÃO DE DÉBITO') ||
        text.contains('CARTAO DEBITO') ||
        text.contains('CARTÃO DÉBITO') ||
        text.contains('C. DEBITO') ||
        text.contains('C DEBITO') ||
        text.contains('C.DEBITO') ||
        (text.contains('DEBITO') && !text.contains('CREDITO')) ||
        (text.contains('DÉBITO') && !text.contains('CRÉDITO'))) {
      return 'CARTÃO DE DÉBITO';
    }

    // 2. Credit
    if (text.contains('CARTAO DE CREDITO') ||
        text.contains('CARTÃO DE CRÉDITO') ||
        text.contains('CARTAO CREDITO') ||
        text.contains('CARTÃO CRÉDITO') ||
        text.contains('C. CREDITO') ||
        text.contains('C CREDITO') ||
        text.contains('C.CREDITO') ||
        text.contains('CREDITO') ||
        text.contains('CRÉDITO')) {
      return 'CARTÃO DE CRÉDITO';
    }

    // 3. Dinheiro
    if (text.contains('DINHEIRO') ||
        text.contains('ESPECIE') ||
        text.contains('ESPÉCIE') ||
        text.contains('EM DINHEIRO')) {
      return 'DINHEIRO';
    }

    // 4. Pix
    if (text.contains('PIX')) {
      return 'PIX';
    }

    // 5. Food Voucher
    if (text.contains('VALE ALIMENTACAO') ||
        text.contains('VALE ALIMENTAÇÃO') ||
        text.contains('ALIMENTACAO') ||
        text.contains('ALIMENTAÇÃO') ||
        text.contains('V.A.') ||
        text.contains(' V.A ') ||
        text.contains(' VA ')) {
      return 'VALE ALIMENTAÇÃO';
    }

    // 6. Meal Voucher
    if (text.contains('VALE REFEICAO') ||
        text.contains('VALE REFEIÇÃO') ||
        text.contains('REFEICAO') ||
        text.contains('REFEIÇÃO') ||
        text.contains('V.R.') ||
        text.contains(' V.R ') ||
        text.contains(' VR ')) {
      return 'VALE REFEIÇÃO';
    }

    // 7. Isolated card brands and E-Commerce
    if (text.contains('MASTERCARD') ||
        text.contains('MASTER CARD') ||
        text.contains('VISA') ||
        text.contains('ELO') ||
        text.contains('HIPERCARD') ||
        text.contains('AMEX') ||
        text.contains('E COMMERCE') ||
        text.contains('E-COMMERCE') ||
        text.contains('E CONNERCE')) {
      return 'CARTÃO';
    }

    // 8. Check / Bank transfer
    if (text.contains('CHEQUE')) return 'CHEQUE';
    if (text.contains('TRANSFERENCIA') || text.contains('TRANSFERÊNCIA')) {
      return 'TRANSFERÊNCIA';
    }

    return null;
  }

  static int _scorePaymentLine(String text) {
    var score = 10;
    if (text.contains('FORMA DE PAGAMENTO') ||
        text.contains('FORMA PAGTO') ||
        text.contains('FORMA DE PGTO') ||
        text.contains('PAGAMENTO:')) {
      score += 100;
    } else if (text.contains('CARTAO') ||
        text.contains('CARTÃO') ||
        text.contains('DINHEIRO') ||
        text.contains('PIX')) {
      score += 60;
    }
    return score;
  }
}

class _TotalCandidate {
  final Money money;
  final double confidence;
  final int score;
  final int lineIndex;

  const _TotalCandidate({
    required this.money,
    required this.confidence,
    required this.score,
    required this.lineIndex,
  });
}

class _SubtotalCandidate {
  final Money money;
  final double confidence;
  final int score;

  const _SubtotalCandidate({
    required this.money,
    required this.confidence,
    required this.score,
  });
}

class _DiscountCandidate {
  final Money money;
  final double confidence;
  final int score;

  const _DiscountCandidate({
    required this.money,
    required this.confidence,
    required this.score,
  });
}

class _PaymentCandidate {
  final String method;
  final double confidence;
  final int score;

  const _PaymentCandidate({
    required this.method,
    required this.confidence,
    required this.score,
  });
}
