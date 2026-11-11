import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/sequential_id_generator.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator idGen;
  late ProductDao dao;

  setUp(() async {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 9, 23, 10, 0));
    idGen = SequentialIdGenerator();
    dao = ProductDao(db, idGen, clock);

    // Provide dependencies (category)
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-001',
            name: 'Comida',
            kind: 'product',
            iconKey: 'food',
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-002',
            name: 'Limpeza',
            kind: 'product',
            iconKey: 'cleaning',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductDao.create', () {
    test('creates product and base alias successfully', () async {
      final newProduct = NewProduct(
        canonicalName: 'Pão Francês',
        categoryId: 'cat-001',
        defaultUnit: Unit.kg,
        packageSizeMilli: null,
      );

      final result = await dao.create(newProduct);

      expect(result.isOk, isTrue);

      final product = result.valueOrNull!;
      expect(product.id, 'id-001');
      expect(product.canonicalName, 'Pão Francês');
      expect(product.categoryId, 'cat-001');
      expect(product.defaultUnit, Unit.kg);

      // Verifica no banco
      final dbProducts = await db.select(db.products).get();
      expect(dbProducts, hasLength(1));
      expect(dbProducts.first.canonicalName, 'Pão Francês');

      // Verifica o alias gerado automaticamente (RN-023)
      final aliases = await db.select(db.productAliases).get();
      expect(aliases, hasLength(1));
      expect(aliases.first.productId, 'id-001');
      expect(aliases.first.alias, 'Pão Francês');
      expect(aliases.first.normalizedAlias, 'pao frances');
      expect(aliases.first.source, 'user');
    });

    test('rejects creation if name is empty after normalization', () async {
      final newProduct = NewProduct(
        canonicalName: '   ',
        categoryId: 'cat-001',
        defaultUnit: Unit.un,
      );

      final result = await dao.create(newProduct);

      expect(result.isErr, isTrue);
      final failure = result.failureOrNull as ValidationFailure;
      expect(
        failure.fields,
        containsPair('canonicalName', 'Nome não pode ser vazio.'),
      );

      final dbProducts = await db.select(db.products).get();
      expect(dbProducts, isEmpty);
    });

    test(
      'rejeita criação se já existir produto com mesmo nome normalizado',
      () async {
        final first = NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-001',
          defaultUnit: Unit.kg,
        );
        await dao.create(first);

        final second = NewProduct(
          canonicalName: 'pão francês',
          categoryId: 'cat-002',
          defaultUnit: Unit.un,
        );
        final result = await dao.create(second);

        expect(result.isErr, isTrue);
        final failure = result.failureOrNull as ValidationFailure;
        expect(
          failure.fields,
          containsPair('canonicalName', 'Produto já existe com este nome.'),
        );

        final dbProducts = await db.select(db.products).get();
        expect(dbProducts, hasLength(1));
      },
    );
  });

  group('ProductDao.registerDenial & buildIndex', () {
    test(
      'registerDenial saves denial idempotently and buildIndex includes it',
      () async {
        // 1. Cria produto
        final newProduct = NewProduct(
          canonicalName: 'Mandioca',
          categoryId: 'cat-001',
          defaultUnit: Unit.kg,
        );
        final productResult = await dao.create(newProduct);
        final productId = productResult.valueOrNull!.id;

        // 2. Register denial twice
        final r1 = await dao.registerDenial(productId, 'Macaxeira');
        expect(r1.isOk, isTrue);

        final r2 = await dao.registerDenial(
          productId,
          'macaxeira',
        ); // mesmo normalizado
        expect(r2.isOk, isTrue);

        // 3. Verifica no banco
        final dbDenials = await db.select(db.productDenials).get();
        expect(dbDenials, hasLength(1));
        expect(dbDenials.first.productId, productId);
        expect(dbDenials.first.rawText, 'Macaxeira');
        expect(dbDenials.first.normalizedText, 'macaxeira');

        // 4. Build index and verify
        final indexResult = await dao.buildIndex();
        expect(indexResult.isOk, isTrue);

        final index = indexResult.valueOrNull!;
        expect(index.products.map((p) => p.id), contains(productId));
        expect(
          index.aliases.map((a) => a.productId),
          contains(productId),
        ); // canonical alias generated
        expect(index.denials, hasLength(1));
        expect(index.denials.first.productId, productId);
        expect(index.denials.first.rawText, 'Macaxeira');
      },
    );

    test('registerDenial rejeita se texto vazio', () async {
      final r = await dao.registerDenial('id-123', '   ');
      expect(r.isErr, isTrue);
      expect(
        (r.failureOrNull as ValidationFailure).fields.keys,
        contains('rawText'),
      );
    });
  });

  group('ProductDao.search', () {
    test('encontra produtos por nome e verifica UTC da data', () async {
      await dao.create(
        NewProduct(
          canonicalName: 'Café',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      );

      final result = await dao.search('cafe');
      expect(result.isOk, isTrue);

      final products = result.valueOrNull!;
      expect(products, hasLength(1));
      final product = products.first;
      expect(product.canonicalName, 'Café');
      expect(product.createdAt.isUtc, isTrue);
      expect(product.updatedAt.isUtc, isTrue);
    });
  });

  group('ProductDao.merge', () {
    test('mescla dois produtos movendo referencias', () async {
      await dao.create(
        NewProduct(
          canonicalName: 'Leite A',
          categoryId: 'cat-001',
          defaultUnit: Unit.l,
        ),
      );
      await dao.create(
        NewProduct(
          canonicalName: 'Leite B',
          categoryId: 'cat-001',
          defaultUnit: Unit.l,
        ),
      );

      final pA = (await dao.search('leite a')).valueOrNull!.first;
      final pB = (await dao.search('leite b')).valueOrNull!.first;

      final mergeRes = await dao.merge(from: pA.id, into: pB.id);
      expect(mergeRes.isOk, isTrue);

      final searchAfter = await dao.search('leite a');
      expect(searchAfter.valueOrNull!.first.id, pB.id);

      final undoRes = await dao.undoMerge(mergeRes.valueOrNull!.id);
      expect(undoRes.isOk, isTrue);

      // Como pA volta a ficar ativo, a busca por "leite a" deve retornar pA
      final searchABack = await dao.search('leite a');
      expect(searchABack.valueOrNull!.any((p) => p.id == pA.id), isTrue);
    });
  });

  group('ProductDao.hasHistory, archive e delete', () {
    test('hasHistory, archive e delete funcionam corretamente', () async {
      final p = (await dao.create(
        NewProduct(
          canonicalName: 'Arroz Teste',
          categoryId: 'cat-001',
          defaultUnit: Unit.kg,
        ),
      )).valueOrNull!;

      final historyEmpty = await dao.hasHistory(p.id);
      expect(historyEmpty.isOk, isTrue);
      expect(historyEmpty.valueOrNull, isFalse);

      // Insert item in pricePoints to create history
      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'price-001',
              productId: Value(p.id),
              observedAt: '2026-10-14T12:00:00Z',
              unitPriceCents: 500,
              normalizedPriceCents: 500,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );

      final historyFilled = await dao.hasHistory(p.id);
      expect(historyFilled.isOk, isTrue);
      expect(historyFilled.valueOrNull, isTrue);

      final archiveRes = await dao.archive(p.id);
      expect(archiveRes.isOk, isTrue);

      // Product with history cannot be deleted directly (would violate FK in price_points)
      final deleteWithHistoryRes = await dao.delete(p.id);
      expect(deleteWithHistoryRes.isErr, isTrue);

      // Product without history can be deleted cleanly
      final pNoHistory = (await dao.create(
        NewProduct(
          canonicalName: 'Produto Temporário',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;
      final deleteRes = await dao.delete(pNoHistory.id);
      expect(deleteRes.isOk, isTrue);
    });
  });

  group('ProductDao.buildIndex, removeAlias e checkAliasConflict', () {
    test(
      'buildIndex indexa produtos ativos, removeAlias e checkAliasConflict',
      () async {
        final p1 = (await dao.create(
          NewProduct(
            canonicalName: 'Feijão Preto',
            categoryId: 'cat-001',
            defaultUnit: Unit.kg,
          ),
        )).valueOrNull!;

        final addAliasRes = await dao.addAlias(
          p1.id,
          'feijao carioquinha',
          AliasSource.user,
        );
        expect(addAliasRes.isOk, isTrue);

        final conflict = await dao.checkAliasConflict('feijao carioquinha');
        expect(conflict.isOk, isTrue);
        expect(conflict.valueOrNull, isNotNull);
        expect(conflict.valueOrNull!.existingProductId, p1.id);

        final noConflict = await dao.checkAliasConflict(
          'produto inexistente 123',
        );
        expect(noConflict.isOk, isTrue);
        expect(noConflict.valueOrNull, isNull);

        final indexRes = await dao.buildIndex();
        expect(indexRes.isOk, isTrue);

        final aliases = await db.select(db.productAliases).get();
        final aliasToRemove = aliases.firstWhere(
          (a) => a.alias == 'feijao carioquinha',
        );
        final removeRes = await dao.removeAlias(aliasToRemove.id);
        expect(removeRes.isOk, isTrue);

        // Cannot remove alias that is canonical name
        final canonicalAlias = aliases.firstWhere(
          (a) => a.alias == 'Feijão Preto',
        );
        final removeCanonicalRes = await dao.removeAlias(canonicalAlias.id);
        expect(removeCanonicalRes.isErr, isTrue);
      },
    );
  });

  group('ProductDao.search com query vazia ou limite', () {
    test('search with empty query returns unarchived products', () async {
      await dao.create(
        NewProduct(
          canonicalName: 'Produto Ativo 1',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      );
      final p2 = (await dao.create(
        NewProduct(
          canonicalName: 'Produto Arquivado',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;
      await dao.archive(p2.id);

      final resultEmpty = await dao.search('');
      expect(resultEmpty.isOk, isTrue);
      final listEmpty = resultEmpty.valueOrNull!;
      expect(
        listEmpty.any((p) => p.canonicalName == 'Produto Ativo 1'),
        isTrue,
      );
      expect(listEmpty.any((p) => p.id == p2.id), isFalse);

      final resultWhitespace = await dao.search('   ');
      expect(resultWhitespace.isOk, isTrue);

      final resultWithLimit = await dao.search('', limit: 1);
      expect(resultWithLimit.isOk, isTrue);
      expect(resultWithLimit.valueOrNull!.length, 1);
    });

    test(
      'search with empty query returns StorageFailure if database fails',
      () async {
        await db.customStatement('DROP TABLE products;');
        final result = await dao.search('');
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      },
    );
  });

  group('ProductDao.setCanonicalName & separateAlias', () {
    test(
      'setCanonicalName valida entradas e atualiza nome preservando apelido',
      () async {
        final p = (await dao.create(
          NewProduct(
            canonicalName: 'Nome Original',
            categoryId: 'cat-001',
            defaultUnit: Unit.un,
          ),
        )).valueOrNull!;

        // Rejeita nome vazio
        final emptyRes = await dao.setCanonicalName(p.id, '   ');
        expect(emptyRes.isErr, isTrue);

        // Rejeita produto inexistente
        final notFoundRes = await dao.setCanonicalName(
          'id-inexistente',
          'Novo Nome',
        );
        expect(notFoundRes.isErr, isTrue);

        // Cria segundo produto para conflito
        await dao.create(
          NewProduct(
            canonicalName: 'Outro Produto',
            categoryId: 'cat-001',
            defaultUnit: Unit.un,
          ),
        );

        final conflictRes = await dao.setCanonicalName(p.id, 'Outro Produto');
        expect(conflictRes.isErr, isTrue);

        // Atualiza com sucesso
        final successRes = await dao.setCanonicalName(p.id, 'Nome Atualizado');
        expect(successRes.isOk, isTrue);
        expect(successRes.valueOrNull!.canonicalName, 'Nome Atualizado');

        // Verifica que o nome original virou apelido
        final aliases = await (db.select(
          db.productAliases,
        )..where((tbl) => tbl.productId.equals(p.id))).get();
        expect(aliases.any((a) => a.alias == 'Nome Original'), isTrue);
        expect(aliases.any((a) => a.alias == 'Nome Atualizado'), isTrue);
      },
    );

    test('separateAlias separa apelido em novo produto independente', () async {
      final p = (await dao.create(
        NewProduct(
          canonicalName: 'Biscoito',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      await dao.addAlias(p.id, 'Bolacha', AliasSource.user);
      final aliases = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.productId.equals(p.id))).get();
      final bolachaAlias = aliases.firstWhere((a) => a.alias == 'Bolacha');
      final biscoitoAlias = aliases.firstWhere((a) => a.alias == 'Biscoito');

      // Rejects separating canonical alias
      final sepCanonical = await dao.separateAlias(biscoitoAlias.id);
      expect(sepCanonical.isErr, isTrue);

      // Rejeita apelido inexistente
      final sepNotFound = await dao.separateAlias('alias-inexistente');
      expect(sepNotFound.isErr, isTrue);

      // Separa com sucesso
      final sepRes = await dao.separateAlias(bolachaAlias.id);
      expect(sepRes.isOk, isTrue);
      final newProd = sepRes.valueOrNull!;
      expect(newProd.canonicalName, 'Bolacha');
      expect(newProd.id, isNot(equals(p.id)));

      // Verifies denial was created in original product
      final denials = await (db.select(
        db.productDenials,
      )..where((tbl) => tbl.productId.equals(p.id))).get();
      expect(denials.any((d) => d.rawText == 'Bolacha'), isTrue);
    });

    test(
      'undoMerge retorna NotFoundFailure quando recibo não existe',
      () async {
        final res = await dao.undoMerge('recibo-inexistente');
        expect(res.isErr, isTrue);
      },
    );

    test('undoMerge reverte mesclagem com sucesso restaurando apelidos e desmarcando arquivado', () async {
      final pA = (await dao.create(
        NewProduct(
          canonicalName: 'Produto A',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      final pB = (await dao.create(
        NewProduct(
          canonicalName: 'Produto B',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      // Adiciona apelido e item de compras no produto A
      await dao.addAlias(pA.id, 'Apelido A', AliasSource.user);
      await db
          .into(db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              id: 'shop-item-1',
              productId: Value(pA.id),
              freeText: const Value('Item 1'),
              source: 'manual',
              position: 0,
            ),
          );

      // Mesclar A dentro de B
      final mergeRes = await dao.merge(from: pA.id, into: pB.id);
      expect(mergeRes.isOk, isTrue);
      final receipt = mergeRes.valueOrNull!;

      // Confirms that A is archived
      final pAArchived = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(pA.id))).getSingle();
      expect(pAArchived.isArchived, isTrue);

      // Confirma que o apelido agora aponta para B
      final aliasInB = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.alias.equals('Apelido A'))).getSingle();
      expect(aliasInB.productId, pB.id);

      // Desfazer mesclagem
      final undoRes = await dao.undoMerge(receipt.id);
      expect(undoRes.isOk, isTrue);

      // Produto A deve estar desarquivado
      final pARestored = await (db.select(
        db.products,
      )..where((tbl) => tbl.id.equals(pA.id))).getSingle();
      expect(pARestored.isArchived, isFalse);

      // Alias must point back to A
      final aliasBackInA = await (db.select(
        db.productAliases,
      )..where((tbl) => tbl.alias.equals('Apelido A'))).getSingle();
      expect(aliasBackInA.productId, pA.id);

      // Shopping item must point back to A
      final shopItemBackInA = await (db.select(
        db.shoppingItems,
      )..where((tbl) => tbl.id.equals('shop-item-1'))).getSingle();
      expect(shopItemBackInA.productId, pA.id);

      // Receipt should have been deleted
      final receiptSetting =
          await (db.select(db.settings)
                ..where((tbl) => tbl.key.equals('merge_receipt_${receipt.id}')))
              .getSingleOrNull();
      expect(receiptSetting, isNull);
    });

    test('hasHistory returns true when items exist in recipes, shoppingItems, or pricePoints', () async {
      final p = (await dao.create(
        NewProduct(
          canonicalName: 'Ingrediente Especial',
          categoryId: 'cat-001',
          defaultUnit: Unit.kg,
        ),
      )).valueOrNull!;

      // Inicialmente false
      final histEmpty = await dao.hasHistory(p.id);
      expect(histEmpty.isOk, isTrue);
      expect(histEmpty.valueOrNull, isFalse);

      // Adicionar receita e ingrediente de receita
      await db
          .into(db.recipes)
          .insert(RecipesCompanion.insert(id: 'rec-001', title: 'Bolo'));
      await db
          .into(db.recipeIngredients)
          .insert(
            RecipeIngredientsCompanion.insert(
              id: 'ing-001',
              recipeId: const Value('rec-001'),
              productId: Value(p.id),
              rawText: '500g ingrediente',
              position: 0,
              quantityMilli: const Value(500),
              unit: const Value('kg'),
            ),
          );

      final histRes = await dao.hasHistory(p.id);
      expect(histRes.isOk, isTrue);
      expect(histRes.valueOrNull, isTrue);

      // Testa shoppingItems para outro produto
      final pShop = (await dao.create(
        NewProduct(
          canonicalName: 'Item de Compras Teste',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      await db
          .into(db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              id: 'shop-item-2',
              productId: Value(pShop.id),
              freeText: const Value('Item 2'),
              source: 'manual',
              position: 0,
            ),
          );
      final histShop = await dao.hasHistory(pShop.id);
      expect(histShop.isOk, isTrue);
      expect(histShop.valueOrNull, isTrue);

      // Testa pricePoints para terceiro produto
      final pPrice = (await dao.create(
        NewProduct(
          canonicalName: 'Item com Preco',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'price-1',
              productId: Value(pPrice.id),
              observedAt: '2026-10-15T12:00:00.000Z',
              unitPriceCents: 500,
              normalizedPriceCents: 500,
              quantityMilli: 1000,
              unit: 'un',
              source: 'manual',
            ),
          );
      final histPrice = await dao.hasHistory(pPrice.id);
      expect(histPrice.isOk, isTrue);
      expect(histPrice.valueOrNull, isTrue);
    });
  });
}
