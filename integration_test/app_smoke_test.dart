import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/app/app.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/seed_loader.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_page_container.dart';
import 'package:my_sweet_home/features/expenses/presentation/expenses_screen.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app smoke test - traverse all tabs, check dashboard data and persistence (CA-8.2)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.memory();
      const clock = SystemClock();
      final seedLoader = SeedLoader(db, const UuidV7Generator(), clock);
      await seedLoader.loadIfNeeded();

      final now = clock.nowUtc();
      final nowStr = now.toIso8601String();

      // 1. Real expense in current month (R$ 10,00)
      await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: 'exp_smoke_1',
          amountCents: 1000,
          occurredOn: nowStr,
          createdAt: drift.Value(nowStr),
          updatedAt: drift.Value(nowStr),
        ),
      );

      // 2. Tarefa do dia com dueAt preenchido
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 'task_smoke_1',
          title: 'Smoke Test Task',
          dueAt: drift.Value(nowStr),
          isCompleted: const drift.Value(false),
          createdAt: drift.Value(nowStr),
          updatedAt: drift.Value(nowStr),
        ),
      );

      // 3. Conta e pagamento a vencer hoje
      await db.into(db.bills).insert(
        BillsCompanion.insert(
          id: 'bill_smoke_1',
          title: 'Smoke Test Bill',
          amountCents: const drift.Value(5000),
          isAmountVariable: false,
          dueDay: now.day,
        ),
      );
      await db.into(db.billPayments).insert(
        BillPaymentsCompanion.insert(
          id: 'payment_smoke_1',
          billId: const drift.Value('bill_smoke_1'),
          dueOn: nowStr,
          status: 'pending',
        ),
      );

      // Primeiro boot do app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MySweetHomeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Se onboarding for exibido, pula
      final skipButton = find.text('Pular');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // --- 1. Dashboard e dados reais ---
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('My Sweet Home'), findsOneWidget);

      // Current month balance summary (R$ 10,00)
      expect(find.text('R\$ 10,00'), findsWidgets);

      // Contas a vencer
      expect(find.text('Smoke Test Bill'), findsOneWidget);

      // Tarefas do dia
      expect(find.text('Smoke Test Task'), findsOneWidget);

      // Active list (ShoppingListWidget Card)
      expect(find.byKey(const Key('shopping_list_widget_card')), findsOneWidget);

      // --- 2. Shell tab navigation ---
      // Expenses tab
      await tester.tap(find.byIcon(AppIcons.budget).last);
      await tester.pumpAndSettle();
      expect(find.byType(ExpensesScreen), findsOneWidget);

      // Bills tab
      await tester.tap(find.byIcon(AppIcons.bill).last);
      await tester.pumpAndSettle();
      expect(find.byType(BillsPageContainer), findsOneWidget);

      // Tasks tab
      await tester.tap(find.byIcon(AppIcons.tasks).last);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarPage), findsOneWidget);

      // Shopping tab
      await tester.tap(find.byIcon(AppIcons.shopping).last);
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListScreen), findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(AppIcons.home).last);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // --- 3. Settings page accessibility and navigation ---
      final settingsButton = find.byIcon(AppIcons.settings).first;
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Ajustes'), findsWidgets);

      // Return to Dashboard
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
        navigator.pop();
      }
      await tester.pumpAndSettle();

      // --- 4. Data persistence across simulated app restart ---
      // Tear down widget tree simulating process kill
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // Restart app using the same persisted database instance
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MySweetHomeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dashboard loads persisted data
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Smoke Test Bill'), findsOneWidget);
      expect(find.text('Smoke Test Task'), findsOneWidget);
      expect(find.text('R\$ 10,00'), findsWidgets);

      // Desmonta e drena timers de streams do Drift antes de encerrar o teste
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));

      await db.close();
    },
  );
}
