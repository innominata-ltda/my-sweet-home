import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/shopping/domain/models/known_price.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/services/estimate_policy.dart';

/// Orquestra a estimativa de custo de uma lista de compras (RF-052, RN-083).
///
/// 1. Coleta todos os `productId`s distintos dos itens da lista.
/// 2. For each product, fetches price points in [PricePointRepository].
/// 3. Selects latest price, preferring store of the list (CA-2.2).
/// 4. Builds map `productId -> KnownPrice` and delegates to [EstimatePolicy].
///
/// Only queries price repository **once per product** (not once per
/// item), meeting performance budget of plan.md.
class GetListEstimateUseCase {
  GetListEstimateUseCase({
    required this.priceRepository,
    required this.policy,
    Clock? clock,
  }) : clock = clock ?? const SystemClock();

  final PricePointRepository priceRepository;
  final EstimatePolicy policy;
  final Clock clock;

  /// Returns [ListEstimate] for [list].
  ///
  /// [windowDays] controls how many days into past to search prices.
  Future<Result<ListEstimate, Failure>> call(
    ShoppingList list, {
    int windowDays = 365,
  }) async {
    // Unique products from list (only items linked to a product).
    final productIds = list.items
        .map((i) => i.productId)
        .whereType<ProductId>()
        .toSet();

    final since = clock.nowUtc().subtract(Duration(days: windowDays));

    // Builds productId -> KnownPrice map with store preference (CA-2.2).
    final Map<ProductId, KnownPrice> lastPrices = {};

    for (final productId in productIds) {
      final result = await priceRepository.getByProduct(
        productId,
        since: since,
      );

      if (result.isErr) return Err(result.failureOrNull!);

      final points = result.valueOrNull!;
      if (points.isEmpty) continue;

      final preferred = _selectBestPrice(points, list.storeId);
      if (preferred != null) {
        lastPrices[productId] = preferred;
      }
    }

    final estimate = policy.estimate(items: list.items, lastPrices: lastPrices);

    return Ok(estimate);
  }

  /// Selects most recent price point, preferring [preferredStoreId].
  ///
  /// Strategy (CA-2.2):
  ///   1. Filtra pontos do mercado preferido; se houver, usa o mais recente.
  ///   2. Otherwise, uses most recent point from any store.
  ///
  /// Retorna `null` se [points] estiver vazio.
  static KnownPrice? _selectBestPrice(
    List<PricePoint> points,
    String? preferredStoreId,
  ) {
    if (points.isEmpty) return null;

    List<PricePoint> candidates;
    if (preferredStoreId != null) {
      candidates = points.where((p) => p.storeId == preferredStoreId).toList();
    } else {
      candidates = [];
    }

    if (candidates.isEmpty) {
      candidates = points;
    }

    // Mais recente dentro dos candidatos.
    final best = candidates.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    return KnownPrice(
      price: _normalizedToItemPrice(best),
      recordedAt: best.date,
      storeId: best.storeId,
    );
  }

  /// Converts normalized price of [PricePoint] to price of 1 unit
  /// in reference unit of point itself (R$/kg -> Money for 1 kg).
  ///
  /// For list estimates, we use price per 1 reference unit
  /// as proxy for item cost. Precision is intentionally limited —
  /// RN-083 requires UI to make clear it is an estimate.
  static Money _normalizedToItemPrice(PricePoint point) {
    // normalizedPrice is already in BRL per reference unit (kg, l, un).
    // For simple estimate: we use normalized price directly.
    return point.normalizedPrice;
  }
}
