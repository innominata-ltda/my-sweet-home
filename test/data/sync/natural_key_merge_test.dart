import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/natural_key_merger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const merger = NaturalKeyMerger();

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('CA-5.6 / RN-326 - Product merge by natural identity', () {
    test('Given product Detergente created in A and B before pairing, '
        'when syncing, then one product remains with price history of both (CA-5.6)', () async {
      const timeA = '2026-10-22T10:00:00.000Z';
      const timeB = '2026-10-22T11:00:00.000Z';

      // 1. Loja comum
      await db
          .into(db.stores)
          .insert(
            StoresCompanion.insert(id: 'store-1', name: 'Supermercado Central'),
          );

      // 2. Produto criado em A (mais antigo)
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-a',
              canonicalName: 'Detergente',
              defaultUnit: 'un',
              createdAt: const Value(timeA),
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'alias-a',
              productId: 'prod-a',
              alias: 'Detergente Neutro',
              normalizedAlias: 'detergente neutro',
              source: 'user',
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp-a',
              productId: const Value('prod-a'),
              storeId: const Value('store-1'),
              observedAt: timeA,
              unitPriceCents: 500,
              normalizedPriceCents: 500,
              quantityMilli: 1000,
              unit: 'un',
              source: 'purchase',
            ),
          );

      // 3. Product created in B (newer, canonicalName differs only by case/spaces)
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-b',
              canonicalName: '  detergente  ',
              defaultUnit: 'un',
              createdAt: const Value(timeB),
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'alias-b',
              productId: 'prod-b',
              alias: 'Detergente L\u00EDquido',
              normalizedAlias: 'detergente liquido',
              source: 'user',
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp-b',
              productId: const Value('prod-b'),
              storeId: const Value('store-1'),
              observedAt: timeB,
              unitPriceCents: 450,
              normalizedPriceCents: 450,
              quantityMilli: 1000,
              unit: 'un',
              source: 'purchase',
            ),
          );

      // Before merger: 2 products
      expect(await db.products.count().getSingle(), equals(2));

      // 4. Executes natural identity merge
      final report = await merger.mergeAll(db);
      expect(report.mergedProductsCount, equals(1));

      // 5. Resta exatamente UM produto (o mais antigo, prod-a)
      final remainingProducts = await db.select(db.products).get();
      expect(remainingProducts, hasLength(1));
      final survivor = remainingProducts.first;
      expect(survivor.id, equals('prod-a'));

      // 6. Price history preserves points from A and B pointing to survivor!
      final pricePoints = await db.select(db.pricePoints).get();
      expect(pricePoints, hasLength(2));
      for (final pp in pricePoints) {
        expect(pp.productId, equals('prod-a'));
      }

      // 7. Apelidos de ambos foram preservados apontando para o sobrevivente
      final aliases = await db.select(db.productAliases).get();
      expect(aliases, hasLength(2));
      for (final a in aliases) {
        expect(a.productId, equals('prod-a'));
      }
    });

    test(
      'deduplicates identical aliases without violating unique constraint',
      () async {
        const now = '2026-10-22T10:00:00.000Z';

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-1',
                canonicalName: 'Sab\u00E3o em P\u00F3',
                defaultUnit: 'kg',
                createdAt: const Value(now),
              ),
            );

        await db
            .into(db.productAliases)
            .insert(
              ProductAliasesCompanion.insert(
                id: 'al-1',
                productId: 'prod-1',
                alias: 'Sab\u00E3o',
                normalizedAlias: 'sabao',
                source: 'user',
              ),
            );

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-2',
                canonicalName: 'sabao em po',
                defaultUnit: 'kg',
                createdAt: const Value('2026-10-22T11:00:00.000Z'),
              ),
            );

        // Product 2 has same exact alias "Sabao"
        await db
            .into(db.productAliases)
            .insert(
              ProductAliasesCompanion.insert(
                id: 'al-2',
                productId: 'prod-2',
                alias: 'Sab\u00E3o',
                normalizedAlias: 'sabao',
                source: 'user',
              ),
            );

        final report = await merger.mergeAll(db);
        expect(report.mergedProductsCount, equals(1));

        final aliases = await db.select(db.productAliases).get();
        expect(aliases, hasLength(1));
        expect(aliases.first.productId, equals('prod-1'));
        expect(aliases.first.normalizedAlias, equals('sabao'));
      },
    );

    test('preserves purchase_items, shopping_items, and recipe_ingredients on merge', () async {
      const time1 = '2026-10-22T10:00:00.000Z';
      const time2 = '2026-10-22T11:00:00.000Z';

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p-winner',
              canonicalName: '\u00D3leo de Soja',
              defaultUnit: 'l',
              createdAt: const Value(time1),
            ),
          );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p-loser',
              canonicalName: 'Oleo de Soja',
              defaultUnit: 'l',
              createdAt: const Value(time2),
            ),
          );

      // Purchase with item pointing to p-loser
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'purch-1',
              purchasedAt: time2,
              totalCents: 800,
              source: 'manual',
            ),
          );

      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-loser',
              purchaseId: 'purch-1',
              productId: const Value('p-loser'),
              rawDescription: 'Oleo Soja 900ml',
              quantityMilli: 900,
              unit: 'ml',
              unitPriceCents: 800,
              totalPriceCents: 800,
              position: 1,
            ),
          );

      // Shopping list item pointing to p-loser
      await db
          .into(db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              id: 'list-1',
              name: 'Compras da Semana',
            ),
          );

      await db
          .into(db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              id: 'si-loser',
              productId: const Value('p-loser'),
              source: 'manual',
              position: 1,
            ),
          );

      // Recipe pointing to p-loser
      await db
          .into(db.recipes)
          .insert(RecipesCompanion.insert(id: 'rec-1', title: 'Batata Frita'));

      await db
          .into(db.recipeIngredients)
          .insert(
            RecipeIngredientsCompanion.insert(
              id: 'ri-loser',
              recipeId: const Value('rec-1'),
              productId: const Value('p-loser'),
              rawText: '\u00D3leo para fritar',
              position: 1,
            ),
          );

      await merger.mergeAll(db);

      // All children remapped to p-winner
      final pi = await db.select(db.purchaseItems).getSingle();
      expect(pi.productId, equals('p-winner'));

      final si = await db.select(db.shoppingItems).getSingle();
      expect(si.productId, equals('p-winner'));

      final ri = await db.select(db.recipeIngredients).getSingle();
      expect(ri.productId, equals('p-winner'));
    });
  });

  group('RN-326 — Deterministic establishment merge by CNPJ', () {
    test('same normalized CNPJ merges stores and remaps purchases', () async {
      const time1 = '2026-10-22T08:00:00.000Z';
      const time2 = '2026-10-22T09:00:00.000Z';

      await db
          .into(db.stores)
          .insert(
            StoresCompanion.insert(
              id: 'store-a',
              name: 'Supermercado Silva (Matriz)',
              cnpj: const Value('12.345.678/0001-99'),
              createdAt: const Value(time1),
            ),
          );

      await db
          .into(db.stores)
          .insert(
            StoresCompanion.insert(
              id: 'store-b',
              name: 'Supermercado Silva Filial',
              cnpj: const Value('12345678000199'),
              createdAt: const Value(time2),
            ),
          );

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'purch-store-b',
              storeId: const Value('store-b'),
              purchasedAt: time2,
              totalCents: 1500,
              source: 'manual',
            ),
          );

      final report = await merger.mergeAll(db);
      expect(report.mergedStoresCount, equals(1));

      final stores = await db.select(db.stores).get();
      expect(stores, hasLength(1));
      expect(stores.first.id, equals('store-a'));

      final purch = await db.select(db.purchases).getSingle();
      expect(purch.storeId, equals('store-a'));
    });
  });

  group('INV-6 / RN-326 — Ambiguous alias pointing to distinct products becomes prompt', () {
    test('alias pointing to two distinct products generates PendingAliasConflict without breaking sync', () async {
      // Two distinct products
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-veja-multi',
              canonicalName: 'Veja Multiuso',
              defaultUnit: 'un',
            ),
          );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-veja-desengord',
              canonicalName: 'Veja Desengordurante',
              defaultUnit: 'un',
            ),
          );

      // Alias "veja" on both
      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'al-multi',
              productId: 'prod-veja-multi',
              alias: 'Veja',
              normalizedAlias: 'veja',
              source: 'user',
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'al-desengord',
              productId: 'prod-veja-desengord',
              alias: 'Veja',
              normalizedAlias: 'veja',
              source: 'user',
            ),
          );

      final report = await merger.mergeAll(db);

      // Products do not merge because they have different canonical_name
      expect(report.mergedProductsCount, equals(0));

      // Conflict detected
      expect(report.pendingAliasConflicts, hasLength(1));
      final conflict = report.pendingAliasConflicts.first;
      expect(conflict.normalizedAlias, equals('veja'));
      expect(conflict.candidateProductIds, contains('prod-veja-multi'));
      expect(conflict.candidateProductIds, contains('prod-veja-desengord'));

      // Conflict can be read from settings
      final pending = await merger.getPendingAliasConflicts(db);
      expect(pending, hasLength(1));

      // Resolution by user: chooses prod-veja-multi
      await merger.resolveAliasConflict(
        db,
        normalizedAlias: 'veja',
        chosenProductId: 'prod-veja-multi',
      );

      // Now only one alias with 'veja' remains
      final remainingAliases = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.normalizedAlias.equals('veja'))).get();
      expect(remainingAliases, hasLength(1));
      expect(remainingAliases.first.productId, equals('prod-veja-multi'));

      // Pending items list was emptied
      expect(await merger.getPendingAliasConflicts(db), isEmpty);
    });
  });

  group('Integration with BatchApplier (CA-5.6 via sync)', () {
    test('BatchApplier executes automatic product merge after applying remote batch', () async {
      const timeLocal = '2026-10-22T08:00:00.000Z';
      const timeRemote = '2026-10-22T09:00:00.000Z';

      // 1. Local product in A with price point
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-local-det',
              canonicalName: 'Detergente Neutro Yp\u00EA',
              defaultUnit: 'un',
              createdAt: const Value(timeLocal),
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp-local',
              productId: const Value('prod-local-det'),
              observedAt: timeLocal,
              unitPriceCents: 299,
              normalizedPriceCents: 299,
              quantityMilli: 500,
              unit: 'ml',
              source: 'manual',
            ),
          );

      // 2. Batch received from B containing store, purchase, item and product "detergente neutro ype"
      final applier = DriftBatchApplier(db: db);

      final hlc1 = Hlc.parse('2026-10-22T09:00:00.000Z:00001:device-b');
      final hlc2 = Hlc.parse('2026-10-22T09:00:00.000Z:00002:device-b');

      final batch = SyncBatch(
        householdId: 'hh-1',
        fromSiteId: 'device-b',
        senderVector: VersionVector({'device-b': hlc2}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-remote-det',
            column: 'canonical_name',
            value: 'detergente neutro ype',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-remote-det',
            column: 'default_unit',
            value: 'un',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'stores',
            rowId: 'store-b',
            column: 'name',
            value: 'Mercado Remoto',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'purchases',
            rowId: 'purch-b',
            column: 'store_id',
            value: 'store-b',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'purchases',
            rowId: 'purch-b',
            column: 'purchased_at',
            value: timeRemote,
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'purchases',
            rowId: 'purch-b',
            column: 'total_cents',
            value: 279,
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'purchases',
            rowId: 'purch-b',
            column: 'source',
            value: 'manual',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'purchase_id',
            value: 'purch-b',
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'product_id',
            value: 'prod-remote-det',
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'raw_description',
            value: 'Det Neutro Ype 500ml',
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'quantity_milli',
            value: 500,
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'unit',
            value: 'ml',
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'unit_price_cents',
            value: 279,
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'total_price_cents',
            value: 279,
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'purchase_items',
            rowId: 'pi-b',
            column: 'position',
            value: 1,
            hlc: hlc2,
          ),
        ],
      );

      final result = await applier.apply(batch);
      if (result.isErr) {
        fail('Apply batch failed with: $result');
      }
      expect(result.isOk, isTrue);

      // 3. Result after sync and merge:
      // Only 1 product remains (local prod-local-det)
      final prods = await db.select(db.products).get();
      expect(prods, hasLength(1));
      expect(prods.first.id, equals('prod-local-det'));

      // Remote purchase item now points to prod-local-det
      final purchaseItem = await db.select(db.purchaseItems).getSingle();
      expect(purchaseItem.productId, equals('prod-local-det'));
    });
  });
}
