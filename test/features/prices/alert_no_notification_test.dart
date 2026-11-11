import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/price_alert/price_alert_policy.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/save_purchase_usecase.dart';

import '../../fakes/recording_scheduler.dart';

class _FakePurchaseRepository implements PurchaseRepository {
  Purchase? savedPurchase;

  @override
  Future<Result<void, Failure>> save(Purchase purchase) async {
    savedPurchase = purchase;
    return const Ok(null);
  }

  @override
  Future<Result<Purchase?, Failure>> findById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Purchase>, Failure>> getAll() async {
    return Ok(savedPurchase != null ? [savedPurchase!] : []);
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void, Failure>> restore(String id) async {
    throw UnimplementedError();
  }
}

class _FakePricePointRepository implements PricePointRepository {
  List<PricePoint>? savedPoints;

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async {
    savedPoints = points;
    return const Ok(null);
  }

  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async {
    return const Ok(
      PriceStats(
        averagePrice: Money(500), // R$ 5,00
        observationsCount: 5,
        windowDays: 30,
      ),
    );
  }

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async {
    return const Ok([]);
  }
}

void main() {
  group('CA-4.3 (RN-064): Price variation alert on screen and NO scheduled notification', () {
    late _FakePurchaseRepository purchaseRepo;
    late _FakePricePointRepository pricePointRepo;
    late RecordingScheduler recordingScheduler;
    late SavePurchaseUseCase savePurchaseUseCase;
    late PriceAlertPolicy alertPolicy;

    setUp(() {
      purchaseRepo = _FakePurchaseRepository();
      pricePointRepo = _FakePricePointRepository();
      recordingScheduler = RecordingScheduler();
      savePurchaseUseCase = SavePurchaseUseCase(
        purchaseRepository: purchaseRepo,
        pricePointRepository: pricePointRepo,
      );
      alertPolicy = const DefaultPriceAlertPolicy();
    });

    test('dado um alerta de variacao disparado ao salvar a compra, nenhuma notificacao push e agendada', () async {
      // 1. Purchase with item of R$ 6.50 (when product historical average is R$ 5.00 -> +30%)
      final purchase = Purchase(
        id: 'pur-101',
        storeId: 'store-1',
        date: DateTime(2026, 9, 30),
        items: [
          const PurchaseItem(
            id: 'item-101',
            productId: 'prod-arroz',
            quantity: Quantity(1000, Unit.un),
            unitPrice: Money(650),
            totalPrice: Money(650),
          ),
        ],
        totalAmount: const Money(650),
        discountAmount: Money.zero,
      );

      // 2. Evaluate price variation alert
      final statsResult = await pricePointRepo.getStatsByProduct(
        'prod-arroz',
        since: DateTime.now(),
        windowDays: 30,
      );
      expect(statsResult.isOk, isTrue);
      final stats = statsResult.valueOrNull!;

      final alert = alertPolicy.evaluate(
        productId: 'prod-arroz',
        observed: purchase.items.first.unitPrice,
        stats: stats,
        thresholdPercent: 20.0,
      );

      // Alert MUST have fired (appears on confirmation screen)
      expect(alert, isNotNull);
      expect(alert!.message, equals('Alta de 30% sobre a média de 30 dias'));

      // 3. Salvar a compra
      final saveResult = await savePurchaseUseCase(purchase);
      expect(saveResult.isOk, isTrue);

      // 4. Assertion CA-4.3: NO push notification was scheduled in RecordingScheduler (RN-064)
      final pendingNotifications = await recordingScheduler.pending();
      expect(pendingNotifications, isEmpty);
      expect(recordingScheduler.scheduled, isEmpty);
    });
  });
}
