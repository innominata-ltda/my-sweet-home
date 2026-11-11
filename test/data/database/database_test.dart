library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  group('AppDatabase - schema e invariantes (T-11)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('Cria banco v1 com todas as tabelas', () async {
      // Simply insert into base table and check it works without exception.
      final productId = '01H...';
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: productId,
              canonicalName: 'Produto Teste',
              defaultUnit: 'un',
            ),
          );

      final count = await db.products.count().getSingle();
      expect(count, 1);
    });

    test(
      'Foreign Keys are active by default (PRAGMA foreign_keys = ON)',
      () async {
        // PRAGMA foreign_keys = ON is set in beforeOpen, so force
        // a abertura executando uma query de teste.
        await db.customSelect('SELECT 1').get();

        // Tenta inserir um alias para um produto inexistente.
        expect(
          () => db
              .into(db.productAliases)
              .insert(
                ProductAliasesCompanion.insert(
                  id: 'alias_id',
                  productId: 'produto_inexistente',
                  alias: 'teste',
                  normalizedAlias: 'teste',
                  source: 'test',
                ),
              ),
          throwsA(isA<SqliteException>()),
          reason: 'Must fail because product_id does not exist (FK)',
        );
      },
    );

    test('Chaves estrangeiras com CASCADE funcionam (ex.: delete de product deleta aliases)', () async {
      final productId = '01H...';
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: productId,
              canonicalName: 'Produto Teste',
              defaultUnit: 'un',
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'alias_id',
              productId: productId,
              alias: 'teste',
              normalizedAlias: 'teste',
              source: 'test',
            ),
          );

      // Deleta o produto
      await db.delete(db.products).go();

      // O alias deve ter sumido
      final count = await db.productAliases.count().getSingle();
      expect(count, 0);
    });

    test('Indexes are created correctly', () async {
      // Checks in sqlite master if manual indexes exist
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
          )
          .get();

      final indexNames = indexes
          .map((row) => row.read<String>('name'))
          .toList();

      expect(indexNames, contains('idx_pp_product_date'));
      expect(indexNames, contains('idx_pp_product_store'));
      expect(indexNames, contains('idx_alias_norm'));
      expect(indexNames, contains('idx_exp_month'));
      expect(indexNames, contains('idx_tasks_due'));
      expect(indexNames, contains('idx_bill_payments_due_status'));
      expect(indexNames, contains('idx_shopping_items_pos'));
    });

    test(
      'Cria banco v4 com stock_items e checklist_items (SPEC-011 T-I01)',
      () async {
        final productId = '01H_prod_1';
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: productId,
                canonicalName: 'Papel Higiênico',
                defaultUnit: 'un',
              ),
            );

        await db
            .into(db.stockItems)
            .insert(
              StockItemsCompanion.insert(
                id: 'stock_1',
                productId: productId,
                quantityMilli: const Value(4000),
                unit: const Value('un'),
              ),
            );

        final stockCount = await db.stockItems.count().getSingle();
        expect(stockCount, 1);

        await db
            .into(db.checklistItems)
            .insert(
              ChecklistItemsCompanion.insert(
                id: 'checklist_1',
                roomCategory: 'Banheiro',
                title: 'Toalha de banho',
                isMarked: const Value(false),
                position: const Value(1),
              ),
            );

        final checklistCount = await db.checklistItems.count().getSingle();
        expect(checklistCount, 1);
      },
    );

    test('Cria banco v7 com tasks.sourcePresetId, sync e hardening (SPEC-014 / SPEC-013 / SPEC-016)', () async {
      expect(db.schemaVersion, 7);

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task_preset_1',
              title: 'Lavar louça',
              sourcePresetId: const Value('wash-dishes'),
            ),
          );

      final task = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals('task_preset_1'))).getSingle();
      expect(task.sourcePresetId, 'wash-dishes');
    });
  });
}
