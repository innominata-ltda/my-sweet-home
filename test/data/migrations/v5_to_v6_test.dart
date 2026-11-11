import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idGen = UuidV5DeterministicIdGenerator();

  group('Migration v5 to v6 — SPEC-013 (T-I01, RF-124, RNF-008, 006 §4)', () {
    late Directory tempDir;
    late File dbFile;
    late AppDatabase db;

    setUp(() async {
      final fixtureFile = File('test/fixtures/db/v5.sqlite');
      expect(
        fixtureFile.existsSync(),
        isTrue,
        reason: 'Execute dart run scripts/generate_fixture_v5.dart antes',
      );

      tempDir = Directory.systemTemp.createTempSync('drift_migration_v6_test');
      dbFile = File('${tempDir.path}/app_v6.db');
      fixtureFile.copySync(dbFile.path);

      db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));
      // Forces opening and onUpgrade execution for v6
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
      tempDir.deleteSync(recursive: true);
    });

    test('schemaVersion foi atualizado para 6 ou superior', () async {
      final versionResult = await db
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(versionResult.read<int>('user_version'), greaterThanOrEqualTo(6));
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

      final bgt = await db.select(db.budgets).getSingle();
      expect(bgt.limitCents, equals(100000));

      final bill = await db.select(db.bills).getSingle();
      expect(bill.amountCents, equals(12000));

      final pay = await db.select(db.billPayments).getSingle();
      expect(pay.amountCents, equals(12000));
    });

    test('executes SeedIdentityMigration and remaps seed products/aliases to deterministic UUID v5', () async {
      const canonicalName = 'Arroz Branco Agulhinha';
      final normCanonical = normalizeProductName(canonicalName);
      final expectedProdId = idGen.forSeed('product', normCanonical);
      final expectedAliasId = idGen.forSeed(
        'product_alias',
        '$expectedProdId:$normCanonical',
      );

      // 1. Produto seed remapeado
      final remappedProd = await (db.select(
        db.products,
      )..where((tbl) => tbl.canonicalName.equals(canonicalName))).getSingle();
      expect(remappedProd.id, equals(expectedProdId));

      // 2. Alias seed remapeado
      final remappedAlias = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.alias.equals(canonicalName))).getSingle();
      expect(remappedAlias.id, equals(expectedAliasId));
      expect(remappedAlias.productId, equals(expectedProdId));

      // 3. User product was not modified
      final userProd =
          await (db.select(db.products)..where(
                (tbl) => tbl.canonicalName.equals('Café Especial do Sul'),
              ))
              .getSingle();
      expect(userProd.id, equals('custom-user-prod-001'));

      // 4. FKs in purchases, items, price history, lists, recipes, and stock point to new ID
      final purchaseItem = await db.select(db.purchaseItems).getSingle();
      expect(purchaseItem.productId, equals(expectedProdId));

      final pricePoint = await db.select(db.pricePoints).getSingle();
      expect(pricePoint.productId, equals(expectedProdId));

      final shoppingItem = await db.select(db.shoppingItems).getSingle();
      expect(shoppingItem.productId, equals(expectedProdId));

      final recipeIngredient = await db
          .select(db.recipeIngredients)
          .getSingle();
      expect(recipeIngredient.productId, equals(expectedProdId));

      final stockItem = await db.select(db.stockItems).getSingle();
      expect(stockItem.productId, equals(expectedProdId));
    });

    test('tabelas sync_* foram criadas vazias', () async {
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toSet();

      expect(tableNames, contains('sync_household'));
      expect(tableNames, contains('sync_members'));
      expect(tableNames, contains('sync_column_versions'));
      expect(tableNames, contains('sync_row_tombstones'));
      expect(tableNames, contains('sync_peer_vectors'));

      expect(await db.syncHouseholds.count().getSingle(), equals(0));
      expect(await db.syncMembers.count().getSingle(), equals(0));
      expect(await db.syncColumnVersions.count().getSingle(), equals(0));
      expect(await db.syncRowTombstones.count().getSingle(), equals(0));
      expect(await db.syncPeerVectors.count().getSingle(), equals(0));
    });

    test('sync triggers are installed and disabled by default', () async {
      // 1. Inserir produto com sync_household vazio
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'new-product-without-household',
              canonicalName: 'Feij\u00E3o Preto',
              defaultUnit: 'kg',
            ),
          );

      // sync_column_versions must continue with 0 records (triggers disabled by default)
      final count = await db.syncColumnVersions.count().getSingle();
      expect(count, equals(0));
    });

    test('triggers write versions to sync_column_versions when household is active', () async {
      const now = '2026-10-22T14:00:00.000Z';
      const householdId = 'hh-1234-uuid';
      const localSiteId = 'device-phone-a';

      // 1. Ativa a casa
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa da Duda',
              localSiteId: localSiteId,
              sharedAreas: 'catalog,home,finance',
              createdAt: now,
              joinedAt: now,
              active: const Value(true),
            ),
          );

      // 2. Insere um novo produto
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-with-active-sync',
              canonicalName: 'Açúcar Cristal',
              defaultUnit: 'kg',
            ),
          );

      // 3. Triggers recorded versions of monitored columns!
      final versions = await db.select(db.syncColumnVersions).get();
      expect(versions, isNotEmpty);
      expect(
        versions.any(
          (v) =>
              v.rowId == 'prod-with-active-sync' &&
              v.columnName == 'canonical_name',
        ),
        isTrue,
      );
      expect(versions.first.siteId, equals(localSiteId));
    });

    test('triggers produce no echo when sync_applying_remote = 1', () async {
      const now = '2026-10-22T14:00:00.000Z';
      const householdId = 'hh-1234-uuid';
      const localSiteId = 'device-phone-a';

      // 1. Ativa a casa
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa da Duda',
              localSiteId: localSiteId,
              sharedAreas: 'catalog,home,finance',
              createdAt: now,
              joinedAt: now,
              active: const Value(true),
            ),
          );

      // 2. Activates remote applying flag
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'sync_applying_remote', value: '1'),
          );

      final beforeCount = await db.syncColumnVersions.count().getSingle();

      // 3. Inserts product simulating remote batch application
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'remote-incoming-prod',
              canonicalName: 'Sal Refinado Remoto',
              defaultUnit: 'kg',
            ),
          );

      // 4. No local version was generated (no echo!)
      final afterCount = await db.syncColumnVersions.count().getSingle();
      expect(afterCount, equals(beforeCount));
    });

    test('triggers write versions to sync_column_versions on UPDATE only for modified columns', () async {
      const now = '2026-10-22T14:00:00.000Z';
      const householdId = 'hh-1234-uuid';
      const localSiteId = 'device-phone-a';

      // 1. Ativa a casa
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa da Duda',
              localSiteId: localSiteId,
              sharedAreas: 'catalog,home,finance',
              createdAt: now,
              joinedAt: now,
              active: const Value(true),
            ),
          );

      // 2. Insere produto inicial
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-to-update',
              canonicalName: 'Farinha de Trigo',
              defaultUnit: 'kg',
            ),
          );

      final initialVersions = await (db.select(
        db.syncColumnVersions,
      )..where((tbl) => tbl.rowId.equals('prod-to-update'))).get();
      final initialUnit = initialVersions.firstWhere(
        (v) => v.columnName == 'default_unit',
      );

      // 3. Updates only canonical_name with later explicit HLC
      const customHlc = '2026-10-22T15:00:00.000Z:00001:device-phone-a';
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'sync_current_hlc', value: customHlc),
          );

      await (db.update(
        db.products,
      )..where((tbl) => tbl.id.equals('prod-to-update'))).write(
        const ProductsCompanion(
          canonicalName: Value('Farinha de Trigo Integral'),
        ),
      );

      // 4. Verify canonical_name was updated with customHlc
      final updatedVersions = await (db.select(
        db.syncColumnVersions,
      )..where((tbl) => tbl.rowId.equals('prod-to-update'))).get();
      final updatedCanonical = updatedVersions.firstWhere(
        (v) => v.columnName == 'canonical_name',
      );
      final updatedUnit = updatedVersions.firstWhere(
        (v) => v.columnName == 'default_unit',
      );

      expect(updatedCanonical.hlc, equals(customHlc));
      // default_unit DID NOT change on update, so initial hlc is preserved!
      expect(updatedUnit.hlc, equals(initialUnit.hlc));
    });

    test('triggers write tombstones to sync_row_tombstones on DELETE with valid HLC', () async {
      const now = '2026-10-22T14:00:00.000Z';
      const householdId = 'hh-1234-uuid';
      const localSiteId = 'device-phone-a';

      // 1. Ativa a casa
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa da Duda',
              localSiteId: localSiteId,
              sharedAreas: 'catalog,home,finance',
              createdAt: now,
              joinedAt: now,
              active: const Value(true),
            ),
          );

      // 2. Insere e deleta um item
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-to-delete',
              canonicalName: 'Biscoito Recheado',
              defaultUnit: 'un',
            ),
          );

      await (db.delete(
        db.products,
      )..where((tbl) => tbl.id.equals('prod-to-delete'))).go();

      // 3. Verifica registro em sync_row_tombstones
      final tombstones =
          await (db.select(db.syncRowTombstones)..where(
                (tbl) =>
                    tbl.tableNameCol.equals('products') &
                    tbl.rowId.equals('prod-to-delete'),
              ))
              .get();

      expect(tombstones, hasLength(1));
      final t = tombstones.first;
      expect(t.rowId, equals('prod-to-delete'));
      expect(t.tableNameCol, equals('products'));

      final parsedHlc = Hlc.parse(t.hlc);
      expect(parsedHlc.siteId, equals(localSiteId));
      expect(parsedHlc.millis, greaterThan(0));
    });

    test('triggers permanecem inativos se sync_household.active = 0', () async {
      const now = '2026-10-22T14:00:00.000Z';

      // Casa cadastrada, mas active = false
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: 'inactive-hh',
              name: 'Casa Inativa',
              localSiteId: 'device-phone-a',
              sharedAreas: 'catalog,home',
              createdAt: now,
              joinedAt: now,
              active: const Value(false),
            ),
          );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-inactive-sync',
              canonicalName: 'Óleo de Soja',
              defaultUnit: 'l',
            ),
          );

      expect(await db.syncColumnVersions.count().getSingle(), equals(0));
    });

    test('triggers suportam recipe_tags com chave composta recipe_id:tag no INSERT e DELETE', () async {
      const now = '2026-10-22T14:00:00.000Z';
      const householdId = 'hh-1234-uuid';
      const localSiteId = 'device-phone-a';

      // 1. Ativa a casa
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa da Duda',
              localSiteId: localSiteId,
              sharedAreas: 'catalog,home,finance',
              createdAt: now,
              joinedAt: now,
              active: const Value(true),
            ),
          );

      // 2. Insere receita e tag
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(
              id: 'rec-bolo-01',
              title: 'Bolo de Cenoura',
            ),
          );

      await db
          .into(db.recipeTags)
          .insert(
            RecipeTagsCompanion.insert(
              recipeId: 'rec-bolo-01',
              tag: 'sobremesa',
            ),
          );

      // 3. Verifies recipe_tags versions with composite rowId
      final tagVersions =
          await (db.select(db.syncColumnVersions)..where(
                (tbl) =>
                    tbl.tableNameCol.equals('recipe_tags') &
                    tbl.rowId.equals('rec-bolo-01:sobremesa'),
              ))
              .get();
      expect(tagVersions, isNotEmpty);
      expect(tagVersions.first.rowId, equals('rec-bolo-01:sobremesa'));

      // 4. Delete tag and verify tombstone with composite rowId
      await (db.delete(db.recipeTags)..where(
            (tbl) =>
                tbl.recipeId.equals('rec-bolo-01') &
                tbl.tag.equals('sobremesa'),
          ))
          .go();

      final tombstones =
          await (db.select(db.syncRowTombstones)..where(
                (tbl) =>
                    tbl.tableNameCol.equals('recipe_tags') &
                    tbl.rowId.equals('rec-bolo-01:sobremesa'),
              ))
              .get();
      expect(tombstones, hasLength(1));
      expect(tombstones.first.rowId, equals('rec-bolo-01:sobremesa'));
    });
  });
}
