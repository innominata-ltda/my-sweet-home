import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_customize_sheet.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_providers.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../../fakes/fake_bill_payment_repository.dart';
import '../../fakes/fake_bill_repository.dart';
import '../../fakes/fake_dashboard_layout_repository.dart';
import '../../fakes/sequential_id_generator.dart';

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  MonthSummary summary;
  _FakeMonthSummaryRepo(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async =>
      Ok(summary);
}

class _FakeTaskRepo implements TaskRepository {
  List<task_models.Task> tasks;
  _FakeTaskRepo(this.tasks);

  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async => Ok(tasks);

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
  late FakeDashboardLayoutRepository fakeLayoutRepo;
  late _FakeMonthSummaryRepo fakeMonthRepo;
  late _FakeTaskRepo fakeTaskRepo;
  late FakeBillRepository fakeBillRepo;
  late FakeBillPaymentRepository fakePaymentRepo;
  late _FakeShoppingListRepo fakeShoppingRepo;

  setUp(() {
    fakeLayoutRepo = FakeDashboardLayoutRepository();
    fakeMonthRepo = _FakeMonthSummaryRepo(
      const MonthSummary(
        month: YearMonth('2026-10'),
        actual: Money(0),
        budget: Money(100000),
        remaining: Money(100000),
        byCategory: [],
        monthsOfHistory: 1,
      ),
    );
    fakeTaskRepo = _FakeTaskRepo([]);
    fakeBillRepo = FakeBillRepository(SequentialIdGenerator());
    fakePaymentRepo = FakeBillPaymentRepository();
    fakeShoppingRepo = _FakeShoppingListRepo();
  });

  Widget buildDashboard({DashboardLayoutConfig? initialConfig}) {
    if (initialConfig != null) {
      fakeLayoutRepo = FakeDashboardLayoutRepository(
        initialConfig: initialConfig,
      );
    }
    return ProviderScope(
      overrides: [
        mascotConfigStreamProvider.overrideWith(
          (ref) => Stream.value(MascotConfig.defaultMomo),
        ),
        monthSummaryRepositoryProvider.overrideWithValue(fakeMonthRepo),
        taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        billRepositoryProvider.overrideWithValue(fakeBillRepo),
        billPaymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
        shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
        dashboardLayoutRepositoryProvider.overrideWithValue(fakeLayoutRepo),
      ],
      child: MaterialApp(
        theme: lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DashboardScreen(),
      ),
    );
  }

  group(
    'Personalização do Dashboard (RF-105, RN-372, CA-3.3, CA-3.4, CA-3.6)',
    () {
      testWidgets(
        'botão Personalizar início no AppBar abre a folha de personalização',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildDashboard());
          await tester.pumpAndSettle();

          final customizeButton = find.byKey(
            const Key('customize_dashboard_button'),
          );
          expect(customizeButton, findsOneWidget);

          await tester.tap(customizeButton);
          await tester.pumpAndSettle();

          expect(find.byType(DashboardCustomizeSheet), findsOneWidget);
          expect(find.text('Personalizar início'), findsOneWidget);
        },
      );

      testWidgets(
        'CA-3.3: mover todayTasks para o topo reflete imediatamente no painel',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildDashboard());
          await tester.pumpAndSettle();

          // Abrir sheet
          await tester.tap(find.byKey(const Key('customize_dashboard_button')));
          await tester.pumpAndSettle();

          // Move todayTasks up successively to top
          await tester.tap(find.byKey(const Key('move_up_todayTasks')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('move_up_todayTasks')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('move_up_todayTasks')));
          await tester.pumpAndSettle();

          // Fechar modal
          Navigator.of(tester.element(find.byType(DashboardCustomizeSheet)))
              .pop();
          await tester.pumpAndSettle();

          // Verify repository persisted todayTasks at top
          final loaded = await fakeLayoutRepo.load();
          expect(
            loaded.valueOrNull!.visibleItems.first,
            DashboardItemKind.todayTasks,
          );
        },
      );

      testWidgets(
        'CA-3.4: ocultar cards remove-os do Dashboard; readicionar restaura exibição',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildDashboard());
          await tester.pumpAndSettle();

          // Initially due to defaultOrder, dueBills and mascotGreeting are visible
          expect(
            find.byKey(const Key('due_bills_widget_card')),
            findsOneWidget,
          );

          // Abrir sheet
          await tester.tap(find.byKey(const Key('customize_dashboard_button')));
          await tester.pumpAndSettle();

          // Ocultar dueBills e mascotGreeting
          await tester.tap(find.byKey(const Key('hide_dueBills')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('hide_mascotGreeting')));
          await tester.pumpAndSettle();

          // Now both should appear in hidden section with add buttons
          expect(find.byKey(const Key('add_dueBills')), findsOneWidget);
          expect(find.byKey(const Key('add_mascotGreeting')), findsOneWidget);

          // Fechar sheet
          Navigator.of(tester.element(find.byType(DashboardCustomizeSheet)))
              .pop();
          await tester.pumpAndSettle();

          // dueBills no longer appears in Dashboard
          expect(find.byKey(const Key('due_bills_widget_card')), findsNothing);

          // Reabrir sheet e readicionar dueBills
          await tester.tap(find.byKey(const Key('customize_dashboard_button')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('add_dueBills')));
          await tester.pumpAndSettle();

          Navigator.of(tester.element(find.byType(DashboardCustomizeSheet)))
              .pop();
          await tester.pumpAndSettle();

          // dueBills voltou a ser exibido
          expect(
            find.byKey(const Key('due_bills_widget_card')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'CA-3.6: ocultar todos os cards exibe AppEmptyState e Restaurar padrão recupera os 5 itens',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          // Iniciar com todos os itens ocultos
          await tester.pumpWidget(
            buildDashboard(
              initialConfig: const DashboardLayoutConfig(visibleItems: []),
            ),
          );
          await tester.pumpAndSettle();

          // Empty State visible with CTA
          expect(
            find.byKey(const Key('dashboard_empty_state')),
            findsOneWidget,
          );
          expect(find.text('Nenhum item visível no painel'), findsOneWidget);
          expect(find.text('Adicionar itens ao painel'), findsOneWidget);

          // Clicking empty state button opens customizer
          await tester.tap(find.text('Adicionar itens ao painel'));
          await tester.pumpAndSettle();

          expect(find.byType(DashboardCustomizeSheet), findsOneWidget);

          // Click "Restore default"
          final restoreButton = find.byKey(const Key('restore_default_button'));
          expect(restoreButton, findsOneWidget);
          await tester.tap(restoreButton);
          await tester.pumpAndSettle();

          // Fechar sheet
          Navigator.of(tester.element(find.byType(DashboardCustomizeSheet)))
              .pop();
          await tester.pumpAndSettle();

          // Dashboard now displays 5 default cards again (empty state gone)
          expect(find.byKey(const Key('dashboard_empty_state')), findsNothing);
          expect(
            find.byKey(const Key('due_bills_widget_card')),
            findsOneWidget,
          );

          final loaded = await fakeLayoutRepo.load();
          expect(
            loaded.valueOrNull!.visibleItems,
            DashboardLayoutConfig.defaultOrder,
          );
        },
      );
    },
  );
}
