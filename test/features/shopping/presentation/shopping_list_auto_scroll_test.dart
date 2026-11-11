import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
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
    // Simulates small db I/O latency
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final list = lists[id];
    if (list != null) return Ok(list);
    return const Err(NotFoundFailure(what: 'Lista não encontrada'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    // Simulates small db write latency
    await Future<void>.delayed(const Duration(milliseconds: 30));
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
  group(
    'SPEC-004 / T-B10 — Rolagem automática até o novo item após renderização',
    () {
      late _FakeShoppingListRepository repo;
      late ShoppingList testList;

      setUp(() {
        final items = List.generate(
          25,
          (i) => ShoppingItem(
            id: 'item-$i',
            rawText: 'Item ${i + 1}',
            parsedName: 'Item ${i + 1}',
          ),
        );
        testList = ShoppingList(
          id: 'list-scroll-1',
          name: 'Lista Longa',
          createdAt: DateTime.utc(2026, 10, 1),
          items: items,
        );
        repo = _FakeShoppingListRepository({'list-scroll-1': testList});
      });

      Widget createWidget() {
        return ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repo),
            pricePointRepositoryProvider.overrideWithValue(
              _FakePricePointRepository(),
            ),
            idGeneratorProvider.overrideWithValue(
              SequentialIdGenerator(prefix: 'gen'),
            ),
            clockProvider.overrideWithValue(
              FakeClock(DateTime.utc(2026, 10, 15, 12)),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShoppingListScreen(listId: 'list-scroll-1'),
          ),
        );
      }

      testWidgets(
        'Executa rolagem automática até o novo item após sua renderização real na lista',
        (tester) async {
          await tester.pumpWidget(createWidget());
          await tester.pumpAndSettle();

          // Initially at top: Item 1 visible, Item 25 off screen
          expect(find.text('Item 1'), findsOneWidget);
          expect(find.text('Item 25'), findsNothing);

          final listScrollableFinder = find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          );
          final initialScrollOffset = tester
              .state<ScrollableState>(listScrollableFinder)
              .position
              .pixels;
          expect(initialScrollOffset, equals(0.0));

          // Digita um novo item
          final inputFinder = find.byType(AppTextField);
          await tester.tap(inputFinder);
          await tester.pump();
          await tester.enterText(inputFinder, 'Chocolate Especial');
          await tester.pump();

          // Tap add button
          final addBtnFinder = find.byTooltip('Adicionar item');
          await tester.tap(addBtnFinder);

          // Advance simulation and animations
          await tester.pumpAndSettle();

          // New item should be rendered and list should auto-scroll to it
          final newItemFinder = find.textContaining('Chocolate Especial');
          expect(newItemFinder, findsOneWidget);

          final finalScrollPosition = tester
              .state<ScrollableState>(listScrollableFinder)
              .position;
          // Scroll should advance significantly to show new item at bottom
          expect(finalScrollPosition.pixels, greaterThan(0.0));
          expect(
            (finalScrollPosition.maxScrollExtent - finalScrollPosition.pixels)
                .abs(),
            lessThanOrEqualTo(1.0),
          );
        },
      );

      testWidgets('Performs auto-scroll when submitting item via keyboard', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final listScrollableFinder = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        );
        expect(
          tester.state<ScrollableState>(listScrollableFinder).position.pixels,
          equals(0.0),
        );

        final inputFinder = find.byType(AppTextField);
        await tester.tap(inputFinder);
        await tester.pump();
        await tester.enterText(inputFinder, 'Biscoito Recheado');
        await tester.pump();

        // Submit via keyboard action
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        final newItemFinder = find.textContaining('Biscoito Recheado');
        expect(newItemFinder, findsOneWidget);

        final finalScrollPosition = tester
            .state<ScrollableState>(listScrollableFinder)
            .position;
        expect(finalScrollPosition.pixels, greaterThan(0.0));
        expect(
          (finalScrollPosition.maxScrollExtent - finalScrollPosition.pixels)
              .abs(),
          lessThanOrEqualTo(1.0),
        );
      });

      testWidgets(
        'Lida corretamente com adição em lista inicialmente vazia sem erros',
        (tester) async {
          final emptyList = ShoppingList(
            id: 'list-empty',
            name: 'Lista Vazia',
            createdAt: DateTime.utc(2026, 10, 1),
            items: const [],
          );
          repo.lists['list-empty'] = emptyList;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                shoppingListRepositoryProvider.overrideWithValue(repo),
                pricePointRepositoryProvider.overrideWithValue(
                  _FakePricePointRepository(),
                ),
                idGeneratorProvider.overrideWithValue(
                  SequentialIdGenerator(prefix: 'gen'),
                ),
                clockProvider.overrideWithValue(
                  FakeClock(DateTime.utc(2026, 10, 15, 12)),
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

          final inputFinder = find.byType(AppTextField);
          await tester.tap(inputFinder);
          await tester.pump();
          await tester.enterText(inputFinder, 'Primeiro Item');
          await tester.pump();

          final addBtnFinder = find.byTooltip('Adicionar item');
          await tester.tap(addBtnFinder);
          await tester.pumpAndSettle();

          expect(find.textContaining('Primeiro Item'), findsOneWidget);
        },
      );
    },
  );
}
