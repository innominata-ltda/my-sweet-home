import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/data/price_point/sqlite_price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';

void main() {
  late db.AppDatabase database;
  late SqlitePricePointRepository repository;

  setUp(() {
    database = db.AppDatabase.memory();
    repository = SqlitePricePointRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Saves price points and queries sorted history', () async {
    // Setup - add store, category, product
    await database
        .into(database.stores)
        .insert(
          db.StoresCompanion.insert(
            id: 's1',
            name: 'Mercado Teste',
            createdAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
            updatedAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Mercado',
            kind: 'product',
            iconKey: 'cart',
          ),
        );
    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod1',
            canonicalName: 'Arroz',
            categoryId: const Value('cat1'),
            defaultUnit: 'kg',
          ),
        );

    final points = [
      PricePoint(
        id: 'pp1',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 20),
        normalizedPrice: const Money(450),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
      PricePoint(
        id: 'pp2',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 25),
        normalizedPrice: const Money(400),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
    ];

    final saveResult = await repository.saveAll(points);
    expect(saveResult.isOk, isTrue);

    final getResult = await repository.getByProduct(
      'prod1',
      since: DateTime.utc(2026, 1, 1),
    );
    expect(getResult.isOk, isTrue);

    final loadedPoints = getResult.valueOrNull!;
    expect(loadedPoints, hasLength(2));
    // Should be ordered by date descending
    expect(loadedPoints[0].id, 'pp2');
    expect(loadedPoints[1].id, 'pp1');
  });

  test('Price statistics aggregate correctly', () async {
    await database
        .into(database.stores)
        .insert(
          db.StoresCompanion.insert(
            id: 's1',
            name: 'Mercado Teste',
            createdAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
            updatedAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Mercado',
            kind: 'product',
            iconKey: 'cart',
          ),
        );
    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod1',
            canonicalName: 'Feijão',
            categoryId: const Value('cat1'),
            defaultUnit: 'kg',
          ),
        );

    final points = [
      PricePoint(
        id: 'pp1',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 20),
        normalizedPrice: const Money(500),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
      PricePoint(
        id: 'pp2',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 25),
        normalizedPrice: const Money(600),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
    ];

    await repository.saveAll(points);

    final statsResult = await repository.getStatsByProduct(
      'prod1',
      since: DateTime.utc(2026, 9, 1),
      windowDays: 30,
    );

    expect(statsResult.isOk, isTrue);
    final stats = statsResult.valueOrNull!;
    expect(stats.observationsCount, 2);
    expect(stats.averagePrice.cents, 550); // (500 + 600) / 2
  });

  test('Ranking de lojas agrupa e ordena', () async {
    await database
        .into(database.stores)
        .insert(
          db.StoresCompanion.insert(
            id: 's1',
            name: 'Mercado Caro',
            createdAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
            updatedAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
          ),
        );
    await database
        .into(database.stores)
        .insert(
          db.StoresCompanion.insert(
            id: 's2',
            name: 'Mercado Barato',
            createdAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
            updatedAt: Value(DateTime.utc(2026, 9, 20).toIso8601String()),
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Mercado',
            kind: 'product',
            iconKey: 'cart',
          ),
        );
    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod1',
            canonicalName: 'Feijão',
            categoryId: const Value('cat1'),
            defaultUnit: 'kg',
          ),
        );

    final points = [
      // Mercado Caro
      PricePoint(
        id: 'pp1',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 20),
        normalizedPrice: const Money(800),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
      PricePoint(
        id: 'pp2',
        productId: 'prod1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 21),
        normalizedPrice: const Money(800),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
      // Mercado Barato
      PricePoint(
        id: 'pp3',
        productId: 'prod1',
        storeId: 's2',
        date: DateTime.utc(2026, 9, 22),
        normalizedPrice: const Money(500),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
      PricePoint(
        id: 'pp4',
        productId: 'prod1',
        storeId: 's2',
        date: DateTime.utc(2026, 9, 23),
        normalizedPrice: const Money(500),
        unit: Unit.kg,
        source: PricePointSource.manual,
      ),
    ];

    await repository.saveAll(points);

    final rankingResult = await repository.getCheapestStores(
      'prod1',
      since: DateTime.utc(2026, 9, 1),
      minObservations: 2,
    );

    expect(
      rankingResult.isOk,
      isTrue,
      reason: rankingResult.failureOrNull?.toString(),
    );
    final rankings = rankingResult.valueOrNull!;
    expect(rankings, hasLength(2));

    // Ordered by cheapest
    expect(rankings[0].store.id, 's2'); // 500
    expect(rankings[0].averageNormalized.cents, 500);

    expect(rankings[1].store.id, 's1'); // 800
    expect(rankings[1].averageNormalized.cents, 800);
  });
}
