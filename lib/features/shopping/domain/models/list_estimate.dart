import 'package:my_sweet_home/core/money/money.dart';

/// Estimativa de custo de uma lista de compras (RN-083).
///
/// Deliberately separates what has price from what does not, to never
/// pretend precision that does not exist (CA-2.1).
final class ListEstimate {
  const ListEstimate({
    required this.known,
    required this.itemsWithoutPrice,
    this.oldestPriceUsed,
  });

  /// Sum of items whose price is known. In cents (RN-001).
  final Money known;

  /// Number of items for which no price is available.
  /// Exibido separadamente — NUNCA embutido no total.
  final int itemsWithoutPrice;

  /// Date of oldest price point used in calculation.
  /// Allows UI to display "price of August 12" as warning of potential obsolescence.
  final DateTime? oldestPriceUsed;

  /// Indicates if all items have known price.
  bool get isComplete => itemsWithoutPrice == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListEstimate &&
          other.known == known &&
          other.itemsWithoutPrice == itemsWithoutPrice &&
          other.oldestPriceUsed == oldestPriceUsed;

  @override
  int get hashCode => Object.hash(known, itemsWithoutPrice, oldestPriceUsed);

  @override
  String toString() =>
      'ListEstimate(known: ${known.formatPtBr()}, '
      'itemsWithoutPrice: $itemsWithoutPrice, '
      'oldestPriceUsed: $oldestPriceUsed)';
}
