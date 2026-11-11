import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
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
  group('SPEC-004 / T-B12 — Reposition item addition field to list footer', () {
    late _FakeShoppingListRepository repo;
    late ShoppingList emptyList;
    late ShoppingList populatedList;

    setUp(() {
      emptyList = ShoppingList(
        id: 'list-empty',
        name: 'Lista Vazia',
        createdAt: DateTime.utc(2026, 10, 1),
        items: const [],
      );
      populatedList = ShoppingList(
        id: 'list-populated',
        name: 'Lista Preenchida',
        createdAt: DateTime.utc(2026, 10, 1),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: '1 un Macarrão',
            parsedName: 'Macarrão',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
          const ShoppingItem(
            id: 'item-2',
            rawText: '2 un Molho de Tomate',
            parsedName: 'Molho de Tomate',
            parsedQuantity: Quantity(2000, Unit.un),
          ),
        ],
      );
      repo = _FakeShoppingListRepository({
        'list-empty': emptyList,
        'list-populated': populatedList,
      });
    });

    Widget createWidget(String listId) {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'bottom'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: listId),
        ),
      );
    }

    testWidgets(
      'Em lista vazia, campo de adição de itens fica no rodapé abaixo do estado vazio',
      (tester) async {
        await tester.pumpWidget(createWidget('list-empty'));
        await tester.pumpAndSettle();

        final emptyStateFinder = find.byType(AppEmptyState);
        final inputRowFinder = find.byKey(const Key('shopping_add_input_row'));

        expect(emptyStateFinder, findsOneWidget);
        expect(inputRowFinder, findsOneWidget);

        final emptyCenterY = tester.getCenter(emptyStateFinder).dy;
        final inputTopY = tester.getTopLeft(inputRowFinder).dy;

        // Input field MUST be strictly below center of empty state (in footer)
        expect(inputTopY, greaterThan(emptyCenterY));
      },
    );

    testWidgets(
      'Em lista com itens, campo de adição de itens fica no rodapé abaixo do ListView',
      (tester) async {
        await tester.pumpWidget(createWidget('list-populated'));
        await tester.pumpAndSettle();

        final listViewFinder = find.byType(ListView);
        final inputRowFinder = find.byKey(const Key('shopping_add_input_row'));

        expect(listViewFinder, findsOneWidget);
        expect(inputRowFinder, findsOneWidget);

        final listViewBottomY = tester.getBottomLeft(listViewFinder).dy;
        final inputTopY = tester.getTopLeft(inputRowFinder).dy;

        // Input field in footer must be at bottom, below list area
        expect(inputTopY, greaterThanOrEqualTo(listViewBottomY));
      },
    );

    testWidgets(
      'Adiciona item a partir da barra no rodapé e mantém o layout de rodapé estável',
      (tester) async {
        await tester.pumpWidget(createWidget('list-empty'));
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Queijo Minas');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Item added and visible
        expect(find.textContaining('Queijo Minas'), findsOneWidget);

        // Bar remains in footer below ListView
        final listViewFinder = find.byType(ListView);
        final inputRowFinder = find.byKey(const Key('shopping_add_input_row'));
        expect(listViewFinder, findsOneWidget);
        expect(inputRowFinder, findsOneWidget);

        final listViewBottomY = tester.getBottomLeft(listViewFinder).dy;
        final inputTopY = tester.getTopLeft(inputRowFinder).dy;
        expect(inputTopY, greaterThanOrEqualTo(listViewBottomY));
      },
    );
  });
}
