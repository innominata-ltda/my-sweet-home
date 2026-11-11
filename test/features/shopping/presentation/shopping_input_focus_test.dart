import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
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

import '../../../../test/fakes/fake_clock.dart';
import '../../../../test/fakes/sequential_id_generator.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 50));
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
  group(
    'SPEC-004 / T-B09 — Manter foco na entrada de texto e teclado ativo',
    () {
      late _FakeShoppingListRepository repo;
      late ShoppingList testList;

      setUp(() {
        testList = ShoppingList(
          id: 'list-1',
          name: 'Compras do Mês',
          createdAt: DateTime.utc(2026, 10, 1),
          items: [
            ShoppingItem(
              id: 'item-1',
              rawText: '1 un Arroz',
              parsedName: 'Arroz',
            ),
          ],
        );
        repo = _FakeShoppingListRepository({'list-1': testList});
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
            home: ShoppingListScreen(listId: 'list-1'),
          ),
        );
      }

      testWidgets(
        'Mantém o foco no campo de texto após submeter item via teclado',
        (tester) async {
          await tester.pumpWidget(createWidget());
          await tester.pumpAndSettle();

          final inputFinder = find.byType(AppTextField);
          expect(inputFinder, findsOneWidget);

          // Foca no campo e digita um item
          await tester.tap(inputFinder);
          await tester.pump();
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText).first)
                .focusNode
                .hasFocus,
            isTrue,
          );

          await tester.enterText(inputFinder, 'Feijão');
          await tester.pump();

          // Submit text input simulating keyboard action (done / onFieldSubmitted)
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump(const Duration(milliseconds: 60));
          await tester.pump();
          // Must not display AppLoading during addition (no state reset)
          expect(find.byType(AppLoading), findsNothing);

          await tester.pumpAndSettle();

          // Verifica que o item foi adicionado
          expect(find.textContaining('Feijão'), findsOneWidget);

          // Field must be cleared and keep focus active for continuous typing
          final editableText = tester.widget<EditableText>(
            find.byType(EditableText).first,
          );
          expect(editableText.controller.text, isEmpty);
          expect(editableText.focusNode.hasFocus, isTrue);
        },
      );

      testWidgets(
        'Mantém o foco no campo de texto ao adicionar item via botão Adicionar',
        (tester) async {
          await tester.pumpWidget(createWidget());
          await tester.pumpAndSettle();

          final inputFinder = find.byType(AppTextField);
          await tester.tap(inputFinder);
          await tester.pump();
          await tester.enterText(inputFinder, 'Macarrão');
          await tester.pump();

          // Tap add button
          final addBtnFinder = find.byTooltip('Adicionar item');
          expect(addBtnFinder, findsOneWidget);
          await tester.tap(addBtnFinder);
          await tester.pump(const Duration(milliseconds: 60));
          await tester.pump();

          // Must not display full screen loading
          expect(find.byType(AppLoading), findsNothing);

          await tester.pumpAndSettle();

          // Item adicionado e campo focado
          expect(find.textContaining('Macarrão'), findsOneWidget);
          final editableText = tester.widget<EditableText>(
            find.byType(EditableText).first,
          );
          expect(editableText.controller.text, isEmpty);
          expect(editableText.focusNode.hasFocus, isTrue);
        },
      );
    },
  );
}
