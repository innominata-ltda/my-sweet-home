import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
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

void main() {
  group('SPEC-004 / T-B15 - Preserve Scaffold and stable text field', () {
    late _FakeShoppingListRepository repo;
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'list-stable-scaffold',
        name: 'Lista Estável',
        createdAt: DateTime.utc(2026, 10, 1),
        items: const [],
      );
      repo = _FakeShoppingListRepository({'list-stable-scaffold': testList});
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'stable'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-stable-scaffold'),
        ),
      );
    }

    testWidgets(
      'Preserva a mesma instância de ScaffoldState na transição entre lista vazia e preenchida',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Estado inicial: lista vazia
        expect(find.byType(AppEmptyState), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        final initialScaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );

        // Adiciona o primeiro item
        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Maçã Fuji');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Agora preenchida com o item
        expect(find.byType(AppEmptyState), findsNothing);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.textContaining('Maçã Fuji'), findsOneWidget);

        final afterAddScaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );

        // Scaffold structure MUST NOT be rebuilt/destroyed
        expect(identical(initialScaffoldState, afterAddScaffoldState), isTrue);

        // Now remove single item to return to empty state
        final deleteBtnFinder = find.byTooltip('Remover item');
        await tester.tap(deleteBtnFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AppEmptyState), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        final afterRemoveScaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );

        // Continues preserving same Scaffold instance
        expect(
          identical(initialScaffoldState, afterRemoveScaffoldState),
          isTrue,
        );
      },
    );

    testWidgets(
      'Preserva o foco e estado do campo de texto ao adicionar primeiro item',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.tap(inputFinder);
        await tester.pump();

        final initialEditableState = tester.state<EditableTextState>(
          find.byType(EditableText).first,
        );

        await tester.enterText(inputFinder, 'Banana Prata');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final afterAddEditableState = tester.state<EditableTextState>(
          find.byType(EditableText).first,
        );

        // O widget de entrada de texto e seu estado permanecem os mesmos
        expect(identical(initialEditableState, afterAddEditableState), isTrue);
      },
    );
  });
}
