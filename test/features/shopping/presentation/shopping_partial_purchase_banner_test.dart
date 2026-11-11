import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
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

void main() {
  group('SPEC-004 / T-B16 — Display prominent Register Purchase button with partial selection', () {
    late _FakeShoppingListRepository repo;
    late ShoppingList testList;
    late List<ShoppingItem> registeredItems;

    setUp(() {
      registeredItems = [];
      testList = ShoppingList(
        id: 'list-partial-purchase',
        name: 'Compras da Semana',
        createdAt: DateTime.utc(2026, 10, 1),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: '1 un Arroz',
            parsedName: 'Arroz',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
          const ShoppingItem(
            id: 'item-2',
            rawText: '1 un Feijão',
            parsedName: 'Feijão',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
          const ShoppingItem(
            id: 'item-3',
            rawText: '1 un Macarrão',
            parsedName: 'Macarrão',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
        ],
      );
      repo = _FakeShoppingListRepository({'list-partial-purchase': testList});
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'partial'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(
            listId: 'list-partial-purchase',
            onRegisterItems: (items) {
              registeredItems = items;
            },
          ),
        ),
      );
    }

    testWidgets(
      'Quando nenhum item está marcado como comprado, o banner de destaque não é exibido',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopping_register_purchase_banner')),
          findsNothing,
        );
        expect(
          find.widgetWithText(AppButton, 'registrar a compra'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Com seleção parcial de itens, exibe o banner em destaque e repassa itens comprados ao acionar',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Marca apenas o item 1 (Arroz) como comprado
        final item1Finder = find.text('1 un Arroz');
        await tester.tap(item1Finder);
        await tester.pumpAndSettle();

        // Now there is partial selection (1 of 3 items)
        final bannerFinder = find.byKey(
          const Key('shopping_register_purchase_banner'),
        );
        expect(bannerFinder, findsOneWidget);
        expect(find.text('1 de 3 itens marcados'), findsOneWidget);

        final purchaseBtnFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(AppButton),
        );
        expect(purchaseBtnFinder, findsOneWidget);

        // Tap prominent register purchase button
        await tester.tap(purchaseBtnFinder);
        await tester.pumpAndSettle();

        // Repassa apenas os itens comprados (Arroz)
        expect(registeredItems.length, equals(1));
        expect(registeredItems.first.parsedName, equals('Arroz'));
      },
    );

    testWidgets(
      'Com todos os itens comprados, exibe o banner com mensagem de conclusão',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Marca os 3 itens
        await tester.tap(find.text('1 un Arroz'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 un Feijão'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 un Macarrão'));
        await tester.pumpAndSettle();

        final bannerFinder = find.byKey(
          const Key('shopping_register_purchase_banner'),
        );
        expect(bannerFinder, findsOneWidget);
        expect(find.text('Tudo comprado 🎉'), findsOneWidget);

        final purchaseBtnFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(AppButton),
        );
        expect(purchaseBtnFinder, findsOneWidget);

        await tester.tap(purchaseBtnFinder);
        await tester.pumpAndSettle();

        expect(registeredItems.length, equals(3));
      },
    );
  });
}
