import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart'
    as db
    hide Store, PricePoint;
import 'package:my_sweet_home/features/prices/data/price_point/sqlite_price_point_repository.dart';
import 'package:my_sweet_home/features/prices/data/store/sqlite_store_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/get_product_price_stats_usecase.dart';

class _FakeClock implements Clock {
  _FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime todayUtc() => DateTime.utc(_now.year, _now.month, _now.day);
}

Future<void> _insertProduct(db.AppDatabase database, String productId) async {
  await database
      .into(database.products)
      .insertOnConflictUpdate(
        db.ProductsCompanion.insert(
          id: productId,
          canonicalName: productId,
          defaultUnit: 'kg',
        ),
      );
}

void main() {
  late db.AppDatabase database;
  late SqlitePricePointRepository pricePointRepo;
  late SqliteStoreRepository storeRepo;
  late GetProductPriceStatsUseCase useCase;
  late DateTime fixedDate;

  setUp(() async {
    database = db.AppDatabase.memory();
    pricePointRepo = SqlitePricePointRepository(database);
    storeRepo = SqliteStoreRepository(database);
    fixedDate = DateTime(2026, 9, 30, 12, 0);
    useCase = GetProductPriceStatsUseCase(
      repository: pricePointRepo,
      clock: _FakeClock(fixedDate),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('T-07 / RF-030 / RN-056 / CA-3.2: Ranking of cheapest store', () {
    test(
      'StoreRanking value object identifica pouca informação corretamente',
      () {
        final store = Store(
          id: 's1',
          name: 'Mercado A',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        );

        final r1 = StoreRanking(
          store: store,
          averageNormalized: const Money(500),
          observations: 1,
          minObservations: 2,
        );

        final r2 = StoreRanking(
          store: store,
          averageNormalized: const Money(500),
          observations: 2,
          minObservations: 2,
        );

        expect(r1.hasLittleData, isTrue);
        expect(r2.hasLittleData, isFalse);
      },
    );

    test('CA-3.2: Given 1 obs in Store A and 4 in Store B, Store A is marked as low info and is not declared winner', () async {
      // Cadastrar estabelecimentos
      final storeA = Store(
        id: 'store-a',
        name: 'Mercado A',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final storeB = Store(
        id: 'store-b',
        name: 'Mercado B',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      await storeRepo.save(storeA);
      await storeRepo.save(storeB);

      const productId = 'prod-cafe';
      await _insertProduct(database, productId);

      // 1 observation in Store A (R$ 5.00 normalized)
      final pointsA = [
        PricePoint(
          id: 'pp-a1',
          productId: productId,
          storeId: storeA.id,
          date: fixedDate.subtract(const Duration(days: 2)),
          normalizedPrice: const Money(500),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      ];

      // 4 observations in Store B (R$ 6.00 normalized)
      final pointsB = List.generate(4, (index) {
        return PricePoint(
          id: 'pp-b${index + 1}',
          productId: productId,
          storeId: storeB.id,
          date: fixedDate.subtract(Duration(days: index + 1)),
          normalizedPrice: const Money(600),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        );
      });

      await pricePointRepo.saveAll([...pointsA, ...pointsB]);

      // Consultar ranking via UseCase
      final rankingResult = await useCase.getCheapestStores(
        productId,
        windowDays: 30,
      );
      expect(rankingResult.isOk, isTrue);

      final rankings = rankingResult.valueOrNull!;
      expect(rankings.length, equals(2));

      // Store B comes first being the cheapest solid conclusion (observations >= 2)
      final firstRank = rankings[0];
      expect(firstRank.store.id, equals(storeB.id));
      expect(firstRank.observations, equals(4));
      expect(firstRank.hasLittleData, isFalse); // Vencedor declarado!

      // Store A comes next, marked as low information
      final secondRank = rankings[1];
      expect(secondRank.store.id, equals(storeA.id));
      expect(secondRank.observations, equals(1));
      expect(
        secondRank.hasLittleData,
        isTrue,
      ); // Low information! NOT the declared winner
    });

    test(
      'Ordena lojas conclusivas por preço médio normalizado crescente',
      () async {
        final store1 = Store(
          id: 's1',
          name: 'Mercado Caro',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        );
        final store2 = Store(
          id: 's2',
          name: 'Mercado Barato',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        );
        await storeRepo.save(store1);
        await storeRepo.save(store2);

        const productId = 'prod-arroz';
        await _insertProduct(database, productId);

        // Store 1: 3 obs a R$ 10,00
        final points1 = List.generate(
          3,
          (i) => PricePoint(
            id: 'pp-1-$i',
            productId: productId,
            storeId: store1.id,
            date: fixedDate.subtract(Duration(days: i + 1)),
            normalizedPrice: const Money(1000),
            unit: Unit.kg,
            source: PricePointSource.purchase,
          ),
        );

        // Store 2: 3 obs a R$ 7,50
        final points2 = List.generate(
          3,
          (i) => PricePoint(
            id: 'pp-2-$i',
            productId: productId,
            storeId: store2.id,
            date: fixedDate.subtract(Duration(days: i + 1)),
            normalizedPrice: const Money(750),
            unit: Unit.kg,
            source: PricePointSource.purchase,
          ),
        );

        await pricePointRepo.saveAll([...points1, ...points2]);

        final rankingResult = await useCase.getCheapestStores(productId);
        expect(rankingResult.isOk, isTrue);

        final rankings = rankingResult.valueOrNull!;
        expect(rankings.length, 2);
        expect(rankings[0].store.id, equals(store2.id));
        expect(rankings[0].averageNormalized, equals(const Money(750)));
        expect(rankings[1].store.id, equals(store1.id));
        expect(rankings[1].averageNormalized, equals(const Money(1000)));
      },
    );

    test('Ignores observations outside window or deleted', () async {
      final store = Store(
        id: 's1',
        name: 'Mercado Teste',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      await storeRepo.save(store);

      const productId = 'prod-feijao';
      await _insertProduct(database, productId);

      // 2 recent observations
      final recentPoints = List.generate(
        2,
        (i) => PricePoint(
          id: 'pp-recent-$i',
          productId: productId,
          storeId: store.id,
          date: fixedDate.subtract(Duration(days: i + 1)),
          normalizedPrice: const Money(800),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      );

      // 1 observation from 40 days ago (outside 30-day window)
      final oldPoint = PricePoint(
        id: 'pp-old',
        productId: productId,
        storeId: store.id,
        date: fixedDate.subtract(const Duration(days: 40)),
        normalizedPrice: const Money(200),
        unit: Unit.kg,
        source: PricePointSource.purchase,
      );

      await pricePointRepo.saveAll([...recentPoints, oldPoint]);

      final rankingResult = await useCase.getCheapestStores(
        productId,
        windowDays: 30,
      );
      expect(rankingResult.isOk, isTrue);

      final rankings = rankingResult.valueOrNull!;
      expect(rankings.length, 1);
      expect(rankings[0].observations, equals(2));
      expect(rankings[0].averageNormalized, equals(const Money(800)));
    });

    test('On ties in normalized average price, breaks tie alphabetically by store name', () async {
      final storeB = Store(
        id: 'sb',
        name: 'Mercado Beta',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final storeA = Store(
        id: 'sa',
        name: 'Mercado Alfa',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      await storeRepo.save(storeB);
      await storeRepo.save(storeA);

      const productId = 'prod-acucar';
      await _insertProduct(database, productId);

      final pointsA = List.generate(
        2,
        (i) => PricePoint(
          id: 'pp-a-$i',
          productId: productId,
          storeId: storeA.id,
          date: fixedDate.subtract(Duration(days: i + 1)),
          normalizedPrice: const Money(500),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      );

      final pointsB = List.generate(
        2,
        (i) => PricePoint(
          id: 'pp-b-$i',
          productId: productId,
          storeId: storeB.id,
          date: fixedDate.subtract(Duration(days: i + 1)),
          normalizedPrice: const Money(500),
          unit: Unit.kg,
          source: PricePointSource.purchase,
        ),
      );

      await pricePointRepo.saveAll([...pointsA, ...pointsB]);

      final rankingResult = await useCase.getCheapestStores(productId);
      expect(rankingResult.isOk, isTrue);

      final rankings = rankingResult.valueOrNull!;
      expect(rankings.length, 2);
      expect(rankings[0].store.name, equals('Mercado Alfa'));
      expect(rankings[1].store.name, equals('Mercado Beta'));
    });
  });

  group('StoreRanking model', () {
    test('hasLittleData, operator == e hashCode', () {
      final store = Store(
        id: 's1',
        name: 'Supermercado Central',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final r1 = StoreRanking(
        store: store,
        averageNormalized: const Money(450),
        observations: 1,
        minObservations: 2,
      );

      final r2 = StoreRanking(
        store: store,
        averageNormalized: const Money(450),
        observations: 1,
        minObservations: 2,
      );

      final r3 = StoreRanking(
        store: store,
        averageNormalized: const Money(450),
        observations: 3,
        minObservations: 2,
      );

      expect(r1.hasLittleData, isTrue);
      expect(r3.hasLittleData, isFalse);

      expect(r1, equals(r1));
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1, isNot(equals('ranking')));
    });
  });
}
