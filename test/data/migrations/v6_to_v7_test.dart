import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Migration v6 to v7 — SPEC-016 (T-I02, RF-010, RF-124, RNF-008, 006 §4)',
    () {
      late Directory tempDir;
      late File dbFile;
      late AppDatabase db;

      setUp(() async {
        final fixtureFile = File('test/fixtures/db/v6_populated.sqlite');
        expect(
          fixtureFile.existsSync(),
          isTrue,
          reason: 'Execute dart run scripts/generate_fixture_v6.dart antes',
        );

        tempDir = Directory.systemTemp.createTempSync(
          'drift_migration_v7_test_',
        );
        dbFile = File('${tempDir.path}/app_v7.db');
        fixtureFile.copySync(dbFile.path);

        db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));
        // Forces opening and onUpgrade execution for v7
        await db.customSelect('SELECT 1').get();
      });

      tearDown(() async {
        await db.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('schemaVersion foi atualizado para 7', () async {
        final versionResult = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(versionResult.read<int>('user_version'), equals(7));
      });

      test(
        'preserva contagem de linhas de todas as tabelas de features',
        () async {
          expect(await db.expenses.count().getSingle(), equals(1));
          expect(await db.purchases.count().getSingle(), equals(1));
          expect(await db.purchaseItems.count().getSingle(), equals(1));
          expect(await db.pricePoints.count().getSingle(), equals(1));
          expect(await db.products.count().getSingle(), equals(2));
          expect(await db.productAliases.count().getSingle(), equals(2));
          expect(await db.categories.count().getSingle(), equals(1));
          expect(await db.budgets.count().getSingle(), equals(1));
          expect(await db.shoppingLists.count().getSingle(), equals(1));
          expect(await db.shoppingItems.count().getSingle(), equals(1));
          expect(await db.tasks.count().getSingle(), equals(1));
          expect(await db.recipes.count().getSingle(), equals(1));
          expect(await db.recipeIngredients.count().getSingle(), equals(1));
          expect(await db.recipeTags.count().getSingle(), equals(1));
          expect(await db.stockItems.count().getSingle(), equals(1));
          expect(await db.checklistItems.count().getSingle(), equals(1));
          expect(await db.bills.count().getSingle(), equals(1));
          expect(await db.billPayments.count().getSingle(), equals(1));

          final task = await db.select(db.tasks).getSingle();
          expect(task.sourcePresetId, equals('sweep-floor'));
        },
      );

      test('preserves monetary sums before and after (006 §4)', () async {
        final exp = await db.select(db.expenses).getSingle();
        expect(exp.amountCents, equals(5000));

        final purch = await db.select(db.purchases).getSingle();
        expect(purch.totalCents, equals(2500));
      });

      test(
        'creates new sync metadata tables (acks, bundles, horizon)',
        () async {
          expect(await db.syncMemberAcks.count().getSingle(), equals(0));
          expect(await db.syncAppliedBundles.count().getSingle(), equals(0));
          expect(await db.syncCompactionHorizon.count().getSingle(), equals(0));
        },
      );

      test(
        'desativa pseudo-membros mantendo os dados preservados (RN-429)',
        () async {
          final members = await db.select(db.syncMembers).get();
          expect(members.length, equals(3));

          final realMember = members.firstWhere((m) => m.siteId == 'site_abc');
          expect(realMember.isActive, isTrue);

          final probeMember = members.firstWhere(
            (m) => m.siteId == 'probed_192.168.1.15',
          );
          expect(probeMember.isActive, isFalse);

          final cachedMember = members.firstWhere(
            (m) => m.siteId == 'cached_peer',
          );
          expect(cachedMember.isActive, isFalse);
        },
      );

      test('search_index FTS5 is created and populated by migration', () async {
        final countResult = await db
            .customSelect('SELECT count(*) AS c FROM search_index')
            .getSingle();
        final totalIndexed = countResult.read<int>('c');
        // 2 produtos + 2 aliases + 1 despesa + 1 tarefa + 1 receita + 1 lista de compras = 8 entradas
        expect(totalIndexed, equals(8));

        // Busca por trigram sem acento em produto e alias
        final searchResult = await db
            .customSelect(
              "SELECT target_id, title FROM search_index WHERE search_index MATCH 'arroz*';",
            )
            .get();
        expect(searchResult, isNotEmpty);
        expect(
          searchResult.any(
            (row) => row.read<String>('title').toLowerCase().contains('arroz'),
          ),
          isTrue,
        );
      });

      test(
        'search_index triggers keep index synchronized with changes',
        () async {
          // Insertion of new product
          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'prod-new-fts',
                  canonicalName: 'Feijão Carioca Nobre',
                  defaultUnit: 'kg',
                ),
              );

          var res = await db
              .customSelect(
                "SELECT target_id FROM search_index WHERE search_index MATCH 'feijao*';",
              )
              .get();
          expect(res, isNotEmpty);
          expect(res.first.read<String>('target_id'), equals('prod-new-fts'));

          // Update
          await (db.update(
            db.products,
          )..where((t) => t.id.equals('prod-new-fts'))).write(
            const ProductsCompanion(
              canonicalName: Value('Feijão Preto Especial'),
            ),
          );

          res = await db
              .customSelect(
                "SELECT target_id FROM search_index WHERE search_index MATCH 'preto*';",
              )
              .get();
          expect(res, isNotEmpty);
          expect(res.first.read<String>('target_id'), equals('prod-new-fts'));

          // Deletion
          await (db.delete(
            db.products,
          )..where((t) => t.id.equals('prod-new-fts'))).go();

          res = await db
              .customSelect(
                "SELECT target_id FROM search_index WHERE search_index MATCH 'preto*';",
              )
              .get();
          expect(res, isEmpty);
        },
      );

      test('performance indexes were created', () async {
        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index';",
            )
            .get();
        final indexNames = indexes
            .map((row) => row.read<String>('name'))
            .toSet();

        expect(indexNames.contains('idx_expenses_category'), isTrue);
        expect(indexNames.contains('idx_bill_payments_bill'), isTrue);
        expect(indexNames.contains('idx_purchase_items_purchase'), isTrue);
        expect(indexNames.contains('idx_recipe_ingredients_recipe'), isTrue);
        expect(indexNames.contains('idx_sync_tombstones_purged'), isTrue);
        expect(indexNames.contains('idx_sync_col_ver_site_hlc'), isTrue);
      });
    },
  );
}
