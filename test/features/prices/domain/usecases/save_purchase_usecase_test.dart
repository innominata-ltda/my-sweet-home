import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/save_purchase_usecase.dart';

class FakePurchaseRepository implements PurchaseRepository {
  Result<void, Failure> saveResult = const Ok(null);
  Purchase? lastSaved;

  @override
  Future<Result<void, Failure>> save(Purchase purchase) async {
    lastSaved = purchase;
    return saveResult;
  }

  @override
  Future<Result<Purchase?, Failure>> findById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Purchase>, Failure>> getAll() async {
    return Ok(lastSaved != null ? [lastSaved!] : []);
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

class FakePricePointRepository implements PricePointRepository {
  Result<void, Failure> saveAllResult = const Ok(null);
  List<PricePoint>? lastSavedPoints;
  String? lastPurchaseId;

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async {
    lastSavedPoints = points;
    lastPurchaseId = purchaseId;
    return saveAllResult;
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
    throw UnimplementedError();
  }

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('SavePurchaseUseCase', () {
    late FakePurchaseRepository purchaseRepo;
    late FakePricePointRepository pricePointRepo;
    late SavePurchaseUseCase useCase;

    setUp(() {
      purchaseRepo = FakePurchaseRepository();
      pricePointRepo = FakePricePointRepository();
      useCase = SavePurchaseUseCase(
        purchaseRepository: purchaseRepo,
        pricePointRepository: pricePointRepo,
      );
    });

    test('deve salvar a compra e gerar os price points corretos', () async {
      // Compra de 1.5kg de produto por R$ 15,00
      // Expected normalized price: R$ 10.00/kg (1000 cents)
      final purchase = Purchase(
        id: 'p1',
        storeId: 's1',
        date: DateTime(2026, 9, 25),
        items: [
          PurchaseItem(
            id: 'i1',
            productId: 'prod1',
            quantity: const Quantity(1500, Unit.kg), // 1.5kg
            unitPrice: const Money(1000),
            totalPrice: const Money(1500),
          ),
          PurchaseItem(
            id: 'i2',
            productId: 'prod2',
            quantity: const Quantity(500, Unit.l), // 0.5l
            unitPrice: const Money(400),
            totalPrice: const Money(200),
          ),
        ],
        totalAmount: const Money(1700),
        discountAmount: Money.zero,
      );

      final result = await useCase(purchase);

      expect(result.isOk, isTrue);
      expect(purchaseRepo.lastSaved, purchase);
      expect(pricePointRepo.lastPurchaseId, 'p1');

      final points = pricePointRepo.lastSavedPoints;
      expect(points, isNotNull);
      expect(points!.length, 2);

      // Verification of point 1
      final p1 = points[0];
      expect(p1.id, 'p1_i1');
      expect(p1.productId, 'prod1');
      expect(p1.storeId, 's1');
      expect(p1.unit, Unit.kg);
      expect(p1.normalizedPrice.cents, 1000); // R$ 10,00/kg

      // Verification of point 2
      final p2 = points[1];
      expect(p2.id, 'p1_i2');
      expect(p2.productId, 'prod2');
      expect(p2.unit, Unit.l);
      expect(p2.normalizedPrice.cents, 400); // R$ 4,00/L (200 / 0.5)
    });
  });
}
