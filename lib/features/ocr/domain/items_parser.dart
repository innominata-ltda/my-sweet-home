import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';

/// Classification of quantity pattern match in a line.
class _QtyMatch {
  final Quantity quantity;
  final Money unitPrice;
  final Money? totalPrice;
  final String textBefore;
  final String textAfter;

  const _QtyMatch({
    required this.quantity,
    required this.unitPrice,
    this.totalPrice,
    required this.textBefore,
    required this.textAfter,
  });
}

/// Extrai a lista de itens ([ReceiptItemDraft]) de um documento de OCR ([OcrDocument])
/// ou de uma lista de linhas visuais ([OcrRow]).
///
/// Trata:
/// - Simple or 2-line wrapped description (CA-2.2)
/// - Items weighed by kg/g with fractional quantity (e.g. 0.734 KG X 39.90 -> R$ 29.29) (CA-2.3)
/// - EAN/GTIN code and item number
/// - Per-item confidence level (confidence < 0.6 yields `selected = false`, RN-195)
final class ItemsParser {
  final ColumnDetector columnDetector;

  const ItemsParser({this.columnDetector = const ColumnDetector()});

  /// Extrai itens de um [OcrDocument].
  List<ReceiptItemDraft> parseItems(OcrDocument doc) {
    if (doc.lines.isEmpty) return const [];
    final rows = columnDetector.detectRows(doc);
    return parseRows(rows);
  }

  /// Extrai itens a partir de uma lista de [OcrRow] previamente detectadas.
  List<ReceiptItemDraft> parseRows(List<OcrRow> inputRows) {
    if (inputRows.isEmpty) return const [];

    final result = <ReceiptItemDraft>[];
    _PendingItemBuilder? pending;

    for (var i = 0; i < inputRows.length; i++) {
      final row = inputRows[i];
      final lineText = row.text.trim();
      if (lineText.isEmpty) continue;

      // 0. Desconto por item (ex.: RaiaDrogasil "De 52,99 por 37,99 desconto de -15,00" / "Valor Liquido 37,99")
      final itemNetPrice = _extractPerItemDiscountedPrice(lineText);
      if (itemNetPrice != null || _isPerItemDiscountMetadata(lineText)) {
        if (pending != null && pending.hasPrice) {
          final item = pending.build();
          if (item != null) {
            result.add(item);
          }
          pending = null;
        }
        if (itemNetPrice != null &&
            itemNetPrice.cents > 0 &&
            result.isNotEmpty &&
            itemNetPrice.cents <= result.last.totalPrice.cents) {
          final last = result.last;
          final newUnit =
              (last.quantity.unit == Unit.un &&
                  last.quantity.valueMilli == 1000)
              ? itemNetPrice
              : Money(
                  ((itemNetPrice.cents * 1000) / last.quantity.valueMilli)
                      .round(),
                );
          result[result.length - 1] = last.copyWith(
            unitPrice: newUnit,
            totalPrice: itemNetPrice,
          );
        }
        continue;
      }

      // 1. Ignore footers and totals (saving pending item if it already has price)
      if (_isFooterOrTotalsRow(lineText)) {
        if (pending != null && pending.hasPrice) {
          final item = pending.build();
          if (item != null) {
            result.add(item);
          }
        }
        pending = null;

        // If items already extracted and reached closing/totals/payment/tax footer section,
        // stop reading items to prevent EFT vouchers or footers from turning into products.
        if (result.isNotEmpty && _isEndOfItemsSection(lineText)) {
          break;
        }
        continue;
      }

      // 2. Ignore store or table headers (saving pending item only if it already has price)
      if (_isHeaderRow(lineText)) {
        if (pending != null && pending.hasPrice) {
          final item = pending.build();
          if (item != null) {
            result.add(item);
          }
        }
        pending = null;
        continue;
      }

      // If line starts with new item number (e.g. 002 or #002) or new barcode
      // and we had a previous pending item, finish (if priced) or discard orphan
      if (pending != null &&
          ((pending.hasIndex && _startsWithItemIndex(lineText)) ||
              (!pending.hasPrice && _startsWithBarcodeOrIndex(lineText)))) {
        if (pending.hasPrice) {
          final item = pending.build();
          if (item != null) {
            result.add(item);
          }
        }
        pending = null;
      }

      // 3. Try to extract quantity expression (e.g. "0.734 KG X 39.90", "2 UN X 4.50 9.00" or "1UN 5.99 5.99")
      final qtyMatch = _matchQuantityExpression(lineText);

      if (qtyMatch != null) {
        pending ??= _PendingItemBuilder();
        pending.addQtyLine(row, qtyMatch);

        final item = pending.build();
        if (item != null) {
          result.add(item);
        }
        pending = null;
        continue;
      }

      // 4. Check if line has isolated price at end or right segment
      final priceAtEnd = _extractPriceAtEnd(row);

      if (priceAtEnd != null) {
        pending ??= _PendingItemBuilder();
        pending.addDescriptionRowWithPrice(row, priceAtEnd);

        final item = pending.build();
        if (item != null) {
          result.add(item);
        }
        pending = null;
        continue;
      }

      // 5. Plain text line without price (could be line 1 of a 2-line item)
      pending ??= _PendingItemBuilder();
      pending.addTextRow(row);
    }

    // Pending item at end (only if it has valid price)
    if (pending != null && pending.hasPrice) {
      final item = pending.build();
      if (item != null) {
        result.add(item);
      }
    }

    return result;
  }

  bool _startsWithItemIndex(String text) {
    final s = text.trim();
    if (s.isEmpty) return false;

    // If line is quantity expression (e.g. "2 UN X 4.50" or "0.734 KG"), not an index
    if (RegExp(
      r'^\d+(?:[\.,]\d{1,4})?\s*(?:KG|G|L|ML|UN|UND|UNID|UK|0N|PCT|CX|PACK|PC|PÇ|PT|LA|TB|FR)?\s*[xX*]',
      caseSensitive: false,
    ).hasMatch(s)) {
      return false;
    }

    // Valid index patterns: #1, 1., 1), or 001 (3 digits)
    if (RegExp(r'^#\d{1,3}\b').hasMatch(s)) return true;
    if (RegExp(r'^\d{1,3}[\.\)]\s+').hasMatch(s)) return true;
    if (RegExp(r'^\d{3}\s+').hasMatch(s)) {
      final afterDigits = s.substring(3).trimLeft();
      final startsWithUnit = RegExp(
        r'^(?:KG|G|L|ML|UN|UND|UNID|UK|0N|PCT|CX|PACK|PC|PÇ|PT|LA|TB|FR)\b',
        caseSensitive: false,
      ).hasMatch(afterDigits);
      return !startsWithUnit;
    }

    return false;
  }

  bool _startsWithBarcodeOrIndex(String text) {
    if (_startsWithItemIndex(text)) return true;
    final s = text.trim();
    if (RegExp(r'^\d{6,14}\s+[A-Za-z]').hasMatch(s)) return true;
    if (RegExp(r'^[A-Za-z0-9]{1,3}\s*\d{6,13}\s+[A-Za-z]').hasMatch(s)) {
      return true;
    }
    return false;
  }

  Money? _extractPerItemDiscountedPrice(String text) {
    final dePorMatch = RegExp(
      r'\bDe\s+\d+[\.,]\s*\d{2}\s+p[oa]r\s+(\d+[\.,]\s*\d{2})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (dePorMatch != null) {
      return _parseMoney(dePorMatch.group(1)!.replaceAll(' ', ''));
    }

    final valLiqMatch = RegExp(
      r'^(?:V[aá]?l[o0]r|Vsior|alur)\s+L[ií1]quid[o0]\s+(?:R\$\s*)?(\d+[\.,]\s*\d{2})\b',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (valLiqMatch != null) {
      return _parseMoney(valLiqMatch.group(1)!.replaceAll(' ', ''));
    }
    return null;
  }

  bool _isPerItemDiscountMetadata(String text) {
    final trimmed = text.trim();
    if (RegExp(
      r'^(?:V[aá]?l[o0]r|Vsior|alur)\s+L[ií1]quid[o0]\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(
      r'\bDe\s+\d+[\.,]\s*\d{1,2}\s+p[oa]r\b',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  bool _isEndOfItemsSection(String text) {
    final upper = text.toUpperCase();
    // Individual item discount does not terminate item list
    if (_isItemDiscountOnly(upper)) return false;
    return _isTotalsRow(upper) ||
        _isPaymentRow(upper) ||
        _isTaxOrIbptRow(upper) ||
        _isComplementaryFiscalRow(upper);
  }

  bool _isItemDiscountOnly(String upper) {
    final hasDiscountWord =
        upper.contains('DESCONTO') ||
        upper.contains('ABATIMENTO') ||
        upper.contains('ACRÉSCIMO') ||
        upper.contains('ACRESCIMO');
    if (!hasDiscountWord) return false;
    if (upper.contains('TOTAL') ||
        upper.contains('SUBTOTAL') ||
        upper.contains('PAGAR') ||
        upper.contains('BRUTO') ||
        upper.contains('LIQUIDO') ||
        upper.contains('LÍQUIDO')) {
      return false;
    }
    return true;
  }

  bool _isFooterOrTotalsRow(String text) {
    final upper = text.toUpperCase();
    return _isTotalsRow(upper) ||
        _isPaymentRow(upper) ||
        _isTaxOrIbptRow(upper) ||
        _isComplementaryFiscalRow(upper);
  }

  bool _isTotalsRow(String upper) {
    if (upper.startsWith('SUBTOTAL') ||
        upper.contains('SUB TOTAL') ||
        upper.contains('SUB-TOTAL') ||
        upper.contains('SOMA DOS ITENS') ||
        upper.contains('SOMA R\$')) {
      return true;
    }

    if (upper.contains('TOTAL DE ITENS') ||
        upper.contains('QTD. TOTAL') ||
        upper.contains('QTDE. TOTAL')) {
      return true;
    }

    if (upper.contains('TOTAL R\$') ||
        upper.contains('TOTAL GERAL') ||
        upper.contains('TOTAL A PAGAR') ||
        upper.contains('VALOR A PAGAR') ||
        upper.contains('A PAGAR R\$') ||
        upper.contains('A PAGAR') ||
        upper.contains('PASUR') ||
        upper.contains('PAGUR') ||
        upper.contains('VALOR TOTAL') ||
        upper.contains('TOTAL DOS ITENS') ||
        upper.contains('VALOR LÍQUIDO') ||
        upper.contains('VALOR LIQUIDO') ||
        upper.contains('TOTAL LÍQUIDO') ||
        upper.contains('TOTAL LIQUIDO') ||
        upper.contains('VALOR BRUTO') ||
        upper.contains('TOTAL BRUTO')) {
      return true;
    }

    if (upper.contains('DESCONTO') ||
        upper.contains('(-) DESCONTO') ||
        upper.contains('DESC. TOTAL') ||
        upper.contains('DESC TOTAL') ||
        upper.contains('ABATIMENTO') ||
        upper.contains('ACRÉSCIMO') ||
        upper.contains('ACRESCIMO')) {
      return true;
    }

    if (RegExp(r'^TOTAL\b').hasMatch(upper)) {
      return true;
    }

    return false;
  }

  bool _isPaymentRow(String upper) {
    // 1. Payment method headers (including OCR noise like RHA PAGAMENTO / RMA PAGAMENTO)
    if (upper.contains('FORMA DE PAGAMENTO') ||
        upper.contains('FORMAS DE PAGAMENTO') ||
        upper.contains('FORMA PAGAMENTO') ||
        upper.contains('RMA PAGAMENTO') ||
        upper.contains('RHA PAGAMENTO') ||
        upper.contains('FORMA PAGTO') ||
        upper.contains('FORMAS PAGTO') ||
        upper.contains('FORMAS DE PAGTO') ||
        upper.contains('MEIO DE PAGAMENTO') ||
        upper.contains('MEIOS DE PAGAMENTO') ||
        upper.contains('CONDIÇÃO DE PAGAMENTO') ||
        upper.contains('CONDICAO DE PAGAMENTO') ||
        upper.startsWith('PAGAMENTO') ||
        upper.startsWith('PAGTO')) {
      return true;
    }

    // 2. Credit / Debit card and abbreviations or OCR noise (BTAO CREDITO, RTAO CREDITO)
    if (RegExp(r'\bCART[AÃ]O\s+(DE\s+)?(CR[EÉ]DITO|D[EÉ]BITO)\b')
            .hasMatch(upper) ||
        RegExp(r'\b(?:CA?RT[AÃ]O|BTA[O0]|RTA[O0])\s+(CR[EÉ]DITO|D[EÉ]BITO)\b')
            .hasMatch(upper) ||
        RegExp(r'\bC\.?\s*(CR[EÉ]DITO|D[EÉ]BITO)\b').hasMatch(upper) ||
        RegExp(r'\bCART[AÃ]O\s+DE\s+(COMPRAS|CONV[EÊ]NIO)\b').hasMatch(upper)) {
      return true;
    }

    // 3. Card brands, E-Commerce and EFT vouchers (COMPR:, IMPR:, UALUR:, SITEF)
    if (RegExp(
          r'\b(MASTERCARD|MASTER\s+CARD|VISA|ELO|HIPERCARD|AMEX|AMERICAN\s+EXPRESS|BANRICOMPRAS|BANRISUL|SITEF|REDE)\b',
        ).hasMatch(upper) ||
        RegExp(r'\bE[\s\-]?CO(?:MM|NN)ERCE\b').hasMatch(upper) ||
        RegExp(r'\b(?:COMPR|i?MPR)\s*:').hasMatch(upper) ||
        RegExp(r'\b(?:VALOR|UALUR|URLOR)\s*:').hasMatch(upper)) {
      return true;
    }

    // 4. Cash / Currency
    if (RegExp(r'\b(EM\s+)?DINHEIRO\b').hasMatch(upper) ||
        RegExp(r'\b(EM\s+)?ESP[EÉ]CIE\b').hasMatch(upper)) {
      return true;
    }

    // 5. PIX
    if (RegExp(r'\bPIX\b').hasMatch(upper)) {
      return true;
    }

    // 6. Food / meal vouchers
    if (upper.contains('VALE ALIMENTAÇÃO') ||
        upper.contains('VALE ALIMENTACAO') ||
        upper.contains('VALE REFEIÇÃO') ||
        upper.contains('VALE REFEICAO') ||
        upper.contains('VALE-ALIMENTAÇÃO') ||
        upper.contains('VALE-ALIMENTACAO') ||
        upper.contains('VALE-REFEIÇÃO') ||
        upper.contains('VALE-REFEICAO') ||
        RegExp(r'\b(TICKET|SODEXO|ALELO)\b').hasMatch(upper) ||
        RegExp(
          r'\bV\.[AR]\.|\bV\.?[AR]\.?\s+(ALIMENTA[CÇ][AÃ]O|REFEI[CÇ][AÃ]O)\b',
        ).hasMatch(upper)) {
      return true;
    }

    // 7. Troco
    if (RegExp(r'\bTROCO\b').hasMatch(upper)) {
      return true;
    }

    // 8. Valor pago / recebido (inclui Vl. Pago, Vlr Pago, URLOR PAGO, etc.)
    if (RegExp(r'\b(VALOR|URLOR|UALUR|VLR?\.?|TOTAL)\s+PAG[O0]\b')
            .hasMatch(upper) ||
        RegExp(r'\bVL\.?\s*PAG[O0]\b').hasMatch(upper) ||
        RegExp(r'\b(VALOR|VLR?\.?|TOTAL)\s+RECEBIDO\b').hasMatch(upper) ||
        RegExp(r'\bVL\.?\s*RECEBIDO\b').hasMatch(upper)) {
      return true;
    }

    return false;
  }

  bool _isTaxOrIbptRow(String upper) {
    // 1. IBPT tax mentions
    if (upper.contains('IBPT')) {
      return true;
    }

    // 2. Tributos e impostos
    if (RegExp(r'\bTRIBUTOS?\b').hasMatch(upper) ||
        upper.contains('TRIB TOTAIS') ||
        upper.contains('TOTAIS INCID')) {
      return true;
    }

    // 3. Variations of "Valor aproximado dos tributos" / "Val aprox" / "Vl. Aprox"
    if (RegExp(r'\b(VAL(OR)?|VLR?)\.?\s*APROX(IMADO)?\b').hasMatch(upper) ||
        upper.contains('APROX TRIBUTOS')) {
      return true;
    }

    // 4. Tax transparency law (Law 12.741/2012)
    if (RegExp(r'\b12\.?741(?:/2012)?\b').hasMatch(upper) ||
        upper.contains('TRANSPARÊNCIA FISCAL') ||
        upper.contains('TRANSPARENCIA FISCAL')) {
      return true;
    }

    // 5. Specific taxes and tax deductions
    if (upper.contains('IMPOSTOS INCIDENTES') ||
        upper.contains('IMPOSTO INCIDENTE') ||
        upper.contains('TOTAL DE IMPOSTOS') ||
        upper.contains('VALOR DOS IMPOSTOS') ||
        upper.contains('CARGA TRIBUTÁRIA') ||
        upper.contains('CARGA TRIBUTARIA') ||
        upper.contains('BASE DE CÁLCULO') ||
        upper.contains('BASE DE CALCULO') ||
        upper.contains('BASE CÁLC') ||
        upper.contains('BASE CALC') ||
        upper.contains('VALOR DO ICMS') ||
        upper.contains('VALOR ICMS') ||
        upper.contains('ICMS ST') ||
        upper.contains('ICMS NORMAL') ||
        upper.contains('ALÍQUOTA ICMS') ||
        upper.contains('ALIQUOTA ICMS') ||
        upper.contains('PIS/COFINS') ||
        upper.contains('PIS / COFINS') ||
        upper.contains('ISSQN')) {
      return true;
    }

    return false;
  }

  bool _isComplementaryFiscalRow(String upper) {
    // 1. Chave de acesso e consulta pela chave
    if (upper.contains('CHAVE DE ACESSO') ||
        upper.contains('CHAVE ACESSO') ||
        upper.contains('CONSULTA PELA CHAVE') ||
        upper.contains('CONSULTE PELA CHAVE') ||
        upper.contains('CONSULTA DA CHAVE') ||
        upper.contains('PELA CHAVE DE ACESSO') ||
        upper.contains('SEFAZ') ||
        upper.contains('HTTP://') ||
        upper.contains('HTTPS://') ||
        (upper.contains('CHAVE:') && RegExp(r'\b\d{4}\b').hasMatch(upper))) {
      return true;
    }

    // 44-digit access key (often grouped in blocks of 4)
    if (RegExp(r'(?:\d{4}[\s\.-]?){11}').hasMatch(upper)) {
      return true;
    }

    // 2. Authorization protocol (including OCR typos like PROTOCALO / AUTORLZACAO)
    if (upper.contains('PROTOCOLO DE AUTORIZAÇÃO') ||
        upper.contains('PROTOCOLO DE AUTORIZACAO') ||
        upper.contains('PROTOCALO DE AUTORIZACAO') ||
        upper.contains('PROTOCOLO AUTORIZAÇÃO') ||
        upper.contains('PROTOCOLO AUTORIZACAO') ||
        upper.contains('PROTOCOLO:') ||
        upper.contains('PROT. AUTORIZAÇÃO') ||
        upper.contains('PROT. AUTORIZACAO') ||
        upper.contains('DATA DE AUTORIZACAO') ||
        upper.contains('DATA DE AUTORIZAÇÃO') ||
        upper.contains('DATA DE AUTORLZACAO') ||
        upper.contains('NÚMERO DE AUTORIZAÇÃO') ||
        upper.contains('NUMERO DE AUTORIZACAO') ||
        upper.contains('AUTORIZAÇÃO DE USO') ||
        upper.contains('AUTORIZACAO DE USO')) {
      return true;
    }

    // 3. Consumer (unidentified / CPF / CNPJ)
    if (upper.contains('CONSUMIDOR NÃO IDENTIFICADO') ||
        upper.contains('CONSUMIDOR NAO IDENTIFICADO') ||
        (upper.contains('NÃO IDENTIFICADO') && upper.contains('CONSUMIDOR')) ||
        (upper.contains('NAO IDENTIFICADO') && upper.contains('CONSUMIDOR')) ||
        upper.contains('CPF DO CONSUMIDOR') ||
        upper.contains('CNPJ DO CONSUMIDOR') ||
        upper.contains('CPF/CNPJ DO CONSUMIDOR') ||
        upper.contains('CONSUMIDOR - CPF') ||
        upper.contains('CONSUMIDOR CPF') ||
        upper.contains('CONSUMIDOR CNPJ') ||
        upper.contains('IDENTIFICAÇÃO DO CONSUMIDOR') ||
        upper.contains('IDENTIFICACAO DO CONSUMIDOR') ||
        upper.contains('DADOS DO CONSUMIDOR') ||
        upper.contains('DESTINATÁRIO') ||
        upper.contains('DESTINATARIO')) {
      return true;
    }

    // 4. QR Code e consulta via leitor
    if (upper.contains('QR CODE') ||
        upper.contains('QRCODE') ||
        upper.contains('LEITOR DE QR') ||
        upper.contains('CONSULTA VIA LEITOR') ||
        upper.contains('CONSULTE PELO QR') ||
        upper.contains('CONSULTA POR QR')) {
      return true;
    }

    // 5. Documentos, Procon, TEF e metadados fiscais adicionais
    if (upper.contains('VIA CONSUMIDOR') ||
        upper.contains('VIA DO CONSUMIDOR') ||
        upper.contains('VIA CLIENTE') ||
        upper.contains('VIA ESTABELECIMENTO') ||
        upper.contains('DOCUMENTO AUXILIAR') ||
        upper.contains('DOCUNENTO AUXILIAR') ||
        upper.contains('AMBIENTE DE HOMOLOGAÇÃO') ||
        upper.contains('AMBIENTE DE HOMOLOGACAO') ||
        upper.contains('EMITIDA EM HOMOLOGAÇÃO') ||
        upper.contains('EMITIDA EM HOMOLOGACAO') ||
        upper.contains('EMITIDA EM CONTINGENCIA') ||
        upper.contains('EMITIDA EM CONTINGÊNCIA') ||
        upper.contains('EMITIDA EN CONTINGENCIA') ||
        upper.contains('PENDENTE DE AUTORIZACAO') ||
        upper.contains('PENDENTE DE AUTORIZAÇÃO') ||
        upper.contains('EXTRATO SAT') ||
        upper.contains('CUPOM FISCAL ELETRÔNICO') ||
        upper.contains('CUPOM FISCAL ELETRONICO') ||
        upper.contains('CHECKOUT:') ||
        upper.contains('ECKOUT:') ||
        upper.contains('PROCON') ||
        upper.contains('NOTA LEGAL') ||
        upper.contains('RECEITA CIDADA') ||
        upper.contains('TORPEDO PREMIADO') ||
        upper.contains('DEIXOU DE ECONOMIZAR') ||
        upper.contains('TRANSACAO APROVADA') ||
        upper.contains('TRANSAÇÃO APROVADA')) {
      return true;
    }

    return false;
  }

  bool _isHeaderRow(String text) {
    final upper = text.toUpperCase();

    if (upper.contains('CNPJ:') ||
        upper.contains('CNPJ ') ||
        upper.startsWith('CNPJ')) {
      return true;
    }
    if (upper.contains('CPF:') ||
        upper.contains('CPF ') ||
        upper.startsWith('CPF')) {
      return true;
    }
    if (upper.contains('IE:') ||
        upper.contains('IM:') ||
        upper.contains('INSCRIÇÃO ESTADUAL')) {
      return true;
    }
    if (upper.startsWith('DANFE') ||
        upper.startsWith('NFC-E') ||
        upper.startsWith('SAT') ||
        upper.contains('NFC-E')) {
      return true;
    }
    if (upper.contains('CUPOM FISCAL') ||
        upper.contains('DOCUMENTO AUXILIAR') ||
        upper.contains('DOCUNENTO AUXILIAR') ||
        upper.contains('CONSUMIDOR ELETRONICA') ||
        upper.contains('CONSUMIDOR ELETRÔNICA') ||
        upper.contains('EIETRONICA') ||
        upper.contains('EMITIDA EM CONTINGENCIA') ||
        upper.contains('EMITIDA EN CONTINGENCIA') ||
        upper.contains('PENDENTE DE AUTORIZACAO') ||
        upper.contains('EXTRATO')) {
      return true;
    }

    // Address, phone, corporate name, or cashier lines of header
    if (RegExp(r'\b(LTDA|LTDÄ|LIDA|EIRELI|S/A|& CIA)\b').hasMatch(upper)) {
      return true;
    }
    if (RegExp(
      r'\b(RUA|AVENIDA|AV\.|ALAMEDA|PRACA|RODOVIA|ESTRADA|BAIRRO|CENTRO|CEP|FONE|TEL)\b',
    ).hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'\bLJ\s*\d{3,5}\b').hasMatch(upper) &&
        (upper.contains('PDV') ||
            upper.contains('PDU') ||
            upper.contains('DOC') ||
            upper.contains('OP '))) {
      return true;
    }

    // Column headers of items table (including OCR typos like OIGO DESCRICAO)
    if ((upper.contains('DESCRIÇÃO') ||
            upper.contains('DESCRICAO') ||
            upper.contains('DESC ') ||
            upper.contains('DESC|')) &&
        (upper.contains('CÓDIGO') ||
            upper.contains('CODIGO') ||
            upper.contains('COD') ||
            upper.contains('OIGO') ||
            upper.contains('QTD') ||
            upper.contains('VL ') ||
            upper.contains('V.UN') ||
            upper.contains('ITEM'))) {
      return true;
    }
    if (upper.contains('QTD') &&
        (upper.contains('VL UN') || upper.contains('V.UN'))) {
      return true;
    }
    if (upper.contains('ITEM') && upper.contains('DESC')) {
      return true;
    }
    if (upper.contains('QTD TOTAL DE ITENS') ||
        upper.contains('QTD. TOTAL DE ITENS') ||
        upper.contains('QTDE. TOTAL DE ITENS') ||
        upper.contains('TOTAL DE ITENS')) {
      return true;
    }

    return false;
  }

  _QtyMatch? _matchQuantityExpression(String rawText) {
    // Pre-normalization of OCR merges:
    // - Two decimal prices stuck without space: "2,394.78" -> "2,39 4.78"
    // - "TUN" / "TUR" / "1N" / "1H" followed by price -> "1UN"
    final text = rawText
        .replaceAllMapped(
          RegExp(r'(\d+[\.,]\d{2})(?=\d+[\.,]\d{2}\b)'),
          (m) => '${m.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(
            r'\b(?:TUN|TUR|1N|1H)(?=\s+\d+[\.,]\d{2}\b)',
            caseSensitive: false,
          ),
          (_) => '1UN',
        );

    // 1. Regex to capture multiplier expressions with X or * or x (\u00D7):
    // Supports optional tax value in parentheses like "(11.04)" between unit and total:
    // - "0,734 KG X 39,90"
    // - "2 UN X 4,50 9,00"
    // - "1 UN X 35,12 (11,04) 35,12"
    final regX = RegExp(
      r'(\d+(?:[\.,]\d{1,4})?)\s*([A-Za-zÇç]{1,8})?\s*[xX*\u00D7]\s*(?:R\$\s*)?(\d+(?:[\.,]\d{2,3}))(?:\s*\(\s*\d+[\.,]\d{2}\s*\))?(?:\s+(?:R\$\s*)?(\d+(?:[\.,]\d{2})))?',
    );

    final matchX = regX.firstMatch(text);
    if (matchX != null) {
      final qtyStr = matchX.group(1)!;
      final unitStr = matchX.group(2);
      final unitPriceStr = matchX.group(3)!;
      final totalPriceStr = matchX.group(4);

      final unit = _parseUnit(unitStr);
      final quantity = _parseQuantity(qtyStr, unit);
      final unitPrice = _parseMoney(unitPriceStr) ?? Money.zero;
      final totalPrice = totalPriceStr != null
          ? _parseMoney(totalPriceStr)
          : null;

      final textBefore = text.substring(0, matchX.start);
      final textAfter = text.substring(matchX.end);

      return _QtyMatch(
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        textBefore: textBefore,
        textAfter: textAfter,
      );
    }

    // 2a. Regex with TWO prices "<QTY><UN> <UNIT_VAL> <TOTAL_VAL>" without "X"
    // Ex: "1UN 5,99 5,99", "CARAMELO1UN 5,99 5,99", "10N 5,99 5,99", "1 CX 79,90 Tf 20.00% 79,90"
    final regNoXTwoPrices = RegExp(
      r'(?<!\d)(\d+(?:[\.,]\d{1,4})?)\s*(UN|UND|UNID|UK|0N|ON|ÜN|KG|K6|K9|L|ML|PCT|CX|PACK|PC|PÇ|PT|LA|TB|FR|BT)\s+(?:R\$\s*)?(\d+[\.,]\d{2})(?:\s+(?:Tf\s*)?\d+[\.,]\d{2}%|\s+\(\s*\d+[\.,]\d{2}\s*\)|\s+\d+[\.,]\d{2})?\s+(?:R\$\s*)?(\d+[\.,]\d{2})\b',
      caseSensitive: false,
    );

    // 2b. Regex with ONE price "<QTY><UN> <UNIT_VAL>" without "X" (only count units like UN/CX/BT,
    // or fractional weight like "0.458KG 46.99" / line start, avoiding confusion with "ARROZ 5KG 25.90")
    final regNoXOnePrice = RegExp(
      r'(?:(?<!\d)(\d+(?:[\.,]\d{1,4})?)\s*(UN|UND|UNID|UK|0N|ON|ÜN|CX|BT)\s+(?:R\$\s*)?(\d+[\.,]\d{2})|(?<!\d)(\d+[\.,]\d{2,4})\s*(KG|K6|K9)\s+(?:R\$\s*)?(\d+[\.,]\d{2}))\b',
      caseSensitive: false,
    );

    final matchNoX =
        regNoXTwoPrices.firstMatch(text) ?? regNoXOnePrice.firstMatch(text);
    if (matchNoX != null) {
      final isTwoPrices =
          matchNoX.groupCount >= 4 &&
          matchNoX.group(4) != null &&
          regNoXTwoPrices.hasMatch(text);
      final qtyStr = (matchNoX.group(1) ?? matchNoX.group(4))!;
      var unitStr = (matchNoX.group(2) ?? matchNoX.group(5))!;
      final upperUnit = unitStr.toUpperCase();
      if (upperUnit == '0N' || upperUnit == 'ON' || upperUnit == 'ÜN') {
        unitStr = 'UN';
      } else if (upperUnit == 'K6' || upperUnit == 'K9') {
        unitStr = 'KG';
      }
      final unitPriceStr = (matchNoX.group(3) ?? matchNoX.group(6))!;
      final totalPriceStr = isTwoPrices ? matchNoX.group(4) : null;

      final unit = _parseUnit(unitStr);
      final quantity = _parseQuantity(qtyStr, unit);
      final unitPrice = _parseMoney(unitPriceStr) ?? Money.zero;
      final totalPrice = totalPriceStr != null
          ? _parseMoney(totalPriceStr)
          : null;

      final textBefore = text.substring(0, matchNoX.start);
      final textAfter = text.substring(matchNoX.end);

      return _QtyMatch(
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        textBefore: textBefore,
        textAfter: textAfter,
      );
    }

    // 3. Tax line with explicit rate without X (e.g. Kalunga "68.00 Tf 20.00% 68.00")
    final regTaxLine = RegExp(
      r'\b(\d+[\.,]\d{2})\s+Tf\s+\d+[\.,]\d{2}%(?:\s+(\d+[\.,]\d{2}))?',
      caseSensitive: false,
    );
    final matchTax = regTaxLine.firstMatch(text);
    if (matchTax != null) {
      final unitPrice = _parseMoney(matchTax.group(1)!) ?? Money.zero;
      final totalPrice = matchTax.group(2) != null
          ? _parseMoney(matchTax.group(2)!)
          : unitPrice;
      return _QtyMatch(
        quantity: const Quantity(1000, Unit.un),
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        textBefore: text.substring(0, matchTax.start),
        textAfter: text.substring(matchTax.end),
      );
    }

    return null;
  }

  Money? _extractPriceAtEnd(OcrRow row) {
    // 1. Tentar pegar o valor do segmento da direita
    final rightSeg = row.rightSegment;
    if (rightSeg != null) {
      final m = _parsePriceCandidate(rightSeg.text);
      if (m != null && m.cents > 0) {
        return m;
      }
    }

    // 2. If no right segment, search value at end of line text
    final text = row.text.trim();
    final reg = RegExp(r'(?:R\$\s*)?(\d{1,5}[\.,]\d{2})\s*$');
    final match = reg.firstMatch(text);
    if (match != null) {
      return _parseMoney(match.group(1)!);
    }

    return null;
  }

  Money? _parsePriceCandidate(String raw) {
    final s = raw.trim();
    // Ignore lines with multiple numbers that are dates/keys or percentages at end
    if (s.endsWith('%')) return null;
    final lastPriceMatch = RegExp(r'(?:R\$\s*)?(\d{1,5}[\.,]\d{2})\s*$')
        .firstMatch(s);
    if (lastPriceMatch != null) {
      return _parseMoney(lastPriceMatch.group(1)!);
    }
    if (s.toUpperCase().startsWith('R\$')) {
      return _parseMoney(s);
    }
    return null;
  }

  Unit _parseUnit(String? raw) {
    if (raw == null || raw.isEmpty) return Unit.un;
    final norm = raw.toLowerCase().trim();

    switch (norm) {
      case 'kg':
      case 'k6':
      case 'k9':
      case 'kilos':
      case 'kilo':
        return Unit.kg;
      case 'g':
      case 'gr':
      case 'gramas':
      case 'grama':
        return Unit.g;
      case 'l':
      case 'lt':
      case 'litro':
      case 'litros':
        return Unit.l;
      case 'ml':
      case 'mls':
        return Unit.ml;
      case 'pack':
      case 'pct':
      case 'pacote':
      case 'cx':
      case 'caixa':
      case 'fd':
      case 'fardo':
      case 'pk':
        return Unit.pack;
      case 'un':
      case 'uk':
      case '0n':
      case 'on':
      case 'ün':
      case '1n':
      case 'tur':
      case 'bt':
      case 'und':
      case 'unid':
      case 'unidade':
      case 'pc':
      case 'pç':
      case 'peça':
      case 'pt':
      case 'pote':
      case 'la':
      case 'lata':
      case 'tb':
      case 'tubo':
      case 'fr':
      case 'frasco':
      default:
        return Unit.un;
    }
  }

  Quantity _parseQuantity(String rawVal, Unit unit) {
    final s = rawVal.trim().replaceAll(',', '.');
    final val = double.tryParse(s) ?? 1.0;

    final valueMilli = (val * 1000).round();
    return Quantity(valueMilli, unit);
  }

  Money? _parseMoney(String raw) {
    var s = raw.trim();
    // If multiple space-separated tokens, extract only the last decimal value
    // to never concatenate two distinct numbers (e.g. "99 7.79" -> "7.79", "2.39 4.78" -> "4.78").
    final decimalMatches = RegExp(r'\d{1,6}[\.,]\d{1,2}').allMatches(s);
    if (decimalMatches.isNotEmpty) {
      s = decimalMatches.last.group(0)!;
    }
    final cleaned = s.replaceAll(RegExp(r'R\$\s*'), '').trim();
    if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(cleaned)) {
      s = s.replaceAll('.', ',');
    }

    return Money.tryParsePtBr(s) ??
        Money.fromDouble(
          double.tryParse(
                s.replaceAll(RegExp(r'[^\d,\.]'), '').replaceAll(',', '.'),
              ) ??
              0.0,
        );
  }
}

class _PendingItemBuilder {
  final List<OcrRow> _rows = [];
  final List<String> _textParts = [];
  String? _itemIndex;
  String? _ean;
  Quantity? _quantity;
  Money? _unitPrice;
  Money? _totalPrice;

  bool get hasData => _rows.isNotEmpty || _textParts.isNotEmpty;
  bool get hasIndex => _itemIndex != null;
  bool get hasPrice => _unitPrice != null || _totalPrice != null;

  void addQtyLine(OcrRow row, _QtyMatch match) {
    _rows.add(row);
    _quantity = match.quantity;
    _unitPrice = match.unitPrice;
    if (match.totalPrice != null) {
      _totalPrice = match.totalPrice;
    }

    final textBefore = match.textBefore.trim();
    if (textBefore.isNotEmpty) {
      _extractIndexAndEanAndText(textBefore);
    }

    var textAfter = match.textAfter.trim();
    if (textAfter.isNotEmpty) {
      // Remove optional tax value in parentheses (e.g. "(11.04)") and repeated price at end
      textAfter = textAfter
          .replaceAll(RegExp(r'\(\s*\d+[\.,]\d{2}\s*\)'), ' ')
          .replaceAll(RegExp(r'(?:R\$\s*)?\d+[\.,]\d{2}\s*$'), ' ')
          .trim();
      if (textAfter.isNotEmpty) {
        _extractIndexAndEanAndText(textAfter);
      }
    }
  }

  void addDescriptionRowWithPrice(OcrRow row, Money price) {
    _rows.add(row);
    _totalPrice = price;

    final textWithoutPrice = _stripPriceFromText(row.text);
    if (textWithoutPrice.isNotEmpty) {
      _extractIndexAndEanAndText(textWithoutPrice);
    }
  }

  void addTextRow(OcrRow row) {
    _rows.add(row);
    final text = row.text.trim();
    if (text.isNotEmpty) {
      _extractIndexAndEanAndText(text);
    }
  }

  void _extractIndexAndEanAndText(String input) {
    var s = input.trim();

    if (_itemIndex == null) {
      final idxReg = RegExp(r'^#?(\d{1,3})[\.\)]?\s+');
      final match = idxReg.firstMatch(s);
      if (match != null) {
        _itemIndex = match.group(1);
        s = s.substring(match.end).trim();
      }
    }

    if (_ean == null) {
      // 1. Barcode/product code at start with possible leading characters corrupted by OCR
      // Ex: "T8912274", "Ta98632472837", "B410525146435", "V622210575975", "i 98005516373", "468435"
      final leadingCodeReg = RegExp(
        r'^(?:([A-Za-z0-9]{1,3})\s*)?([TiIlO0-9]{6,14})\b',
      );
      final leadingMatch = leadingCodeReg.firstMatch(s);
      if (leadingMatch != null) {
        final rawCode =
            '${leadingMatch.group(1) ?? ''}${leadingMatch.group(2)!}';
        final digitCount = rawCode.replaceAll(RegExp(r'[^0-9]'), '').length;
        if (digitCount >= 6) {
          _ean = rawCode
              .replaceAll(RegExp(r'[TtVv]'), '7')
              .replaceAll(RegExp(r'[BbAa]'), '8')
              .replaceAll(RegExp(r'[Ss]'), '5')
              .replaceAll(RegExp(r'[Gg]'), '6')
              .replaceAll(RegExp(r'[Oo]'), '0')
              .replaceAll(RegExp(r'[iIl]'), '1');
          s = s.substring(leadingMatch.end).trim();
        }
      }
    }

    if (_ean == null) {
      final eanReg = RegExp(r'\b(\d{6,14})\b');
      final match = eanReg.firstMatch(s);
      if (match != null) {
        _ean = match.group(1);
        s = s
            .replaceFirst(match.group(0)!, '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }

    // Limpa sufixos fiscais isolados (ST, FF, II, NN) caso tenham sobrado de textAfter
    if (RegExp(r'^(ST|FF|II|NN|T|F|I|N)$', caseSensitive: false).hasMatch(s)) {
      return;
    }

    if (s.isNotEmpty) {
      _textParts.add(s);
    }
  }

  String _stripPriceFromText(String text) {
    var s = text.trim();
    final reg = RegExp(r'(?:R\$\s*)?(\d{1,5}[\.,]\d{2})\s*$');
    final match = reg.firstMatch(s);
    if (match != null) {
      s = s.substring(0, match.start).trim();
    }
    return s;
  }

  ReceiptItemDraft? build() {
    final rawDesc = _textParts.join(' ').trim();
    if (rawDesc.isEmpty) return null;

    final qty = _quantity ?? const Quantity(1000, Unit.un);
    Money totalP = _totalPrice ?? Money.zero;
    Money unitP = _unitPrice ?? Money.zero;

    if (_unitPrice == null && _totalPrice != null) {
      if (qty.valueMilli > 0) {
        unitP = Money((_totalPrice!.cents * 1000 / qty.valueMilli).round());
      } else {
        unitP = _totalPrice!;
      }
    } else if (_unitPrice != null && _totalPrice == null) {
      final numerator = qty.valueMilli;
      const denominator = 1000;
      totalP = unitP.timesRatio(numerator, denominator);
    } else if (_unitPrice == null && _totalPrice == null) {
      return null;
    }

    double totalConf = 0.0;
    int countConf = 0;
    for (final r in _rows) {
      for (final e in r.elements) {
        totalConf += e.confidence;
        countConf++;
      }
      if (r.elements.isEmpty) {
        totalConf += r.averageConfidence;
        countConf++;
      }
    }
    final avgConf = countConf > 0 ? (totalConf / countConf) : 1.0;

    return ReceiptItemDraft(
      rawDescription: rawDesc,
      ean: _ean,
      quantity: qty,
      unitPrice: unitP,
      totalPrice: totalP,
      confidence: avgConf,
    );
  }
}
