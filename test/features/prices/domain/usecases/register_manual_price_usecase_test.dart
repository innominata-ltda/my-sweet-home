import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/register_manual_price_usecase.dart';

import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';

class FakePricePointRepository implements PricePointRepository {
  Result<void, Failure> saveAllResult = const Ok(null);
  List<PricePoint>? lastSavedPoints;

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async {
    lastSavedPoints = points;
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

class FakeClock implements Clock {
  final DateTime _now = DateTime(2026, 9, 25);

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime todayUtc() => DateTime.utc(_now.year, _now.month, _now.day);
}

class FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() {
    _counter++;
    return 'fake_id_$_counter';
  }
}

void main() {
  group('RegisterManualPriceUseCase', () {
    late FakePricePointRepository repository;
    late FakeClock clock;
    late FakeIdGenerator idGenerator;
    late RegisterManualPriceUseCase useCase;

    setUp(() {
      repository = FakePricePointRepository();
      clock = FakeClock();
      idGenerator = FakeIdGenerator();
      useCase = RegisterManualPriceUseCase(
        pricePointRepository: repository,
        clock: clock,
        idGenerator: idGenerator,
      );
    });

    test(
      'must create manual price point with generated id and current date',
      () async {
        final result = await useCase(
          productId: 'prod1',
          storeId: 'store1',
          price: const Money(1500), // R$ 15,00
          quantity: const Quantity(500000, Unit.g), // 500g
        );

        expect(result.isOk, isTrue);

        final points = repository.lastSavedPoints;
        expect(points, isNotNull);
        expect(points!.length, 1);

        final point = points.first;
        expect(point.id, 'fake_id_1');
        expect(point.productId, 'prod1');
        expect(point.storeId, 'store1');
        expect(point.date, clock.nowUtc());
        expect(point.source, PricePointSource.manual);

        // Normalized price: 500g costs 15.00 -> 1kg costs 30.00
        expect(point.unit, Unit.kg);
        expect(point.normalizedPrice.cents, 3000);
      },
    );

    test('deve respeitar a data fornecida', () async {
      final customDate = DateTime(2026, 1, 1);
      final result = await useCase(
        productId: 'prod1',
        storeId: 'store1',
        price: const Money(500),
        quantity: const Quantity(1000, Unit.un), // 1 unidade
        date: customDate,
      );

      expect(result.isOk, isTrue);

      final point = repository.lastSavedPoints!.first;
      expect(point.date, customDate);
      expect(point.unit, Unit.un);
      expect(point.normalizedPrice.cents, 500);
    });
  });
}
