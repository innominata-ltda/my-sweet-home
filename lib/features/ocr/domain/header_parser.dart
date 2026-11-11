import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/store_draft.dart';

/// Alias de compatibilidade para HeaderParser.
typedef StoreHeaderParser = HeaderParser;

/// Pure parser for store and CNPJ extraction from receipt header.
///
/// Fulfills rules:
/// - **RF-041**: Extracts store (name, CNPJ and optional address).
/// - **RN-193**: Extracts store (name and CNPJ) from header.
/// - **RN-194**: Extracted CNPJ MUST have check digits validated;
///   invalid CNPJ is marked with `isCnpjValid = false` ("unconfirmed").
/// - **CA-2.1**: Accurate extraction of store from header.
final class HeaderParser {
  final ColumnDetector columnDetector;

  const HeaderParser({this.columnDetector = const ColumnDetector()});

  /// Extracts store information from an [OcrDocument].
  StoreDraft parse(OcrDocument doc) {
    if (doc.lines.isEmpty) {
      return const StoreDraft(confidence: 0.0);
    }

    final rows = columnDetector.detectRows(doc);
    return parseRows(rows, documentConfidence: doc.averageConfidence);
  }

  /// Extracts store information from a list of [OcrRow]s.
  StoreDraft parseRows(List<OcrRow> rows, {double? documentConfidence}) {
    if (rows.isEmpty) {
      return const StoreDraft(confidence: 0.0);
    }

    // Isolate lines belonging to header (before items/totals section)
    final headerRows = _extractHeaderRows(rows);

    // 1. Extract and validate CNPJ, falling back to issuer/TEF CNPJ lines or Access Key in receipt body
    var cnpjExtraction = _extractCnpj(headerRows);
    if (!cnpjExtraction.isValid && rows.length > headerRows.length) {
      final bodyCnpjRows = rows.skip(headerRows.length).where((r) {
        final u = r.text.toUpperCase();
        return !u.contains('CONSUMIDOR');
      }).toList();
      if (bodyCnpjRows.isNotEmpty) {
        final fallbackCnpj = _extractCnpj(bodyCnpjRows);
        if (fallbackCnpj.isValid ||
            (cnpjExtraction.cnpj == null && fallbackCnpj.cnpj != null)) {
          cnpjExtraction = fallbackCnpj;
        }
      }
    }

    // 2. Extract Store Name (Corporate Name / Trade Name)
    final storeNameExtraction = _extractStoreName(headerRows);

    // 3. Extract Address (if present)
    final addressExtraction = _extractAddress(
      headerRows,
      storeName: storeNameExtraction.name,
    );

    // 4. Calculate confidence of header information
    final conf = _calculateConfidence(
      cnpjExtraction: cnpjExtraction,
      storeNameExtraction: storeNameExtraction,
      headerRows: headerRows,
      fallbackDocConfidence: documentConfidence ?? 1.0,
    );

    return StoreDraft(
      name: storeNameExtraction.name,
      cnpj: cnpjExtraction.cnpj,
      isCnpjValid: cnpjExtraction.isValid,
      rawCnpj: cnpjExtraction.rawCnpj,
      address: addressExtraction,
      confidence: conf,
    );
  }

  /// Identifies which lines belong to header (receipt top before items).
  List<OcrRow> _extractHeaderRows(List<OcrRow> rows) {
    final headerRows = <OcrRow>[];
    for (final row in rows) {
      final textUpper = row.text.toUpperCase();

      // Indicators of start of items table or totals section
      if (_isItemTableHeaderOrTotalsStart(textUpper)) {
        break;
      }

      headerRows.add(row);

      // Safety limit of at most 15 lines for header
      if (headerRows.length >= 15) {
        break;
      }
    }
    return headerRows.isEmpty ? rows.take(10).toList() : headerRows;
  }

  bool _isItemTableHeaderOrTotalsStart(String textUpper) {
    if (RegExp(
      r'\b(ITEM|CÓDIGO|CODIGO|OIGO|DESCRIÇÃO|DESCRICAO|QTD|QUANT|VL\.?\s*UNIT|V\.UN)\b',
    ).hasMatch(textUpper)) {
      if (textUpper.contains('CÓDIGO') ||
          textUpper.contains('CODIGO') ||
          textUpper.contains('OIGO') ||
          textUpper.contains('DESCRICAO') ||
          textUpper.contains('ITEM')) {
        return true;
      }
    }
    if (RegExp(r'\b(TOTAL\s+R\$|SUBTOTAL|TOTAL\s+A\s+PAGAR)\b')
        .hasMatch(textUpper)) {
      return true;
    }
    return false;
  }

  /// Extracts CNPJ from header lines and validates check digits (RN-194).
  _CnpjExtractionResult _extractCnpj(List<OcrRow> headerRows) {
    String? bestRawCnpj;
    String? bestCleanCnpj;

    // 1a. Formatted CNPJ with explicit slash or punctuation (supports 1-2 initial digits if leading 0 was trimmed in OCR)
    final cnpjFormattedRegex = RegExp(
      r'(?<!\d)([0-9OoIl]{1,2})[\.\s,]([0-9OoIl]{3})[\.\s,]([0-9OoIlb]{3})\s*[\/71I|]\s*([0-9OoIlTt]{4})\s*[-\.\s]\s*([0-9OoIl]{1,2})(?!\d)',
      caseSensitive: false,
    );

    // 1b. CNPJ with explicit slash without mandatory periods
    final cnpjSlashRegex = RegExp(
      r'(?<!\d)([0-9OoIl]{2})[\.\s,]?([0-9OoIl]{3})[\.\s,]?([0-9OoIl]{3})\/([0-9OoIlTt]{4})[-\.\s]?([0-9OoIl]{2})(?!\d)',
      caseSensitive: false,
    );

    final cnpjRawRegex = RegExp(r'\b\d{14}\b');

    for (final row in headerRows) {
      final text = row.text;

      for (final regex in [cnpjFormattedRegex, cnpjSlashRegex]) {
        for (final match in regex.allMatches(text)) {
          final rawMatch = match.group(0)!;
          var g1 = match.group(1)!;
          if (g1.length == 1) {
            g1 = '0$g1';
          }
          final g5 = match.group(5)!;
          final joinedGroups =
              '$g1${match.group(2)}${match.group(3)}${match.group(4)}$g5';
          final normalized = joinedGroups
              .replaceAll(RegExp(r'[Oo]'), '0')
              .replaceAll(RegExp(r'[IlTt]'), '1')
              .replaceAll('b', '5');
          final clean = normalized.replaceAll(RegExp(r'[^0-9]'), '');

          if (clean.length == 14) {
            final valid = validateCnpjDigits(clean);
            if (valid) {
              return _CnpjExtractionResult(
                cnpj: clean,
                rawCnpj: rawMatch,
                isValid: true,
                confidence: row.averageConfidence,
              );
            } else {
              bestRawCnpj ??= rawMatch;
              bestCleanCnpj ??= clean;
            }
          }
        }
      }

      if (bestCleanCnpj == null) {
        for (final match in cnpjRawRegex.allMatches(text)) {
          final clean = match.group(0)!;
          final valid = validateCnpjDigits(clean);
          if (valid) {
            return _CnpjExtractionResult(
              cnpj: clean,
              rawCnpj: clean,
              isValid: true,
              confidence: row.averageConfidence,
            );
          } else {
            bestRawCnpj ??= clean;
            bestCleanCnpj ??= clean;
          }
        }
      }

      // 3. Fallback to Access Key (sequence of 40 to 48 digits spaced in blocks from NFC-e/SAT)
      final digitsOnly = text
          .replaceAll(RegExp(r'[Oo]'), '0')
          .replaceAll(RegExp(r'[^0-9]'), '');
      final hasFourDigitBlocks = RegExp(r'(?:\d{3,4}\s+){6,}\d{3,4}')
          .hasMatch(text);
      if (hasFourDigitBlocks &&
          digitsOnly.length >= 34 &&
          digitsOnly.length <= 48) {
        for (var i = 0; i <= digitsOnly.length - 14; i++) {
          final cand = digitsOnly.substring(i, i + 14);
          // Default branch 0001..0009 at positions 8..11
          if (cand.substring(8, 11) == '000' && validateCnpjDigits(cand)) {
            return _CnpjExtractionResult(
              cnpj: cand,
              rawCnpj: cand,
              isValid: true,
              confidence: row.averageConfidence,
            );
          }
        }
      }
    }

    if (bestCleanCnpj != null) {
      return _CnpjExtractionResult(
        cnpj: bestCleanCnpj,
        rawCnpj: bestRawCnpj,
        isValid: false,
        confidence: 0.5,
      );
    }

    return const _CnpjExtractionResult(
      cnpj: null,
      rawCnpj: null,
      isValid: false,
      confidence: 0.0,
    );
  }

  /// Extracts store name prioritizing corporate terms and ignoring noise.
  _StoreNameExtractionResult _extractStoreName(List<OcrRow> headerRows) {
    final candidateRows = <OcrRow>[];

    for (final row in headerRows) {
      final textTrim = row.text.trim();
      final textUpper = textTrim.toUpperCase();

      if (textTrim.isEmpty) continue;

      if (_isHeaderMetadataNoise(textUpper)) continue;

      if (_isAddressOrContactLine(textUpper)) continue;

      candidateRows.add(row);
    }

    if (candidateRows.isEmpty) {
      return const _StoreNameExtractionResult(name: null, confidence: 0.0);
    }

    for (final row in candidateRows) {
      final textUpper = row.text.toUpperCase();
      if (_containsCorporateIndicator(textUpper)) {
        final cleanName = _cleanStoreName(row.text);
        if (cleanName.isNotEmpty) {
          return _StoreNameExtractionResult(
            name: cleanName,
            confidence: row.averageConfidence,
          );
        }
      }
    }

    final firstCandidate = candidateRows.first;
    final cleanName = _cleanStoreName(firstCandidate.text);
    return _StoreNameExtractionResult(
      name: cleanName.isNotEmpty ? cleanName : null,
      confidence: firstCandidate.averageConfidence,
    );
  }

  bool _isHeaderMetadataNoise(String textUpper) {
    if (textUpper.contains('DANFE') ||
        textUpper.contains('NFC-E') ||
        textUpper.contains('NF-E') ||
        textUpper.contains('EXTRATO') ||
        textUpper.contains('CUPOM FISCAL') ||
        textUpper.contains('DOCUMENTO AUXILIAR') ||
        textUpper.contains('VIA CONSUMIDOR') ||
        textUpper.contains('RECEITA FEDERAL') ||
        textUpper.contains('SEJA BEM') ||
        textUpper.contains('BEM VINDO') ||
        textUpper.contains('BEM-VINDO') ||
        textUpper.contains('VOLTE SEMPRE') ||
        textUpper.contains('OBRIGADO PELA PREFER') ||
        textUpper.contains('NAO FISCAL') ||
        textUpper.contains('NÃO FISCAL') ||
        textUpper.contains('SAT FISCAL') ||
        textUpper.startsWith('CNPJ') ||
        textUpper.startsWith('I.E') ||
        textUpper.startsWith('IE:') ||
        textUpper.startsWith('I.M') ||
        textUpper.startsWith('IM:')) {
      return true;
    }
    return false;
  }

  bool _isAddressOrContactLine(String textUpper) {
    if (RegExp(
      r'\b(RUA|R\.|AVENIDA|AV\.|PRAÇA|PRC\.|ALAMEDA|AL\.|RODOVIA|ROD\.|BAIRRO|CEP|TEL|FONE)\b',
    ).hasMatch(textUpper)) {
      if (_containsCorporateIndicator(textUpper)) return false;
      return true;
    }
    return false;
  }

  bool _containsCorporateIndicator(String textUpper) {
    return RegExp(
      r'\b(LTDA|S/?A|S\.A\.|EIRELI|ME|EPP|COMERCIO|COMÉRCIO|SUPERMERCADO|SUPERMERCADOS|ATACADO|ATACADISTA|DROGARIA|FARMACIA|FARMÁCIA|PADARIA|MERCADO|MERCEARIA|LOJA|LOJAS|INDUSTRIA|INDÚSTRIA|HORTIFRUTI)\b',
    ).hasMatch(textUpper);
  }

  String _cleanStoreName(String text) {
    var clean = text.trim();
    clean = clean.replaceAll(
      RegExp(
        r'^(NOME FANTASIA|RAZÃO SOCIAL|RAZAO SOCIAL|ESTABELECIMENTO|ESTAB|FANTASIA|NOME)[:\s-]*',
        caseSensitive: false,
      ),
      '',
    );
    clean = clean.replaceAll(
      RegExp(
        r'\s*CNPJ[:\s/MF\.-]*\d{2}[\.\s]?\d{3}[\.\s]?\d{3}[\/\s]?\d{4}[-\s]?\d{2}.*$',
        caseSensitive: false,
      ),
      '',
    );
    return clean.trim();
  }

  String? _extractAddress(List<OcrRow> headerRows, {String? storeName}) {
    final addressLines = <String>[];

    for (final row in headerRows) {
      final textTrim = row.text.trim();
      final textUpper = textTrim.toUpperCase();

      if (storeName != null && textTrim.contains(storeName)) continue;

      if (_isHeaderMetadataNoise(textUpper)) continue;

      if (RegExp(
        r'\b(RUA|R\.|AVENIDA|AV\.|PRAÇA|PRC\.|ALAMEDA|AL\.|RODOVIA|ROD\.|BAIRRO|CEP)\b',
      ).hasMatch(textUpper)) {
        addressLines.add(textTrim);
      }
    }

    if (addressLines.isEmpty) return null;
    return addressLines.join(', ');
  }

  double _calculateConfidence({
    required _CnpjExtractionResult cnpjExtraction,
    required _StoreNameExtractionResult storeNameExtraction,
    required List<OcrRow> headerRows,
    required double fallbackDocConfidence,
  }) {
    if (headerRows.isEmpty) return 0.0;

    final confs = <double>[];
    if (storeNameExtraction.name != null) {
      confs.add(storeNameExtraction.confidence);
    }
    if (cnpjExtraction.cnpj != null) {
      confs.add(cnpjExtraction.confidence);
    }

    if (confs.isEmpty) return fallbackDocConfidence * 0.5;
    final avg = confs.reduce((a, b) => a + b) / confs.length;

    if (cnpjExtraction.cnpj != null && !cnpjExtraction.isValid) {
      return (avg * 0.7).clamp(0.0, 1.0);
    }
    return avg.clamp(0.0, 1.0);
  }

  /// Official CNPJ digit verification algorithm (RN-194).
  static bool validateCnpjDigits(String cleanDigits) {
    if (cleanDigits.length != 14) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cleanDigits)) return false;

    final digits = cleanDigits.split('').map(int.parse).toList();

    int sum1 = 0;
    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 12; i++) {
      sum1 += digits[i] * weights1[i];
    }
    final rem1 = sum1 % 11;
    final digit1 = rem1 < 2 ? 0 : 11 - rem1;
    if (digits[12] != digit1) return false;

    int sum2 = 0;
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 13; i++) {
      sum2 += digits[i] * weights2[i];
    }
    final rem2 = sum2 % 11;
    final digit2 = rem2 < 2 ? 0 : 11 - rem2;
    if (digits[13] != digit2) return false;

    return true;
  }
}

class _CnpjExtractionResult {
  final String? cnpj;
  final String? rawCnpj;
  final bool isValid;
  final double confidence;

  const _CnpjExtractionResult({
    required this.cnpj,
    required this.rawCnpj,
    required this.isValid,
    required this.confidence,
  });
}

class _StoreNameExtractionResult {
  final String? name;
  final double confidence;

  const _StoreNameExtractionResult({
    required this.name,
    required this.confidence,
  });
}
