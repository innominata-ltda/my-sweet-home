import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/products/domain/default_product_matcher.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';

/// Domain service/component to link receipt items ([ReceiptItemDraft])
/// to canonical products from catalog using [ProductMatcher] (SPEC-002, RN-197, CA-3.2).
final class ReceiptItemMatcher {
  final ProductMatcher matcher;

  const ReceiptItemMatcher({this.matcher = const DefaultProductMatcher()});

  /// Links single [ReceiptItemDraft] to catalog using [ProductIndex].
  ///
  /// Executa o [ProductMatcher.match] com [item.rawDescription].
  /// If match exists ([SingleMatch] or [AmbiguousMatch]), populates item [match] field.
  ReceiptItemDraft matchItem(ReceiptItemDraft item, ProductIndex index) {
    if (item.rawDescription.trim().isEmpty) {
      return item.copyWith(clearMatch: true);
    }

    final matchResult = matcher.match(item.rawDescription, index);

    return switch (matchResult) {
      SingleMatch(:final match) => item.copyWith(match: match),
      AmbiguousMatch(:final candidates) =>
        candidates.isNotEmpty
            ? item.copyWith(match: candidates.first)
            : item.copyWith(),
      NoMatch() => item.copyWith(),
    };
  }

  /// Links item list of a [ReceiptDraft] to catalog using [ProductIndex].
  ReceiptDraft matchReceipt(ReceiptDraft draft, ProductIndex index) {
    final matchedItems = draft.items
        .map((item) => matchItem(item, index))
        .toList();
    return draft.copyWith(items: matchedItems);
  }
}
