import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_customize_sheet.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_controller.dart';
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
  testWidgets(
    'T-B07: Botão de Ajustes no AppBar do Dashboard possui tooltip e rótulo semântico pt-BR',
    (tester) async {
      final fakeMonthRepo = _FakeMonthSummaryRepo(
        const MonthSummary(
          month: YearMonth('2026-10'),
          actual: Money(0),
          budget: Money(100000),
          remaining: Money(100000),
          byCategory: [],
          monthsOfHistory: 1,
        ),
      );
      final fakeTaskRepo = _FakeTaskRepo([]);
      final fakeBillRepo = FakeBillRepository(SequentialIdGenerator());
      final fakePaymentRepo = FakeBillPaymentRepository();
      final fakeShoppingRepo = _FakeShoppingListRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mascotConfigStreamProvider.overrideWith(
              (ref) => Stream.value(MascotConfig.defaultMomo),
            ),
            monthSummaryRepositoryProvider.overrideWithValue(fakeMonthRepo),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
            billRepositoryProvider.overrideWithValue(fakeBillRepo),
            billPaymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
            shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
          ],
          child: MaterialApp(
            theme: lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsButtonFinder = find.widgetWithIcon(
        IconButton,
        AppIcons.settings,
      );
      expect(settingsButtonFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(settingsButtonFinder);
      expect(iconButton.tooltip, 'Ajustes');

      // Verify TalkBack accessibility/semantics
      expect(find.bySemanticsLabel('Ajustes'), findsOneWidget);
    },
  );

  group(
    'Acessibilidade do Personalizador do Dashboard (RN-376, A11Y-10, CA-3.7)',
    () {
      testWidgets(
        'botões de ação possuem alvos de toque >= 48dp e rótulos semânticos pt-BR',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fakeRepo = FakeDashboardLayoutRepository();
          final controller = DashboardLayoutController(repository: fakeRepo);
          await controller.load();

          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: DashboardCustomizeSheet(controller: controller),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Check "Move up" button of monthBalance
          final moveUpFinder = find.byKey(const Key('move_up_monthBalance'));
          expect(moveUpFinder, findsOneWidget);
          final moveUpSize = tester.getSize(moveUpFinder);
          expect(moveUpSize.width, greaterThanOrEqualTo(Spacing.touchTarget));
          expect(moveUpSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

          // Check "Move down" button of mascotGreeting
          final moveDownFinder = find.byKey(
            const Key('move_down_mascotGreeting'),
          );
          expect(moveDownFinder, findsOneWidget);
          final moveDownSize = tester.getSize(moveDownFinder);
          expect(moveDownSize.width, greaterThanOrEqualTo(Spacing.touchTarget));
          expect(
            moveDownSize.height,
            greaterThanOrEqualTo(Spacing.touchTarget),
          );

          // Check "Hide" button of dueBills
          final hideFinder = find.byKey(const Key('hide_dueBills'));
          expect(hideFinder, findsOneWidget);
          final hideSize = tester.getSize(hideFinder);
          expect(hideSize.width, greaterThanOrEqualTo(Spacing.touchTarget));
          expect(hideSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

          // Check "Add" button of stockAlert
          final addFinder = find.byKey(const Key('add_stockAlert'));
          expect(addFinder, findsOneWidget);
          final addSize = tester.getSize(addFinder);
          expect(addSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

          // Check semantic labels
          expect(
            find.bySemanticsLabel('Mover Saldo do Mês para cima'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel('Mover Saudação da Momo para baixo'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel('Ocultar Contas a Vencer'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
              RegExp(r'Adicionar Estoque Doméstico ao painel'),
            ),
            findsOneWidget,
          );

          controller.dispose();
        },
      );
    },
  );
}
