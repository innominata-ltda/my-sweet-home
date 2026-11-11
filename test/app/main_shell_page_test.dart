import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/main_shell_page.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/presentation/budget_screen.dart';

void main() {
  group('T-B13 — MainShellPage Tab Routing and FAB visibility', () {
    late GoRouter testRouter;

    Widget buildShellTestApp({String initialLocation = '/'}) {
      testRouter = GoRouter(
        initialLocation: initialLocation,
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainShellPage(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Text('Home Content')),
              ),
              GoRoute(
                path: '/despesas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Expenses Content')),
              ),
              GoRoute(
                path: '/orcamento',
                builder: (context, state) =>
                    const Scaffold(body: Text('Budget Content')),
              ),
              GoRoute(
                path: '/contas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Bills Content')),
              ),
              GoRoute(
                path: '/tarefas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Tasks Content')),
              ),
              GoRoute(
                path: '/listas',
                builder: (context, state) =>
                    const Scaffold(body: Text('Lists Content')),
              ),
            ],
          ),
        ],
      );

      return MaterialApp.router(theme: lightTheme(), routerConfig: testRouter);
    }

    testWidgets('/ selects tab 0 and displays camera FAB', (tester) async {
      await tester.pumpWidget(buildShellTestApp(initialLocation: '/'));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('/despesas selects tab 4 and does not display FAB', (
      tester,
    ) async {
      await tester.pumpWidget(buildShellTestApp(initialLocation: '/despesas'));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 4);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets(
      '/orcamento in shell maps to tab 4 (despesas) and does not display FAB',
      (tester) async {
        await tester.pumpWidget(
          buildShellTestApp(initialLocation: '/orcamento'),
        );
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 4);
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets('Switching tabs via NavigationBar updates route and index', (
      tester,
    ) async {
      await tester.pumpWidget(buildShellTestApp(initialLocation: '/'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contas'));
      await tester.pumpAndSettle();

      final navBarContas = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBarContas.selectedIndex, 3);

      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();

      final navBarTarefas = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBarTarefas.selectedIndex, 2);
    });
  });

  group('T-B13 — BudgetScreen Back Button and Padding', () {
    late GoRouter budgetRouter;

    Widget buildBudgetScreenApp({String initialLocation = '/orcamento'}) {
      budgetRouter = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/despesas',
            builder: (context, state) =>
                const Scaffold(body: Text('Tela Despesas')),
          ),
          GoRoute(
            path: '/orcamento',
            builder: (context, state) => const BudgetScreen(),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          budgetsForMonthProvider.overrideWith(
            (ref, month) => Future.value(<Budget>[]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => Future.value(<Category>[]),
          ),
        ],
        child: MaterialApp.router(
          theme: lightTheme(),
          routerConfig: budgetRouter,
        ),
      );
    }

    testWidgets(
      'BudgetScreen has back button returning to /despesas and bottom padding >= 80',
      (tester) async {
        await tester.pumpWidget(buildBudgetScreenApp());
        await tester.pumpAndSettle();

        expect(find.byType(BudgetScreen), findsOneWidget);

        final backButton = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == AppIcons.back,
        );
        expect(backButton, findsOneWidget);

        final listView = tester.widget<ListView>(find.byType(ListView));
        final padding = listView.padding as EdgeInsets;
        expect(padding.bottom, greaterThanOrEqualTo(80.0));

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Tela Despesas'), findsOneWidget);
      },
    );
  });
}
