import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../fakes/fake_bill_payment_repository.dart';
import '../fakes/fake_bill_repository.dart';
import '../fakes/sequential_id_generator.dart';

// -----------------------------------------------------------------------------
// Fakes for Dashboard repositories
// -----------------------------------------------------------------------------

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
  Future<Result<task_models.Task, Failure>> complete(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  Future<Result<task_models.Task, Failure>> uncomplete(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  Future<Result<task_models.Task, Failure>> upsert(
    task_models.NewTask t,
  ) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShoppingListRepo implements ShoppingListRepository {
  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async => const Ok([]);

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async => const Ok(null);
}

void main() {
  group('Dashboard Momo & Softening (CA-110.6, CA-289.1, RN-284, RN-293)', () {
    late _FakeMonthSummaryRepo fakeMonthRepo;
    late _FakeTaskRepo fakeTaskRepo;
    late BillRepository fakeBillRepo;
    late BillPaymentRepository fakePaymentRepo;
    late _FakeShoppingListRepo fakeShoppingRepo;

    final testMonth = YearMonth('2026-10');

    Widget createTestDashboard({
      MascotConfig config = MascotConfig.defaultMomo,
      ThemeData? theme,
    }) {
      return ProviderScope(
        overrides: [
          mascotConfigStreamProvider.overrideWith(
            (ref) => Stream.value(config),
          ),
          monthSummaryRepositoryProvider.overrideWithValue(fakeMonthRepo),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          billRepositoryProvider.overrideWithValue(fakeBillRepo),
          billPaymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
        ],
        child: MaterialApp(
          theme: theme ?? lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
      );
    }

    setUp(() {
      fakeMonthRepo = _FakeMonthSummaryRepo(
        MonthSummary(
          month: testMonth,
          actual: const Money(45000),
          budget: const Money(100000),
          remaining: const Money(55000),
          byCategory: const [],
          monthsOfHistory: 1,
        ),
      );
      fakeTaskRepo = _FakeTaskRepo([]);
      fakeBillRepo = FakeBillRepository(SequentialIdGenerator());
      fakePaymentRepo = FakeBillPaymentRepository();
      fakeShoppingRepo = _FakeShoppingListRepo();
    });

    testWidgets(
      'CA-110.6: Dashboard displays Momo, welcoming speech bubble, and softened titles',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestDashboard());
        await tester.pumpAndSettle();

        // 1. Momo present in dedicated area (welcoming speech bubble)
        expect(
          find.byKey(const Key('dashboard_mascot_greeting_card')),
          findsOneWidget,
        );
        expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);

        // 2. Momo present in month balance card
        expect(find.byKey(const Key('month_balance_mascot')), findsOneWidget);

        // 3. Softened titles per specification
        expect(find.text('Seu dinheirinho este mês'), findsOneWidget);
        expect(find.text('Contas que precisam de carinho'), findsOneWidget);
        expect(find.text('Tarefinhas do dia'), findsOneWidget);
      },
    );

    testWidgets(
      'RN-293: Momo displays worried expression in card and bubble when budget is exceeded',
      (tester) async {
        // Over-budget (spent 1,200 of 1,000, negative remaining)
        fakeMonthRepo.summary = MonthSummary(
          month: testMonth,
          actual: const Money(120000),
          budget: const Money(100000),
          remaining: const Money(-20000),
          byCategory: const [],
          monthsOfHistory: 1,
        );

        await tester.pumpWidget(createTestDashboard());
        await tester.pumpAndSettle();

        // Verifies caring contextual notice in speech bubble
        expect(
          find.text(
            'Atenção com as continhas este mês! Mas estamos juntas nisso 💕',
          ),
          findsOneWidget,
        );

        // Verifies mascot widget in balance card has worried expression
        final balanceMascotFinder = find.descendant(
          of: find.byKey(const Key('month_balance_mascot')),
          matching: find.byType(MascotWidget),
        );
        expect(balanceMascotFinder, findsOneWidget);
        final mascot = tester.widget<MascotWidget>(balanceMascotFinder);
        expect(mascot.expression, MascotExpression.worried);
      },
    );

    testWidgets(
      'RN-283: Completion of all daily tasks reflects caring time-off message',
      (tester) async {
        final now = DateTime.utc(2026, 10, 20);
        fakeTaskRepo.tasks = [
          task_models.Task(
            id: 't1',
            title: 'Limpar cozinha',
            allDay: true,
            isCompleted: true,
            completedAt: now,
            syncState: task_models.SyncState.synced,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(createTestDashboard());
        await tester.pumpAndSettle();

        // Relaxed expression with welcoming time-off text
        expect(find.text('Hoje pode ser um dia de folga ☕'), findsOneWidget);
      },
    );

    testWidgets(
      'CA-289.1: TalkBack announces greeting and Momo presence with complete semantics in pt-BR',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(createTestDashboard());
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            'Mascote Momo: Oi! Eu sou a Momo 💕. Estou aqui para cuidar do seu cantinho com você!',
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'CA-110.3: Mascot greeting and speeches use configured custom name',
      (tester) async {
        const customConfig = MascotConfig(
          animal: MascotAnimal.dog,
          palette: MascotPalette.lavender,
          accessory: MascotAccessory.collar,
          name: 'Pipoca',
        );

        await tester.pumpWidget(createTestDashboard(config: customConfig));
        await tester.pumpAndSettle();

        expect(find.text('Oi! Eu sou a Pipoca 💕'), findsOneWidget);
      },
    );

    testWidgets('CA-285.2: Home layout stable with textScaleFactor 2.0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: createTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard_mascot_greeting_card')),
        findsOneWidget,
      );
      expect(find.text('Seu dinheirinho este mês'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
