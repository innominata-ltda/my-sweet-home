import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide Product, ShoppingList, ShoppingItem, PricePoint;
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchase_registration_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/purchase_registration_page.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/sequential_id_generator.dart';

class _FakeShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingList> lists;

  _FakeShoppingListRepository(this.lists);

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final l = lists[id];
    if (l != null) return Ok(l);
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

void main() {
  group('SPEC-004 / T-B17 — Repassar itens comprados como rascunho na rota ao registrar compra', () {
    late _FakeShoppingListRepository shoppingRepo;
    late Product sampleProduct;
    late Product sampleProductFeijao;
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
      sampleProduct = Product(
        id: 'prod_1',
        canonicalName: 'Arroz',
        categoryId: 'cat_1',
        defaultUnit: Unit.kg,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      sampleProductFeijao = Product(
        id: 'prod_2',
        canonicalName: 'Feijão',
        categoryId: 'cat_1',
        defaultUnit: Unit.kg,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final list = ShoppingList(
        id: 'list-route-test',
        name: 'Compras da Semana',
        createdAt: DateTime.utc(2026, 10, 15),
        items: [
          ShoppingItem(
            id: 'item-1',
            rawText: '2kg Arroz',
            parsedName: 'Arroz',
            parsedQuantity: const Quantity(2000, Unit.kg),
            boughtAt: DateTime.utc(2026, 10, 15, 10, 0),
          ),
          const ShoppingItem(
            id: 'item-2',
            rawText: '1kg Feijão',
            parsedName: 'Feijão',
            parsedQuantity: Quantity(1000, Unit.kg),
          ),
        ],
      );

      shoppingRepo = _FakeShoppingListRepository({
        'default': list,
        'list-route-test': list,
      });
    });

    tearDown(() async {
      await db.close();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          productListProvider.overrideWith(
            (ref) => Future.value([sampleProduct, sampleProductFeijao]),
          ),
          storeListProvider.overrideWith((ref) => Future.value([])),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12, 0, 0)),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('pt'),
            );
          },
        ),
      );
    }

    testWidgets(
      'Ao registrar compra a partir da rota /listas/:id, repassa itens comprados para /compras/nova',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Navega diretamente para /listas/list-route-test
        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        container.read(appRouterProvider).go('/listas/list-route-test');
        await tester.pumpAndSettle();

        // Verify on list screen with 1 of 2 items checked
        final bannerFinder = find.byKey(
          const Key('shopping_register_purchase_banner'),
        );
        expect(bannerFinder, findsOneWidget);
        expect(find.text('1 de 2 itens marcados'), findsOneWidget);

        // Tap register purchase button in banner
        final purchaseBtnFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(AppButton),
        );
        expect(purchaseBtnFinder, findsOneWidget);
        await tester.tap(purchaseBtnFinder);
        await tester.pumpAndSettle();

        // Must have navigated to PurchaseRegistrationPage
        expect(find.byType(PurchaseRegistrationPage), findsOneWidget);

        // O estado de PurchaseRegistrationPage deve conter o item comprado (Arroz) como rascunho
        final purchaseState = container.read(purchaseRegistrationProvider);
        expect(purchaseState.items.length, equals(1));
        expect(
          purchaseState.items.first.product?.canonicalName,
          equals('Arroz'),
        );

        // Drena timers pendentes
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'Ao registrar compra avulsa de um item específico na rota /listas/:id, repassa somente esse item para /compras/nova',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        container.read(appRouterProvider).go('/listas/list-route-test');
        await tester.pumpAndSettle();

        // Tap individual register purchase button on first unpurchased item
        final singleItemBtn = find
            .byTooltip('Registrar compra deste item')
            .first;
        expect(singleItemBtn, findsOneWidget);
        await tester.tap(singleItemBtn);
        await tester.pumpAndSettle();

        expect(find.byType(PurchaseRegistrationPage), findsOneWidget);

        final purchaseState = container.read(purchaseRegistrationProvider);
        expect(purchaseState.items.length, equals(1));
        expect(
          purchaseState.items.first.product?.canonicalName,
          equals('Feijão'),
        );

        // Drena timers pendentes
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'Ao registrar compra a partir da rota /listas (default), repassa itens comprados para /compras/nova',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        container.read(appRouterProvider).go('/listas');
        await tester.pumpAndSettle();

        final bannerFinder = find.byKey(
          const Key('shopping_register_purchase_banner'),
        );
        expect(bannerFinder, findsOneWidget);

        final purchaseBtnFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(AppButton),
        );
        expect(purchaseBtnFinder, findsOneWidget);
        await tester.tap(purchaseBtnFinder);
        await tester.pumpAndSettle();

        expect(find.byType(PurchaseRegistrationPage), findsOneWidget);

        final purchaseState = container.read(purchaseRegistrationProvider);
        expect(purchaseState.items.length, equals(1));
        expect(
          purchaseState.items.first.product?.canonicalName,
          equals('Arroz'),
        );

        // Drena timers pendentes
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
