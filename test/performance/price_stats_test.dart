import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/data/price_point/sqlite_price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';

void main() {
  late db.AppDatabase database;
  late SqlitePricePointRepository repository;

  setUp(() async {
    database = db.AppDatabase.memory();
    repository = SqlitePricePointRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('T-08 / CA-8.1: Performance and indices of aggregated price queries', () {
    test('EXPLAIN QUERY PLAN confirms index usage for aggregations and lookups by product and store', () async {
      final nowIso = DateTime.now().toUtc().toIso8601String();

      // Consulta de agregados por produto
      final statsPlan = await database
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT AVG(normalized_price_cents), COUNT(id) '
            'FROM price_points WHERE product_id = ? AND deleted_at IS NULL AND observed_at >= ?',
            variables: [
              Variable.withString('prod-1'),
              Variable.withString(nowIso),
            ],
          )
          .get();

      final statsPlanDetail = statsPlan
          .map((r) => r.read<String>('detail'))
          .join('\n');
      expect(statsPlanDetail, contains('idx_pp_product_date'));
      expect(statsPlanDetail, isNot(contains('SCAN TABLE price_points')));

      // History query with store filter
      final storePlan = await database
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM price_points '
            'WHERE product_id = ? AND store_id = ? AND deleted_at IS NULL AND observed_at >= ? '
            'ORDER BY observed_at DESC',
            variables: [
              Variable.withString('prod-1'),
              Variable.withString('store-1'),
              Variable.withString(nowIso),
            ],
          )
          .get();

      final storePlanDetail = storePlan
          .map((r) => r.read<String>('detail'))
          .join('\n');
      expect(storePlanDetail, contains('idx_pp_product_store'));
      expect(storePlanDetail, isNot(contains('SCAN TABLE price_points')));
    });

    test('getStatsByProduct with 10,000 points responds in <50ms and calculates correct average (CA-8.1, RNF-002)', () async {
      final now = DateTime.utc(2026, 9, 30, 12, 0, 0);
      final since = now.subtract(const Duration(days: 30));

      // Insere registros pai para respeitar as chaves estrangeiras
      await database
          .into(database.stores)
          .insert(
            db.StoresCompanion.insert(id: 'store-1', name: 'Mercado Teste'),
          );

      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'product-perf-1',
              canonicalName: 'Produto Perf 1',
              defaultUnit: 'kg',
            ),
          );

      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'product-perf-other',
              canonicalName: 'Produto Perf Outro',
              defaultUnit: 'kg',
            ),
          );

      // Populates 10,000 valid points for target product
      await database.batch((batch) {
        for (var i = 0; i < 10000; i++) {
          batch.insert(
            database.pricePoints,
            db.PricePointsCompanion.insert(
              id: 'pp-$i',
              productId: const Value('product-perf-1'),
              storeId: const Value('store-1'),
              observedAt: now.subtract(Duration(minutes: i)).toIso8601String(),
              unitPriceCents: 500 + (i % 100),
              normalizedPriceCents: 500 + (i % 100),
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );
        }

        // Populates 500 excluded points (must be ignored)
        for (var i = 0; i < 500; i++) {
          batch.insert(
            database.pricePoints,
            db.PricePointsCompanion.insert(
              id: 'pp-del-$i',
              productId: const Value('product-perf-1'),
              storeId: const Value('store-1'),
              observedAt: now.subtract(Duration(minutes: i)).toIso8601String(),
              unitPriceCents: 9999,
              normalizedPriceCents: 9999,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
              deletedAt: Value(now.toIso8601String()),
            ),
          );
        }

        // Popula 500 pontos fora da janela de 30 dias (devem ser ignorados)
        for (var i = 0; i < 500; i++) {
          batch.insert(
            database.pricePoints,
            db.PricePointsCompanion.insert(
              id: 'pp-old-$i',
              productId: const Value('product-perf-1'),
              storeId: const Value('store-1'),
              observedAt: now
                  .subtract(Duration(days: 35 + i))
                  .toIso8601String(),
              unitPriceCents: 9999,
              normalizedPriceCents: 9999,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );
        }

        // Popula 500 pontos de outro produto (devem ser ignorados)
        for (var i = 0; i < 500; i++) {
          batch.insert(
            database.pricePoints,
            db.PricePointsCompanion.insert(
              id: 'pp-other-$i',
              productId: const Value('product-perf-other'),
              storeId: const Value('store-1'),
              observedAt: now.subtract(Duration(minutes: i)).toIso8601String(),
              unitPriceCents: 1234,
              normalizedPriceCents: 1234,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );
        }
      });

      // Warmup
      await repository.getStatsByProduct(
        'product-perf-1',
        since: since,
        windowDays: 30,
      );

      // Performance measurement
      final stopwatch = Stopwatch()..start();
      final result = await repository.getStatsByProduct(
        'product-perf-1',
        since: since,
        windowDays: 30,
      );
      stopwatch.stop();

      expect(result, isA<Ok<PriceStats, Failure>>());
      final stats = (result as Ok<PriceStats, Failure>).value;

      expect(stats.observationsCount, equals(10000));
      expect(stats.averagePrice, equals(const Money(550)));
      expect(stats.windowDays, equals(30));

      // Requisito RNF-002 / CA-8.1: < 50ms
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason:
            'Consulta agregada com 10.000 pontos levou ${stopwatch.elapsedMilliseconds}ms (limite 50ms)',
      );
    });
  });
}
