import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:drift/drift.dart';

void main() {
  group('ProductDao merge e undoMerge', () {
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

    test('CA-4.1: in-memory db populated; compares counts before/after and after undo (CA-4.2)', () async {
      // Setup
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion(
              id: const Value('cat-1'),
              name: const Value('Cat'),
              kind: const Value('product'),
              iconKey: const Value('icon'),
            ),
          );

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

      // Add alias to loser
      await dao.addAlias(loser.id, 'leitao', AliasSource.user);

      // Verify before merge
      final winnerAliasesBefore = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserAliasesBefore = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(winnerAliasesBefore.length, 1); // just canonical name
      expect(loserAliasesBefore.length, 2); // canonical name + leitao

      final winnerArchivedBefore = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(winner.id))).getSingle();
      final loserArchivedBefore = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(loser.id))).getSingle();
      expect(winnerArchivedBefore.isArchived, false);
      expect(loserArchivedBefore.isArchived, false);

      // Execute merge
      final mergeResult = await dao.merge(from: loser.id, into: winner.id);
      expect(mergeResult.isOk, true);
      final receipt = mergeResult.valueOrNull!;

      // Verify after merge
      final winnerAliasesAfter = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserAliasesAfter = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(
        winnerAliasesAfter.length,
        3,
      ); // winner's canonical + loser's canonical + leitao
      expect(loserAliasesAfter.length, 0);

      final loserArchivedAfter = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(loser.id))).getSingle();
      expect(loserArchivedAfter.isArchived, true);

      // Undo merge
      final undoResult = await dao.undoMerge(receipt.id);
      expect(undoResult.isOk, true);

      // Verify after undo
      final winnerAliasesUndo = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(winner.id))).get();
      final loserAliasesUndo = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(loser.id))).get();
      expect(winnerAliasesUndo.length, 1);
      expect(loserAliasesUndo.length, 2);

      final loserArchivedUndo = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(loser.id))).getSingle();
      expect(loserArchivedUndo.isArchived, false);
    });
  });
}
