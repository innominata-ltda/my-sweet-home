import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
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

class _DelayedFakeShoppingListRepository implements ShoppingListRepository {
  _DelayedFakeShoppingListRepository(Map<String, ShoppingList> initial)
    : lists = Map.from(initial);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    // Simulate network/disk latency
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final list = lists[id];
    if (list != null) return Ok(list);
    return const Err(NotFoundFailure(what: 'Lista não encontrada'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    // Simulate write latency
    await Future<void>.delayed(const Duration(milliseconds: 100));
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
  group('SPEC-004 / T-B14 - Eliminate full screen reload on mutations', () {
    late _DelayedFakeShoppingListRepository repo;
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'list-no-loading',
        name: 'Compras Rápidas',
        createdAt: DateTime.utc(2026, 10, 1),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: '1 un P\u00E3o',
            parsedName: 'Pão',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
          ShoppingItem(
            id: 'item-2',
            rawText: '1 un Manteiga',
            parsedName: 'Manteiga',
            parsedQuantity: const Quantity(1000, Unit.un),
            boughtAt: DateTime.utc(2026, 10, 1, 10, 0),
          ),
        ],
      );
      repo = _DelayedFakeShoppingListRepository({'list-no-loading': testList});
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'load'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-no-loading'),
        ),
      );
    }

    testWidgets(
      'Individual item removal does NOT display AppLoading during operation',
      (tester) async {
        await tester.pumpWidget(createWidget());
        // Await legitimate initial load
        await tester.pumpAndSettle();

        expect(find.text('1 un P\u00E3o'), findsOneWidget);
        expect(find.byType(AppLoading), findsNothing);

        // Toca em remover o item
        final deleteButtons = find.byTooltip('Remover item');
        await tester.tap(deleteButtons.first);

        // Advance to moment persistence completed and loadList is triggered
        await tester.pump(const Duration(milliseconds: 110));

        // Must not display AppLoading at any point
        expect(find.byType(AppLoading), findsNothing);
        expect(find.byType(ShoppingListScreen), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(AppLoading), findsNothing);
      },
    );

    testWidgets(
      'Limpeza de itens concluídos NÃO exibe AppLoading durante a operação',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final clearPurchasedBtn = find.byTooltip('Limpar comprados');
        expect(clearPurchasedBtn, findsOneWidget);

        await tester.tap(clearPurchasedBtn);
        await tester.pump(const Duration(milliseconds: 110));

        // Must not replace screen with AppLoading
        expect(find.byType(AppLoading), findsNothing);
        expect(find.byType(ShoppingListScreen), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(AppLoading), findsNothing);
      },
    );

    testWidgets('Item addition does NOT display AppLoading during operation', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final inputFinder = find.byType(AppTextField);
      await tester.enterText(inputFinder, 'Café');
      await tester.pump();

      final addBtnFinder = find.byTooltip('Adicionar item');
      await tester.tap(addBtnFinder);
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(AppLoading), findsNothing);
      expect(find.byType(ShoppingListScreen), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(AppLoading), findsNothing);
      expect(find.textContaining('Café'), findsOneWidget);
    });
  });
}
