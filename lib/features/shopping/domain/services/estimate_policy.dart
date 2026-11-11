import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/shopping/domain/models/known_price.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';

/// Pure cost estimation policy for a shopping list (RN-083).
///
/// Receives list items and map of known prices (with store
/// preference already applied by caller) and returns a [ListEstimate]
/// separating priced total from unpriced items.
///
/// **Pure**: no I/O, no clock, no catalog. Directly testable.
abstract interface class EstimatePolicy {
  /// Calcula a estimativa.
  ///
  /// [items] — list items (checked or not; checked items are included
  ///           because user may still check them at register).
  /// [lastPrices] — map `productId -> KnownPrice`, with store
  ///               preference already resolved by caller (CA-2.2).
  ListEstimate estimate({
    required List<ShoppingItem> items,
    required Map<ProductId, KnownPrice> lastPrices,
  });
}

/// Default implementation of [EstimatePolicy].
///
/// - For each item with [ShoppingItem.productId] present in price map,
///   soma o [KnownPrice.price] ao total conhecido.
/// - Itens sem `productId` ou sem entrada no mapa incrementam
///   [ListEstimate.itemsWithoutPrice].
/// - [ListEstimate.oldestPriceUsed] is oldest date among prices
///   actually used (null if no price was used).
final class DefaultEstimatePolicy implements EstimatePolicy {
  const DefaultEstimatePolicy();

  @override
  ListEstimate estimate({
    required List<ShoppingItem> items,
    required Map<ProductId, KnownPrice> lastPrices,
  }) {
    var total = Money.zero;
    var withoutPrice = 0;
    DateTime? oldest;

    for (final item in items) {
      final productId = item.productId;
      if (productId == null) {
        withoutPrice++;
        continue;
      }

      final known = lastPrices[productId];
      if (known == null) {
        withoutPrice++;
        continue;
      }

      total = total + known.price;

      if (oldest == null || known.recordedAt.isBefore(oldest)) {
        oldest = known.recordedAt;
      }
    }

    return ListEstimate(
      known: total,
      itemsWithoutPrice: withoutPrice,
      oldestPriceUsed: oldest,
    );
  }
}
