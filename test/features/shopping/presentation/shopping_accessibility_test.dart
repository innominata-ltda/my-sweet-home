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
  Future<Result<List<ShoppingList>, Failure>> getAll() async =>
      Ok(lists.values.toList());

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
  group('T-B19: Responsividade da barra de adicionar itens com fonte 200%', () {
    late _FakeShoppingListRepository shoppingRepo;
    late _FakePricePointRepository priceRepo;
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'list-1',
        name: 'Compras da Semana',
        createdAt: DateTime.utc(2026, 10, 1),
        items: const [],
      );
      shoppingRepo = _FakeShoppingListRepository({'list-1': testList});
      priceRepo = _FakePricePointRepository();
    });

    Widget buildSubject({double textScaleFactor = 2.0}) {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepo),
          pricePointRepositoryProvider.overrideWithValue(priceRepo),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 20, 10, 0)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: const ShoppingListScreen(listId: 'list-1'),
          ),
        ),
      );
    }

    testWidgets(
      'Barra de adicionar itens adapta layout com fonte 200% sem overflow ou truncamento',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject(textScaleFactor: 2.0));
        await tester.pumpAndSettle();

        // 1. Sem overflow de layout
        expect(tester.takeException(), isNull);

        // 2. Essential elements visible
        expect(find.byKey(const Key('shopping_add_input_row')), findsOneWidget);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(
          find.byKey(const Key('shopping_quantity_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('shopping_unit_dropdown')), findsOneWidget);

        // 3. Adicionar item com quantidade e unidade sob fonte 200%
        await tester.enterText(find.byType(AppTextField), 'Leite');
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('shopping_quantity_field')),
            matching: find.byType(TextFormField),
          ),
          '3',
        );
        await tester.pump();

        final addButton = find.byTooltip('Adicionar item');
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 4. Item added and visible in list
        expect(find.textContaining('Leite'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Barra de adicionar itens funciona normalmente com escala 1.0',
      (tester) async {
        await tester.pumpWidget(buildSubject(textScaleFactor: 1.0));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('shopping_add_input_row')), findsOneWidget);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(
          find.byKey(const Key('shopping_quantity_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('shopping_unit_dropdown')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
