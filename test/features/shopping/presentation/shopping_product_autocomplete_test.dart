import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/sequential_id_generator.dart';

class _FakeShoppingListRepository implements ShoppingListRepository {
  _FakeShoppingListRepository(Map<String, ShoppingList> initial)
    : lists = Map.from(initial);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = lists[id];
    if (list != null) return Ok(list);
    return const Err(NotFoundFailure(what: 'Lista não encontrada'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    lists[list.id] = list;
    return const Ok(null);
  }
}

class _FakePricePointRepository implements PricePointRepository {
  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async => const Ok([]);

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async => const Ok([]);

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async => const Ok(
    PriceStats(averagePrice: Money(2490), observationsCount: 5, windowDays: 30),
  );

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async => const Ok(null);
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({required this.products});

  final List<Product> products;
  bool failOnSearch = false;

  @override
  Future<Result<List<Product>, Failure>> search(
    String query, {
    int limit = 50,
  }) async {
    if (failOnSearch) {
      return const Err(StorageFailure(detail: 'Erro simulado na busca'));
    }
    final normQuery = normalizeProductName(query);
    if (normQuery.isEmpty) {
      return Ok(products.take(limit).toList());
    }
    final matched = products
        .where(
          (p) =>
              !p.isArchived &&
              normalizeProductName(p.canonicalName).contains(normQuery),
        )
        .take(limit)
        .toList();
    return Ok(matched);
  }

  @override
  Future<Result<Product, Failure>> addAlias(
    ProductId id,
    String alias,
    AliasSource source,
  ) => throw UnimplementedError();

  @override
  Future<Result<Product, Failure>> setCanonicalName(
    ProductId id,
    String canonicalName,
  ) => throw UnimplementedError();

  @override
  Future<Result<Product, Failure>> separateAlias(String aliasId) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> archive(ProductId id) =>
      throw UnimplementedError();

  @override
  Future<Result<ProductIndex, Failure>> buildIndex() =>
      throw UnimplementedError();

  @override
  Future<Result<AliasConflict?, Failure>> checkAliasConflict(String alias) =>
      throw UnimplementedError();

  @override
  Future<Result<Product, Failure>> create(NewProduct p) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> delete(ProductId id) =>
      throw UnimplementedError();

  @override
  Future<Result<bool, Failure>> hasHistory(ProductId id) =>
      throw UnimplementedError();

  @override
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> registerDenial(ProductId id, String rawText) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> removeAlias(String aliasId) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id) =>
      throw UnimplementedError();
}

void main() {
  group('SPEC-004 / T-B18 — Sugerir lista de produtos ao digitar para autocompletar nome e unidade', () {
    late _FakeShoppingListRepository shoppingRepo;
    late _FakeProductRepository productRepo;
    late ShoppingList testList;
    final fixedDate = DateTime.utc(2026, 10, 15, 12);

    setUp(() {
      testList = ShoppingList(
        id: 'list-auto-1',
        name: 'Mercado do Mês',
        createdAt: fixedDate,
        items: const [],
      );
      shoppingRepo = _FakeShoppingListRepository({'list-auto-1': testList});
      productRepo = _FakeProductRepository(
        products: [
          Product(
            id: 'prod-arroz',
            canonicalName: 'Arroz Agulhinha',
            categoryId: 'cat-1',
            defaultUnit: Unit.kg,
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
          Product(
            id: 'prod-arroz-int',
            canonicalName: 'Arroz Integral',
            categoryId: 'cat-1',
            defaultUnit: Unit.pack,
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
          Product(
            id: 'prod-leite',
            canonicalName: 'Leite Integral',
            categoryId: 'cat-2',
            defaultUnit: Unit.l,
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        ],
      );
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepo),
          productRepositoryProvider.overrideWithValue(productRepo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'item'),
          ),
          clockProvider.overrideWithValue(FakeClock(fixedDate)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-auto-1'),
        ),
      );
    }

    testWidgets(
      'Exibe sugestões ao digitar e autocompleta nome, unidade de medida e vínculo ao tocar na sugestão',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Initially no suggestion list visible
        expect(
          find.byKey(const Key('shopping_product_suggestions')),
          findsNothing,
        );

        // Start typing "arr"
        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'arr');
        await tester.pumpAndSettle();

        // Suggestions list appears with two rice types
        final suggestionsBox = find.byKey(
          const Key('shopping_product_suggestions'),
        );
        expect(suggestionsBox, findsOneWidget);
        expect(find.text('Arroz Agulhinha'), findsOneWidget);
        expect(find.text('Arroz Integral'), findsOneWidget);

        // Tap suggestion "Arroz Agulhinha" (default unit: kg)
        await tester.tap(
          find.byKey(const Key('product_suggestion_prod-arroz')),
        );
        await tester.pumpAndSettle();

        // O campo de texto foi autocompletado com "Arroz Agulhinha"
        final textField = tester.widget<TextField>(
          find.descendant(of: inputFinder, matching: find.byType(TextField)),
        );
        expect(textField.controller?.text, equals('Arroz Agulhinha'));

        // O seletor de unidade foi atualizado automaticamente para Unit.kg
        final unitDropdown = tester.widget<DropdownButton<Unit>>(
          find.byType(DropdownButton<Unit>),
        );
        expect(unitDropdown.value, equals(Unit.kg));

        // Suggestions collapse after selection
        expect(suggestionsBox, findsNothing);

        // Altera a quantidade para 5 e adiciona o item
        final qtyFinder = find.widgetWithText(TextFormField, '1');
        await tester.enterText(qtyFinder, '5');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Verify item was saved with name, kg unit, and linked productId
        final savedList = shoppingRepo.lists['list-auto-1']!;
        expect(savedList.items.length, equals(1));
        final added = savedList.items.first;
        expect(added.parsedName, equals('Arroz Agulhinha'));
        expect(added.parsedQuantity, equals(const Quantity(5000, Unit.kg)));
        expect(added.productId, equals('prod-arroz'));
      },
    );

    testWidgets(
      'Borda 1: Limpar o texto oculta as sugestões; editar após selecionar limpa o vínculo anterior',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'leite');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_product_suggestions')),
          findsOneWidget,
        );

        // Limpa o campo
        await tester.enterText(inputFinder, '');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_product_suggestions')),
          findsNothing,
        );

        // Seleciona "Leite Integral" (Unit.l) e depois altera o texto manualmente
        await tester.enterText(inputFinder, 'leite');
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('product_suggestion_prod-leite')),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<DropdownButton<Unit>>(find.byType(DropdownButton<Unit>))
              .value,
          equals(Unit.l),
        );

        // Edit text to another unregistered item
        await tester.enterText(inputFinder, 'Leite de Amêndoas Caseiro');
        await tester.pumpAndSettle();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final savedList = shoppingRepo.lists['list-auto-1']!;
        expect(savedList.items.single.parsedName, 'Leite de Amêndoas Caseiro');
        expect(savedList.items.single.productId, isNull);
      },
    );

    testWidgets(
      'Borda 2: Digitar item sem correspondência no catálogo não exibe sugestões e não bloqueia adição',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Esponja de Aço');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_product_suggestions')),
          findsNothing,
        );

        await tester.tap(find.byTooltip('Adicionar item'));
        await tester.pumpAndSettle();

        final savedList = shoppingRepo.lists['list-auto-1']!;
        expect(savedList.items.single.parsedName, equals('Esponja de Aço'));
      },
    );

    testWidgets(
      'Erro: Falha na busca do ProductRepository não quebra a tela e permite adicionar texto livre',
      (tester) async {
        productRepo.failOnSearch = true;

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Arroz');
        await tester.pumpAndSettle();

        // No suggestions displayed on repository error
        expect(
          find.byKey(const Key('shopping_product_suggestions')),
          findsNothing,
        );

        // Free-text addition continues to work normally
        await tester.tap(find.byTooltip('Adicionar item'));
        await tester.pumpAndSettle();

        final savedList = shoppingRepo.lists['list-auto-1']!;
        expect(savedList.items.single.parsedName, equals('Arroz'));
      },
    );
  });
}
