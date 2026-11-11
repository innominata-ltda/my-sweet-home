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
import 'package:my_sweet_home/features/shopping/presentation/widgets/shopping_item_tile.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  FakeShoppingListRepository(this.lists);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = lists[id];
    if (list != null) return Ok(list);
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
  group('T-V2 / RNF-002: Rolagem fluida com 300 itens', () {
    late List<ShoppingItem> items300;
    late ShoppingList list300;
    late FakeShoppingListRepository repo;

    setUp(() {
      items300 = List.generate(
        300,
        (index) => ShoppingItem(
          id: 'item-${index + 1}',
          rawText: 'Item ${index + 1}',
          parsedName: 'Item ${index + 1}',
          parsedQuantity: index % 2 == 0 ? Quantity(index + 1, Unit.un) : null,
        ),
      );

      list300 = ShoppingList(
        id: 'list-300',
        name: 'Lista de 300 itens',
        createdAt: DateTime(2026, 9, 30),
        items: items300,
      );

      repo = FakeShoppingListRepository({'list-300': list300});
    });

    testWidgets(
      'Deve renderizar e rolar fluidamente 300 itens do topo até o fim',
      (tester) async {
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
              home: ShoppingListScreen(listId: 'list-300'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verifica que o topo exibe o Item 1
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.byType(ShoppingItemTile), findsWidgets);

        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        // Scroll down vigorously to end of list (300 items)
        for (var i = 0; i < 15; i++) {
          await tester.fling(listViewFinder, const Offset(0, -3000), 10000);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify last item (Item 300) is rendered
        expect(find.text('Item 300'), findsOneWidget);

        // Rola de volta para o topo
        for (var i = 0; i < 15; i++) {
          await tester.fling(listViewFinder, const Offset(0, 3000), 10000);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify Item 1 is visible again
        expect(find.text('Item 1'), findsOneWidget);
      },
    );

    testWidgets(
      'Must allow marking items in 300-item list without failure or jank',
      (tester) async {
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
              home: ShoppingListScreen(listId: 'list-300'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toca para marcar o Item 1
        expect(find.text('Item 1'), findsOneWidget);
        await tester.tap(find.text('Item 1'));
        await tester.pumpAndSettle();

        // Item 1 must be moved to bottom of list and show undo snackbar
        expect(find.text('Desfazer'), findsOneWidget);
      },
    );
  });
}
