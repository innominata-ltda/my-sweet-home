import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/extras/domain/stock_consumption_estimate.dart';
import 'package:my_sweet_home/features/extras/domain/stock_item.dart';
import 'package:my_sweet_home/features/extras/domain/stock_repository.dart';

class FakeStockRepository implements StockRepository {
  FakeStockRepository([Clock? clock]) : _clock = clock ?? SystemClock();

  final Clock _clock;
  final Map<String, StockItem> _itemsByProductId = {};
  final Map<String, List<DateTime>> _purchaseDatesByProductId = {};
  static final Map<String, DateTime> _lastAlertedDateByProductId = {};

  static void clearAlertHistory() => _lastAlertedDateByProductId.clear();

  void setPurchaseHistory(String productId, List<DateTime> purchaseDates) {
    _purchaseDatesByProductId[productId] = List.from(purchaseDates)..sort();
  }

  @override
  Future<Result<StockItem, Failure>> upsertStockItem({
    String? id,
    required String productId,
    required Quantity quantity,
    Quantity? lowStockThreshold,
    DateTime? lastRestockedAt,
  }) async {
    final existing = _itemsByProductId[productId];
    final itemId =
        id ?? existing?.id ?? 'stock-${_itemsByProductId.length + 1}';
    final now = _clock.nowUtc();

    final item = StockItem(
      id: itemId,
      productId: productId,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold ?? existing?.lowStockThreshold,
      lastRestockedAt: lastRestockedAt ?? existing?.lastRestockedAt ?? now,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _itemsByProductId[productId] = item;
    return Ok(item);
  }

  @override
  Future<Result<StockItem?, Failure>> getStockItemByProductId(
    String productId,
  ) async {
    return Ok(_itemsByProductId[productId]);
  }

  @override
  Future<Result<List<StockItem>, Failure>> getStockItems() async {
    return Ok(_itemsByProductId.values.toList());
  }

  @override
  Future<Result<void, Failure>> deleteStockItem(String id) async {
    _itemsByProductId.removeWhere(
      (_, item) => item.id == id || item.productId == id,
    );
    return const Ok(null);
  }

  @override
  Future<Result<StockConsumptionEstimate, Failure>> getConsumptionEstimate(
    String productId,
  ) async {
    final dates = _purchaseDatesByProductId[productId] ?? [];
    final count = dates.length;

    // RN-251 / CA-2.2: If fewer than 3 purchases, MUST NOT estimate!
    if (count < 3) {
      return Ok(
        StockConsumptionEstimate(
          productId: productId,
          purchaseCount: count,
          hasEnoughHistory: false,
        ),
      );
    }

    double totalDays = 0;
    for (int i = 1; i < dates.length; i++) {
      totalDays += dates[i].difference(dates[i - 1]).inHours / 24.0;
    }
    final avgInterval = totalDays / (dates.length - 1);

    final item = _itemsByProductId[productId];
    final refDate = item?.lastRestockedAt ?? dates.last;
    final daysSinceRef = _clock.nowUtc().difference(refDate).inHours / 24.0;
    final calcRemainingDays = (avgInterval - daysSinceRef).round();
    final displayRemainingDays = calcRemainingDays < 0 ? 0 : calcRemainingDays;

    final isLowStock =
        calcRemainingDays <= (avgInterval * 0.2).ceil() ||
        (calcRemainingDays <= 3 && calcRemainingDays < avgInterval);

    bool isAlertIssued = false;
    if (isLowStock) {
      final lastAlert = _lastAlertedDateByProductId[productId];
      if (lastAlert == null || lastAlert.isBefore(refDate)) {
        isAlertIssued = true;
        _lastAlertedDateByProductId[productId] = _clock.nowUtc();
      }
    }

    return Ok(
      StockConsumptionEstimate(
        productId: productId,
        purchaseCount: count,
        hasEnoughHistory: true,
        averageIntervalDays: avgInterval,
        estimatedDaysRemaining: displayRemainingDays,
        isLowStock: isLowStock,
        isAlertIssued: isAlertIssued,
      ),
    );
  }
}
