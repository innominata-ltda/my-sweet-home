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

class _FakeShoppingListRepository implements ShoppingListRepository {
  _FakeShoppingListRepository(this.lists);

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
  group('SPEC-004 — T-V3 Acessibilidade (A11Y-2, A11Y-3, A11Y-8)', () {
    late ShoppingList sampleList;
    late _FakeShoppingListRepository fakeRepo;

    setUp(() {
      sampleList = ShoppingList(
        id: 'list-a11y-test',
        name: 'Feira Semanal',
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
      fakeRepo = _FakeShoppingListRepository({'list-a11y-test': sampleList});
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(fakeRepo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('pt'),
          home: ShoppingListScreen(listId: 'list-a11y-test'),
        ),
      );
    }

    testWidgets(
      'A11Y-2: Alvo de toque atende diretrizes androidTapTargetGuideline (>=48dp)',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ShoppingItemTile), findsNWidgets(2));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        handle.dispose();
      },
    );

    testWidgets(
      'A11Y-3: Todo item interativo possui rótulo semântico com a AÇÃO em pt-BR',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Unpurchased item (item-1: '2kg de arroz', parsedName: 'arroz')
        final unboughtSemantics = find.bySemanticsLabel(
          'Marcar arroz como comprado',
        );
        expect(unboughtSemantics, findsOneWidget);

        // Item comprado (item-2: '1L de leite', parsedName: 'leite')
        final boughtSemantics = find.bySemanticsLabel(
          'Desmarcar leite como comprado',
        );
        expect(boughtSemantics, findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'A11Y-8: Campo de adicionar item possui rótulo persistente e SnackBar de desfazer tem liveRegion e foco',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 1. Persistent label in input field
        expect(find.text('Adicionar item'), findsWidgets);

        // 2. Tocar no item para marcar como comprado
        await tester.tap(find.text('2kg de arroz'));
        await tester.pumpAndSettle();

        // 3. Undo snackbar must appear with liveRegion and action label
        final undoFinder = find.text('Desfazer');
        expect(undoFinder, findsOneWidget);

        // 4. Verificar liveRegion na mensagem do SnackBar
        final liveRegionFinder = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        );
        expect(liveRegionFinder, findsAtLeastNWidgets(1));

        // 5. Test invoking Undo action via focus / tap
        await tester.tap(undoFinder);
        await tester.pumpAndSettle();

        // After undo, item returns to unpurchased state
        expect(
          find.bySemanticsLabel('Marcar arroz como comprado'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets('A11Y-3: Fallback to rawText when parsedName is empty', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      final emptyParsedList = ShoppingList(
        id: 'list-empty-parsed',
        name: 'Lista Fallback',
        createdAt: DateTime(2026, 9, 25),
        items: [
          const ShoppingItem(
            id: 'item-3',
            rawText: 'sabão em pó',
            parsedName: '',
          ),
        ],
      );

      final repo = _FakeShoppingListRepository({
        'list-empty-parsed': emptyParsedList,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repo),
            pricePointRepositoryProvider.overrideWithValue(
              _FakePricePointRepository(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('pt'),
            home: ShoppingListScreen(listId: 'list-empty-parsed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Marcar sabão em pó como comprado'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets(
      'A11Y-4: Layout integridade com textScaler 2.0 (sem overflow)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: buildTestWidget(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ShoppingItemTile), findsNWidgets(2));

        handle.dispose();
      },
    );
  });
}
