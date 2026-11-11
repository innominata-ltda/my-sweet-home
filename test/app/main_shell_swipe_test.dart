import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/main_shell_page.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';

class _TestTabBarPage extends StatefulWidget {
  const _TestTabBarPage();

  @override
  State<_TestTabBarPage> createState() => _TestTabBarPageState();
}

class _TestTabBarPageState extends State<_TestTabBarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dia'),
            Tab(text: 'Semana'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Sub-aba Dia')),
          Center(child: Text('Sub-aba Semana')),
          Center(child: Text('Sub-tab Month')),
        ],
      ),
    );
  }
}

void main() {
  group('SPEC-001 / T-G04 — MainShellPage Horizontal Swipe Navigation', () {
    late GoRouter testRouter;

    Widget buildShellSwipeApp({
      String initialLocation = '/',
      bool disableAnimations = false,
    }) {
      testRouter = GoRouter(
        initialLocation: initialLocation,
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainShellPage(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Content'))),
              ),
              GoRoute(
                path: '/despesas',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Expenses Content')),
                ),
              ),
              GoRoute(
                path: '/contas',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Bills Content'))),
              ),
              GoRoute(
                path: '/tarefas',
                builder: (context, state) => const _TestTabBarPage(),
              ),
              GoRoute(
                path: '/compras',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Shopping Content')),
                ),
              ),
              GoRoute(
                path: '/listas',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Lists Content'))),
              ),
            ],
          ),
        ],
      );

      return MaterialApp.router(
        theme: lightTheme(),
        routerConfig: testRouter,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: child!,
          );
        },
      );
    }

    testWidgets(
      'CA-11.1 & RN-018: Swipe left on Home tab navigates to Shopping and syncs FAB; swipe right returns to Home',
      (tester) async {
        await tester.pumpWidget(buildShellSwipeApp(initialLocation: '/'));
        await tester.pumpAndSettle();

        expect(find.text('Home Content'), findsOneWidget);
        var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Swipe left to advance to Shopping/Lists
        await tester.drag(find.text('Home Content'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Lists Content'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 1);
        expect(find.byType(FloatingActionButton), findsNothing);

        // Swipe right to return to Home
        await tester.drag(find.text('Lists Content'), const Offset(300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Home Content'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'CA-11.2: Swipe right on first tab or left on last tab keeps tab unchanged',
      (tester) async {
        // 1. First tab (Home) -> swipe right
        await tester.pumpWidget(buildShellSwipeApp(initialLocation: '/'));
        await tester.pumpAndSettle();

        expect(find.text('Home Content'), findsOneWidget);
        await tester.drag(find.text('Home Content'), const Offset(300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Home Content'), findsOneWidget);
        var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);

        // 2. Last tab (/despesas) -> swipe left
        await tester.pumpWidget(
          buildShellSwipeApp(initialLocation: '/despesas'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Expenses Content'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 4);

        await tester.drag(find.text('Expenses Content'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Expenses Content'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 4);
      },
    );

    testWidgets(
      'CA-11.3: MediaQuery.disableAnimations = true performs immediate cut transition keeping NavigationBar accessible',
      (tester) async {
        await tester.pumpWidget(
          buildShellSwipeApp(initialLocation: '/', disableAnimations: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('Home Content'), findsOneWidget);

        // Swipe left to Shopping/Lists with immediate cut
        await tester.drag(find.text('Home Content'), const Offset(-300, 0));
        await tester.pump();
        expect(find.text('Lists Content'), findsOneWidget);

        // Tap on NavigationBar for Contas
        await tester.tap(find.text('Contas'));
        await tester.pump();
        expect(find.text('Bills Content'), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 3);
      },
    );

    testWidgets(
      'RN-019: TabBarView interna consome gesto enquanto houver sub-aba adjacente e propaga na borda',
      (tester) async {
        // Tarefas starts with TabController on sub-tab 1 (Semana)
        await tester.pumpWidget(
          buildShellSwipeApp(initialLocation: '/tarefas'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sub-aba Semana'), findsOneWidget);
        var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 2);

        // Swipe left from Week: must switch to Month sub-tab and NOT change shell tab
        await tester.fling(
          find.text('Sub-aba Semana'),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('Sub-tab Month'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 2); // Remains in Tarefas

        // On Month sub-tab, swipe left (no sub-tab to left): must advance shell to Bills
        await tester.drag(find.text('Sub-tab Month'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Bills Content'), findsOneWidget);
        expect(find.byType(_TestTabBarPage), findsNothing);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 3);

        // Returns to Tarefas
        await tester.tap(find.text('Tarefas'));
        await tester.pumpAndSettle();
        expect(find.byType(_TestTabBarPage), findsOneWidget);

        // Goes to Day sub-tab
        await tester.tap(find.text('Dia'));
        await tester.pumpAndSettle();
        expect(find.text('Sub-aba Dia'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 2);

        // On Day sub-tab, swipe right (no sub-tab to right): must go back shell to Shopping/Lists
        await tester.drag(find.text('Sub-aba Dia'), const Offset(300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Lists Content'), findsOneWidget);
        navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 1);
      },
    );
  });
}
