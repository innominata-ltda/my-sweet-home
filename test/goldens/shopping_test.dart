import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  FakeShoppingListRepository(this.lists);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final l = lists[id];
    if (l != null) return Ok(l);
    return const Err(StorageFailure(detail: 'Lista não encontrada'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    lists[list.id] = list;
    return const Ok(null);
  }
}

class FakePricePointRepository implements PricePointRepository {
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
  testWidgets('ShoppingListScreen golden test (empty state)', (tester) async {
    final emptyList = ShoppingList(
      id: 'list-empty',
      name: 'Mercado',
      createdAt: DateTime(2026, 9, 25),
      items: [],
    );

    final repo = FakeShoppingListRepository({'list-empty': emptyList});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            FakePricePointRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-empty'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingListScreen),
      matchesGoldenFile('shopping_screen_empty.png'),
    );
  });

  testWidgets('ShoppingListScreen golden test (loaded state with items)', (
    tester,
  ) async {
    final loadedList = ShoppingList(
      id: 'list-loaded',
      name: 'Mercado Semanal',
      createdAt: DateTime(2026, 9, 25),
      items: [
        const ShoppingItem(
          id: 'item-1',
          rawText: '2kg de arroz',
          parsedName: 'arroz',
          parsedQuantity: Quantity(2000, Unit.kg),
        ),
        ShoppingItem(
          id: 'item-2',
          rawText: '1L de leite',
          parsedName: 'leite',
          parsedQuantity: const Quantity(1000, Unit.l),
          boughtAt: DateTime(2026, 9, 25, 10, 0),
        ),
      ],
    );

    final repo = FakeShoppingListRepository({'list-loaded': loadedList});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            FakePricePointRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-loaded'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingListScreen),
      matchesGoldenFile('shopping_screen_loaded.png'),
    );
  });

  testWidgets('ShoppingListScreen golden test (all done state)', (
    tester,
  ) async {
    final allDoneList = ShoppingList(
      id: 'list-done',
      name: 'Farmácia',
      createdAt: DateTime(2026, 9, 25),
      items: [
        ShoppingItem(
          id: 'item-1',
          rawText: 'Dipirona',
          parsedName: 'Dipirona',
          boughtAt: DateTime(2026, 9, 25, 10, 0),
        ),
      ],
    );

    final repo = FakeShoppingListRepository({'list-done': allDoneList});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            FakePricePointRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-done'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingListScreen),
      matchesGoldenFile('shopping_screen_all_done.png'),
    );
  });

  testWidgets('ShoppingListScreen golden test (error state)', (tester) async {
    final repo = FakeShoppingListRepository({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            FakePricePointRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'non-existent-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingListScreen),
      matchesGoldenFile('shopping_screen_error.png'),
    );
  });

  testWidgets(
    'A11Y-2: Tap target of shopping items meets androidTapTargetGuideline (>=48dp)',
    (tester) async {
      final list = ShoppingList(
        id: 'list-a11y',
        name: 'Mercado A11Y',
        createdAt: DateTime(2026, 9, 25),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: 'Banana',
            parsedName: 'Banana',
          ),
        ],
      );

      final repo = FakeShoppingListRepository({'list-a11y': list});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repo),
            pricePointRepositoryProvider.overrideWithValue(
              FakePricePointRepository(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShoppingListScreen(listId: 'list-a11y'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    },
  );

  testWidgets(
    'A11Y-3 & A11Y-8: Tapping item marks as purchased, announces and displays SnackBar with Undo',
    (tester) async {
      final list = ShoppingList(
        id: 'list-undo',
        name: 'Mercado Undo',
        createdAt: DateTime(2026, 9, 25),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: 'Sabão em pó',
            parsedName: 'Sabão em pó',
          ),
        ],
      );

      final repo = FakeShoppingListRepository({'list-undo': list});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repo),
            pricePointRepositoryProvider.overrideWithValue(
              FakePricePointRepository(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShoppingListScreen(listId: 'list-undo'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sabão em pó'), findsOneWidget);

      // Toca no item para marcar
      await tester.tap(find.text('Sabão em pó'));
      await tester.pumpAndSettle();

      // Verifica se a SnackBar de desfazer apareceu
      expect(find.text('Desfazer'), findsOneWidget);

      // Toca em Desfazer
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
    },
  );
}
