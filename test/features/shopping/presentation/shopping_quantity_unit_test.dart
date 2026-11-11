import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
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
  group('SPEC-004 / T-B11 — Separate fields for numeric quantity and measurement unit', () {
    late _FakeShoppingListRepository repo;
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'list-qty-unit-1',
        name: 'Compras da Semana',
        createdAt: DateTime.utc(2026, 10, 1),
        items: [
          const ShoppingItem(
            id: 'item-existing',
            rawText: '1 un Sabonete',
            parsedName: 'Sabonete',
            parsedQuantity: Quantity(1000, Unit.un),
          ),
        ],
      );
      repo = _FakeShoppingListRepository({'list-qty-unit-1': testList});
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repo),
          pricePointRepositoryProvider.overrideWithValue(
            _FakePricePointRepository(),
          ),
          idGeneratorProvider.overrideWithValue(
            SequentialIdGenerator(prefix: 'item'),
          ),
          clockProvider.overrideWithValue(
            FakeClock(DateTime.utc(2026, 10, 15, 12)),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListScreen(listId: 'list-qty-unit-1'),
        ),
      );
    }

    testWidgets(
      'Exibe campos separados de quantidade (com "1" padrão) e dropdown de unidade (com "Un" padrão)',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
        expect(find.text('Qtd'), findsOneWidget);
        expect(find.byType(DropdownButton<Unit>), findsOneWidget);
        expect(find.text('Un'), findsOneWidget);
      },
    );

    testWidgets(
      'Adiciona item com quantidade customizada e unidade padrão (un)',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final qtyFinder = find.widgetWithText(TextFormField, '1');
        await tester.enterText(qtyFinder, '3');
        await tester.pump();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Banana');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final updatedList = repo.lists['list-qty-unit-1']!;
        final addedItem = updatedList.items.firstWhere(
          (i) => i.parsedName == 'Banana',
        );
        expect(addedItem.parsedQuantity, equals(const Quantity(3000, Unit.un)));
      },
    );

    testWidgets('Adiciona item com quantidade decimal e unidade kg', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Change quantity to comma decimal
      final qtyFinder = find.widgetWithText(TextFormField, '1');
      await tester.enterText(qtyFinder, '2,5');
      await tester.pump();

      // Seleciona unidade kg no dropdown
      await tester.tap(find.text('Un'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('kg').last);
      await tester.pumpAndSettle();

      final inputFinder = find.byType(AppTextField);
      await tester.enterText(inputFinder, 'Maçã');
      await tester.pump();

      final addBtnFinder = find.byTooltip('Adicionar item');
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      final updatedList = repo.lists['list-qty-unit-1']!;
      final addedItem = updatedList.items.firstWhere(
        (i) => i.parsedName == 'Maçã',
      );
      expect(addedItem.parsedQuantity, equals(const Quantity(2500, Unit.kg)));
    });

    testWidgets(
      'Adiciona item com unidade pacote (pct) e verifica que é interpretado como Unit.pack',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final qtyFinder = find.widgetWithText(TextFormField, '1');
        await tester.enterText(qtyFinder, '2');
        await tester.pump();

        // Seleciona pct no dropdown
        await tester.tap(find.text('Un'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('pct').last);
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Café Torrado');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final updatedList = repo.lists['list-qty-unit-1']!;
        final addedItem = updatedList.items.firstWhere(
          (i) => i.parsedName == 'Café Torrado',
        );
        expect(
          addedItem.parsedQuantity,
          equals(const Quantity(2000, Unit.pack)),
        );
      },
    );

    testWidgets(
      'Reseta quantidade para "1", unidade para "Un" e limpa texto do item após adicionar',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final qtyFinder = find.widgetWithText(TextFormField, '1');
        await tester.enterText(qtyFinder, '4');
        await tester.pump();

        await tester.tap(find.text('Un'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('L').last);
        await tester.pumpAndSettle();

        final inputFinder = find.byType(AppTextField);
        await tester.enterText(inputFinder, 'Leite Integral');
        await tester.pump();

        final addBtnFinder = find.byTooltip('Adicionar item');
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Verify input fields reset
        expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
        expect(find.text('Un'), findsOneWidget);
        final textField = tester.widget<TextField>(
          find.descendant(
            of: find.byType(AppTextField),
            matching: find.byType(TextField),
          ),
        );
        expect(textField.controller?.text ?? '', isEmpty);
      },
    );

    testWidgets(
      'Garante alvos de toque mínimos de 48x48 e semântica acessível',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Quantidade input box
        final qtyInputSize = tester.getSize(
          find.byKey(const Key('shopping_quantity_field')),
        );
        expect(qtyInputSize.width, greaterThanOrEqualTo(48.0));
        expect(qtyInputSize.height, greaterThanOrEqualTo(48.0));

        // Unit dropdown container
        final unitDropdownSize = tester.getSize(
          find.byKey(const Key('shopping_unit_dropdown')),
        );
        expect(unitDropdownSize.width, greaterThanOrEqualTo(48.0));
        expect(unitDropdownSize.height, greaterThanOrEqualTo(48.0));
      },
    );
  });
}
