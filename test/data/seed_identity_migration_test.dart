import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/seed_loader.dart';

import '../fakes/fake_clock.dart';
import '../fakes/sequential_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idGen = UuidV5DeterministicIdGenerator();
  final clock = FakeClock(DateTime.utc(2026, 10, 22, 10, 0));
  const nowIso = '2026-10-22T10:00:00.000Z';

  group('SeedIdentityMigration (T-P01, RF-124, CA-5.5)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('remapeia banco populado preservando todos os vinculos e historicos de preco', () async {
      // 1. Inserir produto seed com ID aleatorio (legado / v7)
      const oldSeedProductId = 'old-seed-prod-001';
      const oldSeedAliasId = 'old-seed-alias-001';
      const canonicalName = 'Arroz Branco Agulhinha';
      final normCanonical = normalizeProductName(canonicalName);
      final expectedDeterministicProdId = idGen.forSeed(
        'product',
        normCanonical,
      );
      final expectedDeterministicAliasId = idGen.forSeed(
        'product_alias',
        '$expectedDeterministicProdId:$normCanonical',
      );

      // Insert non-seed user product to ensure it is not modified
      const userProductId = 'custom-user-product-uuid';
      const userAliasId = 'custom-user-alias-uuid';

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: oldSeedProductId,
              canonicalName: canonicalName,
              defaultUnit: 'kg',
              createdAt: const Value(nowIso),
              updatedAt: const Value(nowIso),
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: oldSeedAliasId,
              productId: oldSeedProductId,
              alias: canonicalName,
              normalizedAlias: normCanonical,
              source: 'seed',
              createdAt: const Value(nowIso),
            ),
          );

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: userProductId,
              canonicalName: 'Meu Produto Artesanal',
              defaultUnit: 'un',
              createdAt: const Value(nowIso),
              updatedAt: const Value(nowIso),
            ),
          );

      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: userAliasId,
              productId: userProductId,
              alias: 'Meu Produto Artesanal',
              normalizedAlias: 'meu produto artesanal',
              source: 'user',
              createdAt: const Value(nowIso),
            ),
          );

      // Inserir entidades relacionadas que apontam para oldSeedProductId:
      // a) Loja e Compra para purchase_items e price_points
      await db
          .into(db.stores)
          .insert(
            StoresCompanion.insert(id: 'store-1', name: 'Supermercado Central'),
          );
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'purchase-1',
              purchasedAt: nowIso,
              totalCents: 5000,
              source: 'manual',
            ),
          );

      // b) PurchaseItems (aponta para produto seed e compra)
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'p-item-1',
              purchaseId: 'purchase-1',
              productId: const Value(oldSeedProductId),
              rawDescription: canonicalName,
              quantityMilli: 1000,
              unit: 'kg',
              unitPriceCents: 500,
              totalPriceCents: 500,
              position: 1,
            ),
          );

      // c) PricePoints (historico de preco para produto seed)
      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'price-pt-1',
              productId: const Value(oldSeedProductId),
              storeId: const Value('store-1'),
              observedAt: nowIso,
              unitPriceCents: 500,
              normalizedPriceCents: 500,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );

      // d) ShoppingList e ShoppingItems
      await db
          .into(db.shoppingLists)
          .insert(ShoppingListsCompanion.insert(id: 'list-1', name: 'Feira'));
      await db
          .into(db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              id: 'shop-item-1',
              listId: const Value('list-1'),
              productId: const Value(oldSeedProductId),
              source: 'manual',
              position: 1,
            ),
          );

      // e) Recipes e RecipeIngredients
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(id: 'recipe-1', title: 'Arroz Simples'),
          );
      await db
          .into(db.recipeIngredients)
          .insert(
            RecipeIngredientsCompanion.insert(
              id: 'rec-ing-1',
              recipeId: const Value('recipe-1'),
              productId: const Value(oldSeedProductId),
              rawText: '1 xicara de arroz',
              position: 1,
            ),
          );

      // f) StockItems
      await db
          .into(db.stockItems)
          .insert(
            StockItemsCompanion.insert(
              id: 'stock-1',
              productId: oldSeedProductId,
            ),
          );

      // g) ProductDenials
      await db
          .into(db.productDenials)
          .insert(
            ProductDenialsCompanion.insert(
              id: 'denial-1',
              productId: oldSeedProductId,
              rawText: 'Arroz Ruim',
              normalizedText: 'arroz ruim',
            ),
          );

      // 2. Executar a migracao
      final migration = SeedIdentityMigration(db, deterministicIdGen: idGen);
      final count = await migration.remap();
      expect(count, equals(1));

      // 3. Validar se produto seed foi remapeado para UUID v5 deterministico
      final remappedProd = await (db.select(
        db.products,
      )..where((tbl) => tbl.canonicalName.equals(canonicalName))).getSingle();
      expect(remappedProd.id, equals(expectedDeterministicProdId));

      // 4. Validar se alias seed foi remapeado
      final remappedAlias = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.alias.equals(canonicalName))).getSingle();
      expect(remappedAlias.id, equals(expectedDeterministicAliasId));
      expect(remappedAlias.productId, equals(expectedDeterministicProdId));

      // 5. Validate that user product and alias were not touched
      final userProd = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(userProductId))).getSingle();
      expect(userProd.canonicalName, equals('Meu Produto Artesanal'));

      final userAlias = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.id.equals(userAliasId))).getSingle();
      expect(userAlias.productId, equals(userProductId));

      // 6. Validar que todas as FKs apontam para o novo ID deterministico
      final purchaseItem = await (db.select(
        db.purchaseItems,
      )..where((tbl) => tbl.id.equals('p-item-1'))).getSingle();
      expect(purchaseItem.productId, equals(expectedDeterministicProdId));

      final pricePoint = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.id.equals('price-pt-1'))).getSingle();
      expect(pricePoint.productId, equals(expectedDeterministicProdId));

      // Historico de precos por produto permanece perfeitamente intacto
      final priceHistory =
          await (db.select(db.pricePoints)..where(
                (tbl) => tbl.productId.equals(expectedDeterministicProdId),
              ))
              .get();
      expect(priceHistory.length, equals(1));
      expect(priceHistory.first.unitPriceCents, equals(500));

      final shoppingItem = await (db.select(
        db.shoppingItems,
      )..where((tbl) => tbl.id.equals('shop-item-1'))).getSingle();
      expect(shoppingItem.productId, equals(expectedDeterministicProdId));

      final recipeIngredient = await (db.select(
        db.recipeIngredients,
      )..where((tbl) => tbl.id.equals('rec-ing-1'))).getSingle();
      expect(recipeIngredient.productId, equals(expectedDeterministicProdId));

      final stockItem = await (db.select(
        db.stockItems,
      )..where((tbl) => tbl.id.equals('stock-1'))).getSingle();
      expect(stockItem.productId, equals(expectedDeterministicProdId));

      final denial = await (db.select(
        db.productDenials,
      )..where((tbl) => tbl.id.equals('denial-1'))).getSingle();
      expect(denial.productId, equals(expectedDeterministicProdId));

      // 7. Idempotencia: rodar novamente retorna 0 e nada muda
      final secondRun = await migration.remap();
      expect(secondRun, equals(0));
    });

    test('lida com produto deterministico pre-existente sem falhar por UNIQUE constraint', () async {
      const canonicalName = 'Feijão Preto';
      final normCanonical = normalizeProductName(canonicalName);
      final deterministicProdId = idGen.forSeed('product', normCanonical);

      // Product already with deterministic ID
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: deterministicProdId,
              canonicalName: canonicalName,
              defaultUnit: 'kg',
            ),
          );

      // Produto legado que normaliza para o mesmo nome
      const legacyId = 'legacy-feijao';
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: legacyId,
              canonicalName: canonicalName,
              defaultUnit: 'kg',
            ),
          );
      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'alias-legacy',
              productId: legacyId,
              alias: canonicalName,
              normalizedAlias: normCanonical,
              source: 'seed',
            ),
          );

      // Item apontando para o produto legado
      await db
          .into(db.stockItems)
          .insert(
            StockItemsCompanion.insert(id: 'stock-feijao', productId: legacyId),
          );

      final migration = SeedIdentityMigration(db, deterministicIdGen: idGen);
      await migration.remap();

      final stock = await (db.select(
        db.stockItems,
      )..where((t) => t.id.equals('stock-feijao'))).getSingle();
      expect(stock.productId, equals(deterministicProdId));
    });

    test('duas instalacoes carregadas com SeedLoader geram os mesmos IDs deterministicos (CA-5.5)', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        final key = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (key == 'assets/seed/synonyms.json') {
          final bytes = File('assets/seed/synonyms.json').readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      });

      final dbA = AppDatabase.memory();
      final dbB = AppDatabase.memory();

      try {
        final loaderA = SeedLoader(
          dbA,
          SequentialIdGenerator(prefix: 'a'),
          clock,
        );
        final loaderB = SeedLoader(
          dbB,
          SequentialIdGenerator(prefix: 'b'),
          clock,
        );

        await loaderA.loadIfNeeded();
        await loaderB.loadIfNeeded();

        final prodsA = await (dbA.select(
          dbA.products,
        )..orderBy([(tbl) => OrderingTerm.asc(tbl.canonicalName)])).get();
        final prodsB = await (dbB.select(
          dbB.products,
        )..orderBy([(tbl) => OrderingTerm.asc(tbl.canonicalName)])).get();

        expect(prodsA.length, equals(prodsB.length));
        expect(prodsA.length, greaterThanOrEqualTo(120));

        for (var i = 0; i < prodsA.length; i++) {
          expect(
            prodsA[i].id,
            equals(prodsB[i].id),
            reason:
                'Produto ${prodsA[i].canonicalName} deve ter o mesmo ID em A e B',
          );
        }

        final aliasesA = await (dbA.select(
          dbA.productAliases,
        )..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])).get();
        final aliasesB = await (dbB.select(
          dbB.productAliases,
        )..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])).get();

        expect(aliasesA.length, equals(aliasesB.length));
        for (var i = 0; i < aliasesA.length; i++) {
          expect(aliasesA[i].id, equals(aliasesB[i].id));
          expect(aliasesA[i].productId, equals(aliasesB[i].productId));
        }

        // Migration on already deterministic database returns 0
        final migrationA = SeedIdentityMigration(
          dbA,
          deterministicIdGen: idGen,
        );
        expect(await migrationA.remap(), equals(0));
      } finally {
        messenger.setMockMessageHandler('flutter/assets', null);
        await dbA.close();
        await dbB.close();
      }
    });
  });
}
