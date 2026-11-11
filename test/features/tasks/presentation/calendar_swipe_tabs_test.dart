import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task;
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';
import 'package:my_sweet_home/features/tasks/presentation/day_view.dart';
import 'package:my_sweet_home/features/tasks/presentation/month_view.dart';
import 'package:my_sweet_home/features/tasks/presentation/week_view.dart';

import '../../../fakes/fake_clock.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async =>
      throw UnimplementedError();

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async =>
      throw UnimplementedError();

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async =>
      throw UnimplementedError();

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async =>
      Ok(tasks);

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async => Ok([]);

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async =>
      Ok([]);

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async => Ok(tasks);

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async => Ok(task);

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async =>
      const Ok(null);
}

void main() {
  late AppDatabase db;
  late FakeTaskRepository repo;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase.memory();
    repo = FakeTaskRepository();
    clock = FakeClock(DateTime.utc(2026, 10, 15));
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        taskRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(clock),
        calendarBillsProvider.overrideWith(
          (ref, monthDate) => Stream.value([]),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
        home: CalendarPage(),
      ),
    );
  }

  group('SPEC-007 / T-B18 — Horizontal swipe between calendar views (RN-164, CA-6.2)', () {
    testWidgets(
      'CA-6.2: Swipe left a partir de Dia alterna para Semana e depois para Mês mantendo TabBar sincronizada',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Initially in Day view (index 0)
        final tabBarFinder = find.byType(TabBar);
        expect(tabBarFinder, findsOneWidget);
        var tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(0));
        expect(find.byType(DayView), findsOneWidget);

        // 2. Swipe left on TabBarView area
        final tabBarViewFinder = find.byType(TabBarView);
        expect(tabBarViewFinder, findsOneWidget);

        await tester.fling(tabBarViewFinder, const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();

        // 3. Now in Week view (index 1)
        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(1));
        expect(find.byType(WeekView), findsOneWidget);

        // 4. Mais um swipe left
        await tester.fling(tabBarViewFinder, const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();

        // 5. Now in Month view (index 2)
        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(2));
        expect(find.byType(MonthView), findsOneWidget);
      },
    );

    testWidgets(
      'CA-6.2: Swipe right a partir de Mês alterna para Semana e depois para Dia mantendo TabBar sincronizada',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final tabBarFinder = find.byType(TabBar);
        final tabBarViewFinder = find.byType(TabBarView);

        // Go to Month view by tapping Month tab
        await tester.tap(find.text('Mês'));
        await tester.pumpAndSettle();

        var tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(2));
        expect(find.byType(MonthView), findsOneWidget);

        // Swipe right para voltar para Semana
        await tester.fling(tabBarViewFinder, const Offset(400, 0), 1000);
        await tester.pumpAndSettle();

        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(1));
        expect(find.byType(WeekView), findsOneWidget);

        // Swipe right para voltar para Dia
        await tester.fling(tabBarViewFinder, const Offset(400, 0), 1000);
        await tester.pumpAndSettle();

        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(0));
        expect(find.byType(DayView), findsOneWidget);
      },
    );

    testWidgets(
      'A11Y-10: Botões da TabBar (Dia, Semana, Mês) continuam acessíveis por toque alternativo ao gesto de swipe',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final tabBarFinder = find.byType(TabBar);

        // Toca em Semana
        await tester.tap(find.text('Semana'));
        await tester.pumpAndSettle();

        var tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(1));
        expect(find.byType(WeekView), findsOneWidget);

        // Tap Month
        await tester.tap(find.text('Mês'));
        await tester.pumpAndSettle();

        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(2));
        expect(find.byType(MonthView), findsOneWidget);

        // Toca em Dia
        await tester.tap(find.text('Dia'));
        await tester.pumpAndSettle();

        tabController = tester.widget<TabBar>(tabBarFinder).controller;
        expect(tabController?.index, equals(0));
        expect(find.byType(DayView), findsOneWidget);
      },
    );

    testWidgets(
      'RN-164: Quando no extremo Dia (deslizando à direita), o gesto propaga para PageView pai',
      (tester) async {
        final outerController = PageController(initialPage: 1);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              taskRepositoryProvider.overrideWithValue(repo),
              clockProvider.overrideWithValue(clock),
              calendarBillsProvider.overrideWith(
                (ref, monthDate) => Stream.value([]),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
              home: Scaffold(
                body: PageView(
                  controller: outerController,
                  children: const [
                    Text('Aba Anterior Shell'),
                    CalendarPage(),
                    Text('Aba Próxima Shell'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CalendarPage), findsOneWidget);
        expect(outerController.page, equals(1.0));

        // In Day view (far left of calendar sub-tabs):
        // Swipe right should propagate to shell and switch tab
        await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
        await tester.pumpAndSettle();

        expect(outerController.page, equals(0.0));
        expect(find.text('Aba Anterior Shell'), findsOneWidget);
      },
    );

    testWidgets(
      'RN-164: Quando no extremo Mês (deslizando à esquerda), o gesto propaga para PageView pai',
      (tester) async {
        final outerController = PageController(initialPage: 1);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              taskRepositoryProvider.overrideWithValue(repo),
              clockProvider.overrideWithValue(clock),
              calendarBillsProvider.overrideWith(
                (ref, monthDate) => Stream.value([]),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
              home: Scaffold(
                body: PageView(
                  controller: outerController,
                  children: const [
                    Text('Aba Anterior Shell'),
                    CalendarPage(),
                    Text('Aba Próxima Shell'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Week view and then Month via swipe
        await tester.fling(
          find.byType(TabBarView),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(TabBarView),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        final tabController = tester
            .widget<TabBar>(find.byType(TabBar))
            .controller;
        expect(tabController?.index, equals(2));

        // In Month view (far right of calendar sub-tabs):
        // Swipe left should propagate to shell and go to "Next Shell Tab"
        await tester.fling(
          find.byType(TabBarView),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(outerController.page, equals(2.0));
        expect(find.text('Aba Próxima Shell'), findsOneWidget);
      },
    );
  });
}
