import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/main_shell_page.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/expenses_screen.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/presentation/providers/shopping_providers.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart'
    hide DateTimeRange;
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

class _FakeShoppingListDetailNotifier
    extends ValueNotifier<ShoppingListDetailState>
    implements ShoppingListDetailNotifier {
  _FakeShoppingListDetailNotifier(super.value);

  @override
  ShoppingListDetailState get state => value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  final MonthSummary summary;
  _FakeMonthSummaryRepo(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async =>
      Ok(summary);
}

class _FakeExpenseRepo implements ExpenseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  }) async => const Ok([]);
}

class _FakeCategoryRepo implements CategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async => const Ok([]);
}

void main() {
  group('SPEC-015 / T-01 - MainShell and Submodule Navigation (CA-1.1, CA-1.2, CA-1.3)', () {
    Widget buildAppWithRoutes({
      required String initialLocation,
      required GoRouter router,
      List<dynamic> extraOverrides = const [],
    }) {
      return ProviderScope(
        overrides: [...extraOverrides.cast()],
        child: MaterialApp.router(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets('CA-1.1: Bottom bar displays 5 tabs in designated order', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainShellPage(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Text('Home Screen')),
              ),
              GoRoute(
                path: '/compras',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tela Compras')),
              ),
              GoRoute(
                path: '/tarefas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tela Tarefas')),
              ),
              GoRoute(
                path: '/contas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tela Contas')),
              ),
              GoRoute(
                path: '/despesas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tela Despesas')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        buildAppWithRoutes(initialLocation: '/', router: router),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);

      final labels = [
        find.text('In\u00EDcio'),
        find.text('Compras'),
        find.text('Tarefas'),
        find.text('Contas'),
        find.text('Despesas'),
      ];

      for (final label in labels) {
        expect(label, findsOneWidget);
      }

      expect(navBar.selectedIndex, 0);

      // Tap on Shopping -> index 1
      await tester.tap(find.text('Compras'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/compras');

      // Tap on Tasks -> index 2
      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/tarefas');

      // Tap on Bills -> index 3
      await tester.tap(find.text('Contas'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/contas');

      // Tap on Expenses -> index 4
      await tester.tap(find.text('Despesas'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/despesas');
    });

    testWidgets(
      'CA-1.2: ShoppingListScreen exibe atalhos para /compras, /compras/historico-precos, /estoque e /receitas',
      (tester) async {
        String? navigatedRoute;

        final router = GoRouter(
          initialLocation: '/listas',
          routes: [
            GoRoute(
              path: '/listas',
              builder: (context, state) =>
                  const ShoppingListScreen(listId: 'test-list'),
            ),
            GoRoute(
              path: '/compras',
              builder: (context, state) {
                navigatedRoute = '/compras';
                return const Scaffold(body: Text('Tela Compras'));
              },
              routes: [
                GoRoute(
                  path: 'historico-precos',
                  builder: (context, state) {
                    navigatedRoute = '/compras/historico-precos';
                    return const Scaffold(body: Text('Tela Historico Precos'));
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/estoque',
              builder: (context, state) {
                navigatedRoute = '/estoque';
                return const Scaffold(body: Text('Tela Estoque'));
              },
            ),
            GoRoute(
              path: '/receitas',
              builder: (context, state) {
                navigatedRoute = '/receitas';
                return const Scaffold(body: Text('Tela Receitas'));
              },
            ),
          ],
        );

        final dummyList = ShoppingList(
          id: 'test-list',
          name: 'Minha Lista',
          createdAt: DateTime.now(),
          items: const [
            ShoppingItem(
              id: 'item-1',
              rawText: 'Ma\u00E7\u00E3',
              parsedName: 'Ma\u00E7\u00E3',
            ),
          ],
        );

        final shoppingNotifier = _FakeShoppingListDetailNotifier(
          ShoppingListDetailState(list: dummyList, isLoading: false),
        );

        await tester.pumpWidget(
          buildAppWithRoutes(
            initialLocation: '/listas',
            router: router,
            extraOverrides: [
              shoppingListDetailProvider('test-list')
                  .overrideWith((ref) => shoppingNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('shortcut_purchases')), findsOneWidget);
        expect(find.byKey(const Key('shortcut_prices')), findsOneWidget);
        expect(find.byKey(const Key('shortcut_stock')), findsOneWidget);
        expect(find.byKey(const Key('shortcut_recipes')), findsOneWidget);

        await tester.tap(find.byKey(const Key('shortcut_purchases')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/compras');

        router.go('/listas');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('shortcut_prices')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/compras/historico-precos');

        router.go('/listas');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('shortcut_stock')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/estoque');

        router.go('/listas');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('shortcut_recipes')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/receitas');
      },
    );

    testWidgets(
      'CA-1.3: CalendarPage e ExpensesScreen exibem atalhos na AppBar',
      (tester) async {
        String? navigatedRoute;

        final router = GoRouter(
          initialLocation: '/tarefas',
          routes: [
            GoRoute(
              path: '/tarefas',
              builder: (context, state) => const CalendarPage(),
              routes: [
                GoRoute(
                  path: 'sugestoes',
                  builder: (context, state) {
                    navigatedRoute = '/tarefas/sugestoes';
                    return const Scaffold(body: Text('Suggestions'));
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/checklist',
              builder: (context, state) {
                navigatedRoute = '/checklist';
                return const Scaffold(body: Text('Checklist'));
              },
            ),
            GoRoute(
              path: '/despesas',
              builder: (context, state) => const ExpensesScreen(),
            ),
            GoRoute(
              path: '/economia',
              builder: (context, state) {
                navigatedRoute = '/economia';
                return const Scaffold(body: Text('Economia'));
              },
            ),
            GoRoute(
              path: '/orcamento',
              builder: (context, state) {
                navigatedRoute = '/orcamento';
                return const Scaffold(body: Text('Budget Screen Content'));
              },
            ),
          ],
        );

        const ym = YearMonth('2026-10');
        await tester.pumpWidget(
          buildAppWithRoutes(
            initialLocation: '/tarefas',
            router: router,
            extraOverrides: [
              calendarTasksProvider.overrideWith(
                (ref, range) async => <Task>[],
              ),
              calendarBillsProvider.overrideWith(
                (ref, date) => const Stream.empty(),
              ),
              currentMonthProvider.overrideWithValue(ym),
              monthSummaryRepositoryProvider.overrideWithValue(
                _FakeMonthSummaryRepo(
                  const MonthSummary(
                    month: ym,
                    actual: Money.zero,
                    byCategory: [],
                    monthsOfHistory: 0,
                  ),
                ),
              ),
              expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepo()),
              categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // CalendarPage actions
        expect(
          find.byKey(const Key('tasks_suggestions_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('tasks_checklist_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('tasks_suggestions_button')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/tarefas/sugestoes');

        router.go('/tarefas');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tasks_checklist_button')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/checklist');

        // Navigate to /despesas
        router.go('/despesas');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('expenses_economy_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('expenses_budget_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('expenses_economy_button')));
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/economia');

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  });
}
