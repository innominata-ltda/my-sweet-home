import 'package:my_sweet_home/features/ocr/domain/date_time_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/header_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/items_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/totals_parser.dart';

/// Interface pura para o parser completo de nota fiscal.
abstract interface class ReceiptParser {
  ReceiptDraft parse(OcrDocument doc);
}

/// Default implementation of [ReceiptParser], integrating sub-parsers
/// for header, date/time, items and totals.
final class DefaultReceiptParser implements ReceiptParser {
  final HeaderParser headerParser;
  final DateTimeParser dateTimeParser;
  final ItemsParser itemsParser;
  final TotalsParser totalsParser;

  const DefaultReceiptParser({
    this.headerParser = const HeaderParser(),
    this.dateTimeParser = const DateTimeParser(),
    this.itemsParser = const ItemsParser(),
    this.totalsParser = const TotalsParser(),
  });

  @override
  ReceiptDraft parse(OcrDocument doc) {
    if (doc.lines.isEmpty) {
      return ReceiptDraft(
        store: const StoreDraft(),
        items: const [],
        confidence: 0.0,
      );
    }

    final store = headerParser.parse(doc);
    final purchasedAt = dateTimeParser.parseDocument(doc);
    final items = itemsParser.parseItems(doc);
    final totals = totalsParser.parseDocument(doc);

    final itemConfs = items.map((i) => i.confidence);
    final confList = [
      if (store.confidence > 0) store.confidence,
      if (totals.confidence > 0) totals.confidence,
      ...itemConfs,
    ];

    final confidence = confList.isNotEmpty
        ? (confList.reduce((a, b) => a + b) / confList.length).clamp(0.0, 1.0)
        : doc.averageConfidence;

    return ReceiptDraft(
      store: store,
      purchasedAt: purchasedAt,
      items: items,
      subtotal: totals.subtotal,
      discount: totals.discount,
      total: totals.total,
      paymentMethod: totals.paymentMethod,
      confidence: confidence,
    );
  }
}
