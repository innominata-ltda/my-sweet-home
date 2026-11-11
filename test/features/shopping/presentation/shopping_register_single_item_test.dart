import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
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
  group('SPEC-004 / T-B13 - Register purchase from single item selection', () {
    late _FakeShoppingListRepository repo;
    late ShoppingList testList;
    late List<ShoppingItem> registeredItems;

    setUp(() {
      registeredItems = [];
      testList = ShoppingList(
        id: 'list-single-reg',
        name: 'Supermercado',
        createdAt: DateTime.utc(2026, 10, 1),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: '2kg de arroz',
            parsedName: 'arroz',
            parsedQuantity: Quantity(2000, Unit.kg),
          ),
          const ShoppingItem(
            id: 'item-2',
            rawText: '1kg de feijão',
            parsedName: 'feijão',
            parsedQuantity: Quantity(1000, Unit.kg),
          ),
        ],
      );
      repo = _FakeShoppingListRepository({'list-single-reg': testList});
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'reg'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(
            listId: 'list-single-reg',
            onRegisterItems: (items) {
              registeredItems = items;
            },
          ),
        ),
      );
    }

    testWidgets(
      'Exibe botão dedicado de registrar compra em cada item da lista',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final singleItemPurchaseButtons = find.byTooltip(
          'Registrar compra deste item',
        );
        expect(singleItemPurchaseButtons, findsNWidgets(2));
      },
    );

    testWidgets(
      'Tocar no botão de registrar compra de um item específico repassa apenas aquele item',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final singleItemPurchaseButtons = find.byTooltip(
          'Registrar compra deste item',
        );
        // Tap button on second item
        await tester.tap(singleItemPurchaseButtons.at(1));
        await tester.pumpAndSettle();

        expect(registeredItems.length, equals(1));
        expect(registeredItems.first.id, equals('item-2'));
        expect(registeredItems.first.parsedName, equals('feijão'));
      },
    );

    testWidgets(
      'Acionar long press no item da lista também aciona o registro daquele item específico',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final itemTile = find.text('2kg de arroz');
        await tester.longPress(itemTile);
        await tester.pumpAndSettle();

        expect(registeredItems.length, equals(1));
        expect(registeredItems.first.id, equals('item-1'));
        expect(registeredItems.first.parsedName, equals('arroz'));
      },
    );

    testWidgets(
      'Botão de compra do item possui dimensões acessíveis (min 48x48dp)',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final singleItemPurchaseButtons = find.byTooltip(
          'Registrar compra deste item',
        );
        final size = tester.getSize(singleItemPurchaseButtons.first);
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));
      },
    );
  });
}
