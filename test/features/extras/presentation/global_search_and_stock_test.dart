import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide ShoppingItem, ShoppingList;
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_screen.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_screen.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../../../fakes/fake_bill_payment_repository.dart';
import '../../../fakes/fake_bill_repository.dart';
import '../../../fakes/fake_dashboard_layout_repository.dart';
import '../../../fakes/sequential_id_generator.dart';

class _FakeGlobalSearchController extends ValueNotifier<GlobalSearchState>
    implements GlobalSearchController {
  _FakeGlobalSearchController(super.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async =>
      const Ok(
        MonthSummary(
          month: YearMonth('2026-10'),
          actual: Money(0),
          budget: Money(100000),
          remaining: Money(100000),
          byCategory: [],
          monthsOfHistory: 1,
        ),
      );
}

class _FakeTaskRepo implements TaskRepository {
  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShoppingListRepo implements ShoppingListRepository {
  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SPEC-015 / T-02 — Global Search and Stock by Canonical Name (CA-1.4, CA-1.5)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_food',
              name: 'Alimentação',
              kind: 'expense',
              iconKey: 'restaurant',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildTestApp({
      required String initialLocation,
      required GoRouter router,
      List<dynamic> extraOverrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mascotConfigStreamProvider.overrideWith(
            (ref) => Stream.value(MascotConfig.defaultMomo),
          ),
          monthSummaryRepositoryProvider.overrideWithValue(
            _FakeMonthSummaryRepo(),
          ),
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepo()),
          billRepositoryProvider.overrideWithValue(
            FakeBillRepository(SequentialIdGenerator()),
          ),
          billPaymentRepositoryProvider.overrideWithValue(
            FakeBillPaymentRepository(),
          ),
          shoppingListRepositoryProvider.overrideWithValue(
            _FakeShoppingListRepo(),
          ),
          dashboardLayoutRepositoryProvider.overrideWithValue(
            FakeDashboardLayoutRepository(),
          ),
          ...extraOverrides.cast(),
        ],
        child: MaterialApp.router(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets(
      'CA-1.4: Toque no ícone de busca na Home navega para /busca e tocar em resultado navega para detalhe',
      (tester) async {
        String? navigatedRoute;

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/busca',
              builder: (context, state) => const GlobalSearchScreen(),
            ),
            GoRoute(
              path: '/produtos/:id',
              builder: (context, state) {
                navigatedRoute = '/produtos/${state.pathParameters['id']}';
                return const Scaffold(body: Text('Detalhe do Produto'));
              },
            ),
            GoRoute(
              path: '/receitas/:id',
              builder: (context, state) {
                navigatedRoute = '/receitas/${state.pathParameters['id']}';
                return const Scaffold(body: Text('Detalhe da Receita'));
              },
            ),
          ],
        );

        final searchState = GlobalSearchState(
          query: 'Arroz',
          isLoading: false,
          results: const GlobalSearchResults(
            items: [
              GlobalSearchResult(
                id: 'res-prod-1',
                title: 'Arroz Tipo 1',
                subtitle: 'Alimento',
                type: GlobalSearchResultType.product,
                targetId: 'prod-arroz-1',
              ),
              GlobalSearchResult(
                id: 'res-rec-1',
                title: 'Arroz de Forno',
                subtitle: '30 min',
                type: GlobalSearchResultType.recipe,
                targetId: 'rec-arroz-forno',
              ),
            ],
          ),
        );

        final fakeController = _FakeGlobalSearchController(searchState);

        await tester.pumpWidget(
          buildTestApp(
            initialLocation: '/',
            router: router,
            extraOverrides: [
              globalSearchControllerProvider.overrideWithValue(fakeController),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Check search icon on Home
        expect(find.byKey(const Key('global_search_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('global_search_button')));
        await tester.pumpAndSettle();

        expect(find.byType(GlobalSearchScreen), findsOneWidget);

        // Toca no resultado do produto
        expect(find.text('Arroz Tipo 1'), findsOneWidget);
        await tester.tap(find.text('Arroz Tipo 1'));
        await tester.pumpAndSettle();

        expect(navigatedRoute, '/produtos/prod-arroz-1');

        // Volta para /busca e toca na receita
        router.go('/busca');
        await tester.pumpAndSettle();

        expect(find.text('Arroz de Forno'), findsOneWidget);
        await tester.tap(find.text('Arroz de Forno'));
        await tester.pumpAndSettle();

        expect(navigatedRoute, '/receitas/rec-arroz-forno');

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'CA-1.5: Adicionar item de estoque por nome vincula produto e exibe nome canônico no cartão',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/estoque',
          routes: [
            GoRoute(
              path: '/estoque',
              builder: (context, state) => const StockScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestApp(initialLocation: '/estoque', router: router),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StockScreen), findsOneWidget);

        // Open add dialog
        expect(find.byKey(const Key('add_stock_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('add_stock_button')));
        await tester.pumpAndSettle();

        expect(find.text('Registrar no Estoque'), findsOneWidget);
        expect(find.text('Nome do Produto *'), findsOneWidget);

        // Preenche o nome do produto e a quantidade
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.first, 'Arroz Tipo 1');
        await tester.enterText(textFields.at(1), '3');

        // Salva
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Card now displays "Arroz Tipo 1"
        expect(find.text('Arroz Tipo 1'), findsOneWidget);
        expect(find.textContaining('ID do Produto'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  });
}
