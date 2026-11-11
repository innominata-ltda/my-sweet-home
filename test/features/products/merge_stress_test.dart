import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:drift/drift.dart';

void main() {
  group('ProductDao Stress Test - CA-4.1 / CA-4.2', () {
    late AppDatabase db;
    late ProductDao dao;
    late IdGenerator idGen;
    late Clock clock;

    setUp(() {
      db = AppDatabase.memory();
      idGen = const UuidV7Generator();
      clock = SystemClock();
      dao = ProductDao(db, idGen, clock);
    });

    tearDown(() async {
      await db.close();
    });

    test('Mesclagem e desfazer com banco populado (estresse)', () async {
      // Setup de categoria
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion(
              id: const Value('cat-1'),
              name: const Value('Laticínios'),
              kind: const Value('product'),
              iconKey: const Value('icon'),
            ),
          );

      // Insert 2,000 random products and 10,000 price points for stress test
      final stopwatch = Stopwatch()..start();

      const numProducts = 2000;
      const numPricePointsPerProduct = 5;

      final productsToInsert = <ProductsCompanion>[];
      final aliasesToInsert = <ProductAliasesCompanion>[];
      final pricePointsToInsert = <PricePointsCompanion>[];

      for (var i = 0; i < numProducts; i++) {
        final pId = 'prod-stress-$i';
        productsToInsert.add(
          ProductsCompanion(
            id: Value(pId),
            canonicalName: Value('Produto $i'),
            categoryId: const Value('cat-1'),
            defaultUnit: const Value('un'),
            packageSizeMilli: const Value(1000),
            isArchived: const Value(false),
            createdAt: const Value('2026-01-01T00:00:00Z'),
            updatedAt: const Value('2026-01-01T00:00:00Z'),
          ),
        );

        aliasesToInsert.add(
          ProductAliasesCompanion(
            id: Value('alias-stress-$i'),
            productId: Value(pId),
            alias: Value('Produto $i'),
            normalizedAlias: Value('produto $i'),
            source: const Value('user'),
            createdAt: const Value('2026-01-01T00:00:00Z'),
          ),
        );

        for (var j = 0; j < numPricePointsPerProduct; j++) {
          pricePointsToInsert.add(
            PricePointsCompanion(
              id: Value('pp-stress-$i-$j'),
              productId: Value(pId),
              observedAt: const Value('2026-01-01T00:00:00Z'),
              unitPriceCents: Value(1000 + j),
              normalizedPriceCents: Value(1000 + j),
              quantityMilli: const Value(1000),
              unit: const Value('un'),
              source: const Value('manual'),
            ),
          );
        }
      }

      await db.batch((batch) {
        batch.insertAll(db.products, productsToInsert);
        batch.insertAll(db.productAliases, aliasesToInsert);
        batch.insertAll(db.pricePoints, pricePointsToInsert);
      });

      // print('Setup (populando DB): ${stopwatch.elapsedMilliseconds}ms');

      // Setup dos produtos do teste: Leite Integral e Leite Integral 1L
      final winnerResult = await dao.create(
        const NewProduct(
          canonicalName: 'Leite Integral',
          categoryId: 'cat-1',
          defaultUnit: Unit.l,
        ),
      );
      final winner = winnerResult.valueOrNull!;

      final loserResult = await dao.create(
        const NewProduct(
          canonicalName: 'Leite Desnatado',
          categoryId: 'cat-1',
          defaultUnit: Unit.l,
        ),
      );
      final loser = loserResult.valueOrNull!;

      // 12 price points para Leite Integral
      final winnerPP = <PricePointsCompanion>[];
      for (var i = 0; i < 12; i++) {
        winnerPP.add(
          PricePointsCompanion(
            id: Value('pp-winner-$i'),
            productId: Value(winner.id),
            observedAt: const Value('2026-01-01T00:00:00Z'),
            unitPriceCents: const Value(500),
            normalizedPriceCents: const Value(500),
            quantityMilli: const Value(1000),
            unit: const Value('l'),
            source: const Value('manual'),
          ),
        );
      }

      // 5 price points para Leite Integral 1L
      final loserPP = <PricePointsCompanion>[];
      for (var i = 0; i < 5; i++) {
        loserPP.add(
          PricePointsCompanion(
            id: Value('pp-loser-$i'),
            productId: Value(loser.id),
            observedAt: const Value('2026-01-01T00:00:00Z'),
            unitPriceCents: const Value(550),
            normalizedPriceCents: const Value(550),
            quantityMilli: const Value(1000),
            unit: const Value('l'),
            source: const Value('manual'),
          ),
        );
      }

      await db.batch((batch) {
        batch.insertAll(db.pricePoints, [...winnerPP, ...loserPP]);
      });

      // Verify before merge
      final winnerPPBefore = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserPPBefore = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(winnerPPBefore.length, 12);
      expect(loserPPBefore.length, 5);

      // Execute Merge
      stopwatch.reset();
      final mergeResult = await dao.merge(from: loser.id, into: winner.id);
      // print('Merge exec time: ${stopwatch.elapsedMilliseconds}ms');

      expect(mergeResult.isOk, true);
      final receipt = mergeResult.valueOrNull!;

      // Verify after merge CA-4.1
      final winnerPPAfter = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserPPAfter = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(
        winnerPPAfter.length,
        17,
        reason: 'Winner must have 17 price points after merge',
      );
      expect(
        loserPPAfter.length,
        0,
        reason: 'Loser must have 0 price points after merge',
      );

      final winnerAliasesAfter = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      expect(
        winnerAliasesAfter.length,
        2,
        reason: 'Winner must have 2 aliases (both canonicals)',
      );

      final loserArchivedAfter = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(loser.id))).getSingle();
      expect(
        loserArchivedAfter.isArchived,
        true,
        reason: 'Loser deve estar arquivado',
      );

      // Undo Merge CA-4.2
      stopwatch.reset();
      final undoResult = await dao.undoMerge(receipt.id);
      // print('Undo Merge exec time: ${stopwatch.elapsedMilliseconds}ms');

      expect(undoResult.isOk, true);

      // Verify after undo
      final winnerPPUndo = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserPPUndo = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(winnerPPUndo.length, 12, reason: 'Winner volta a ter 12 pontos');
      expect(loserPPUndo.length, 5, reason: 'Loser volta a ter 5 pontos');

      final winnerAliasesUndo = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserAliasesUndo = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(winnerAliasesUndo.length, 1);
      expect(loserAliasesUndo.length, 1);

      final loserArchivedUndo = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(loser.id))).getSingle();
      expect(
        loserArchivedUndo.isArchived,
        false,
        reason: 'Loser deve ser desarquivado',
      );
    });
  });
}
