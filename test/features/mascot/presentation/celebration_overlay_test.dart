import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
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
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/day_view.dart';

class _FakeShoppingListRepository implements ShoppingListRepository {
  _FakeShoppingListRepository(this.lists);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async =>
      Ok(lists.values.toList());

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = lists[id];
    if (list != null) return Ok(list);
    return const Err(StorageFailure(detail: 'Não encontrada'));
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
  group('CelebrationOverlay — SPEC-012 (RF-112, CA-112.1, CA-112.2, CA-112.3)', () {
    testWidgets(
      'exibe Momo com expressão happy, mensagem e confetes animados',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CelebrationOverlay(
                title: 'Parabéns!',
                message: 'Tudo pronto!',
                duration: Duration.zero,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(find.text('Parabéns!'), findsOneWidget);
        expect(find.text('Tudo pronto!'), findsOneWidget);

        final mascotFinder = find.byType(MascotWidget);
        expect(mascotFinder, findsOneWidget);
        final mascot = tester.widget<MascotWidget>(mascotFinder);
        expect(mascot.expression, MascotExpression.happy);

        final state = tester.state<CelebrationOverlayState>(
          find.byType(CelebrationOverlay),
        );
        expect(state.animationController.isAnimating, isTrue);
      },
    );

    testWidgets('desaparece automaticamente em ≤ 3 segundos (CA-112.1)', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              title: 'Lista completa!',
              duration: const Duration(milliseconds: 2500),
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 2600));

      expect(dismissed, isTrue);
    });

    testWidgets('desaparece com toque na barreira de fundo (dismiss manual)', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              duration: Duration.zero,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('celebration_overlay_barrier')));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets(
      'exibe banner estático sem animação quando disableAnimations = true (CA-112.3)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: CelebrationOverlay(duration: Duration.zero),
              ),
            ),
          ),
        );
        await tester.pump();

        final state = tester.state<CelebrationOverlayState>(
          find.byType(CelebrationOverlay),
        );
        expect(state.shouldAnimate, isFalse);
        expect(state.animationController.isAnimating, isFalse);
        expect(
          find.byKey(const Key('celebration_confetti_painter')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('celebration_confetti_lottie')),
          findsNothing,
        );
        expect(find.byType(MascotWidget), findsOneWidget);
      },
    );

    testWidgets(
      'método estático CelebrationOverlay.show insere e remove OverlayEntry',
      (tester) async {
        late BuildContext savedContext;
        OverlayEntry? entry;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  savedContext = ctx;
                  return const Text('Home');
                },
              ),
            ),
          ),
        );

        entry = CelebrationOverlay.show(
          savedContext,
          title: 'Sucesso!',
          duration: const Duration(milliseconds: 2000),
        );
        await tester.pump();

        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(find.text('Sucesso!'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 2200));

        expect(find.byType(CelebrationOverlay), findsNothing);
        expect(entry.mounted, isFalse);
      },
    );

    testWidgets(
      'CelebrationOverlay.show descarta overlay ativo anterior evitando sobreposição múltipla',
      (tester) async {
        late BuildContext savedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  savedContext = ctx;
                  return const Text('Home');
                },
              ),
            ),
          ),
        );

        final firstEntry = CelebrationOverlay.show(
          savedContext,
          title: 'Primeira',
          duration: const Duration(seconds: 5),
        );
        await tester.pump();

        expect(find.text('Primeira'), findsOneWidget);
        expect(find.byType(CelebrationOverlay), findsOneWidget);

        // Trigger second celebration before first expires
        final secondEntry = CelebrationOverlay.show(
          savedContext,
          title: 'Segunda',
          duration: const Duration(seconds: 5),
        );
        await tester.pump();

        expect(find.text('Segunda'), findsOneWidget);
        expect(find.text('Primeira'), findsNothing);
        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(firstEntry.mounted, isFalse);
        expect(secondEntry.mounted, isTrue);

        await tester.tap(find.byKey(const Key('celebration_overlay_barrier')));
        await tester.pump();
        expect(find.byType(CelebrationOverlay), findsNothing);
      },
    );

    testWidgets(
      'A11Y (RNF-011, CA-285.2): Suporta textScaleFactor 2.0 sem overflow de layout',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: CelebrationOverlay(
                  title: 'Parabéns por completar tudo hoje!',
                  message: 'Você concluiu todas as tarefas e compras planejadas com muito amor!',
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(find.byType(MascotWidget), findsOneWidget);
      },
    );

    testWidgets(
      'CA-112.1: aciona celebração ao marcar o último item da lista de compras',
      (tester) async {
        final sampleList = ShoppingList(
          id: 'list-5-items',
          name: 'Compras da Semana',
          createdAt: DateTime(2026, 10, 1),
          items: [
            ShoppingItem(
              id: 'i1',
              rawText: 'Item 1',
              parsedName: 'Item 1',
              boughtAt: DateTime(2026, 10, 1),
            ),
            ShoppingItem(
              id: 'i2',
              rawText: 'Item 2',
              parsedName: 'Item 2',
              boughtAt: DateTime(2026, 10, 1),
            ),
            ShoppingItem(
              id: 'i3',
              rawText: 'Item 3',
              parsedName: 'Item 3',
              boughtAt: DateTime(2026, 10, 1),
            ),
            ShoppingItem(
              id: 'i4',
              rawText: 'Item 4',
              parsedName: 'Item 4',
              boughtAt: DateTime(2026, 10, 1),
            ),
            const ShoppingItem(
              id: 'i5',
              rawText: 'Item 5',
              parsedName: 'Item 5',
            ),
          ],
        );

        final fakeRepo = _FakeShoppingListRepository({
          'list-5-items': sampleList,
        });

        await tester.pumpWidget(
          ProviderScope(
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
              home: ShoppingListScreen(listId: 'list-5-items'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CelebrationOverlay), findsNothing);

        // Check last pending item (Item 5)
        await tester.tap(find.text('Item 5'));
        await tester.pump();

        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(
          find.text('Você completou a lista de compras! 💕'),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 3000));
        expect(find.byType(CelebrationOverlay), findsNothing);
      },
    );

    testWidgets(
      'CA-112.2: aciona celebração ao concluir a última tarefa do dia no DayView',
      (tester) async {
        final targetDate = DateTime(2026, 10, 20);
        final tasks = [
          Task(
            id: 't1',
            title: 'Lavar louça',
            dueAt: targetDate,
            allDay: true,
            isCompleted: true,
            completedAt: targetDate,
            syncState: SyncState.synced,
            createdAt: targetDate,
            updatedAt: targetDate,
          ),
          Task(
            id: 't2',
            title: 'Tirar o lixo',
            dueAt: targetDate,
            allDay: true,
            isCompleted: false,
            syncState: SyncState.synced,
            createdAt: targetDate,
            updatedAt: targetDate,
          ),
        ];

        var toggleCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: Scaffold(
              body: DayView(
                date: targetDate,
                tasks: tasks,
                onToggleComplete: (task, completed) {
                  toggleCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CelebrationOverlay), findsNothing);

        // Tap CuteCheckbox of last pending task
        final checkboxFinder = find.byType(CuteCheckbox);
        expect(checkboxFinder, findsNWidgets(2));
        await tester.tap(checkboxFinder.last);
        await tester.pump();

        expect(toggleCalled, isTrue);
        expect(find.byType(CelebrationOverlay), findsOneWidget);
        expect(
          find.text('Todas as tarefas de hoje foram concluídas! 🎉'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('celebration_overlay_barrier')));
        await tester.pump();
        expect(find.byType(CelebrationOverlay), findsNothing);
      },
    );
  });
}
