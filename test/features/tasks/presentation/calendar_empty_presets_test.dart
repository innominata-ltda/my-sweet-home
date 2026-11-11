import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

import '../../../fakes/fake_clock.dart';

class _FakeTaskRepo implements TaskRepository {
  _FakeTaskRepo({List<Task>? initialTasks}) : tasks = initialTasks ?? <Task>[];

  final List<Task> tasks;

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async {
    return Ok(List.unmodifiable(tasks));
  }

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async => Ok(tasks);

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async =>
      const Ok(null);

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async => Ok(task);

  @override
  Future<Result<Task, Failure>> complete(TaskId id) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) =>
      throw UnimplementedError();

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) => throw UnimplementedError();

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) =>
      throw UnimplementedError();

  @override
  Future<Result<Task, Failure>> upsert(NewTask task) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() =>
      throw UnimplementedError();
}

void main() {
  late FakeClock clock;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 3, 10));
  });

  group(
    'CA-5.1: Lista de tarefas vazia convida a ver o catálogo de predefinições',
    () {
      testWidgets(
        'When tasks empty, displays invite and navigates to catalog on tap',
        (tester) async {
          final repo = _FakeTaskRepo(initialTasks: []);
          String? navigatedRoute;

          final router = GoRouter(
            initialLocation: '/tarefas',
            routes: [
              GoRoute(
                path: '/tarefas',
                builder: (context, state) => const CalendarPage(),
              ),
              GoRoute(
                path: '/tarefas/sugestoes',
                builder: (context, state) {
                  navigatedRoute = '/tarefas/sugestoes';
                  return const Scaffold(body: Text('Catálogo de Sugestões'));
                },
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                taskRepositoryProvider.overrideWithValue(repo),
                clockProvider.overrideWithValue(clock),
                calendarBillsProvider.overrideWith(
                  (ref, monthDate) => const Stream.empty(),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                locale: const Locale('pt', 'BR'),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('pt', 'BR')],
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify prompt and button appear
          expect(
            find.text('Que tal ver sugestões para a rotina da sua casa?'),
            findsOneWidget,
          );
          final buttonFinder = find.text('Ver sugestões para a casa');
          expect(buttonFinder, findsOneWidget);

          // Tap button
          await tester.tap(buttonFinder);
          await tester.pumpAndSettle();

          // Navegou para /tarefas/sugestoes
          expect(navigatedRoute, '/tarefas/sugestoes');
          expect(find.text('Catálogo de Sugestões'), findsOneWidget);
        },
      );

      testWidgets('When tasks are NOT empty, invite is not displayed', (
        tester,
      ) async {
        final existingTask = Task(
          id: 'task-1',
          title: 'Lavar roupa',
          dueAt: DateTime.utc(2026, 3, 10),
          allDay: true,
          isCompleted: false,
          syncState: SyncState.synced,
          createdAt: DateTime.utc(2026, 3, 10),
          updatedAt: DateTime.utc(2026, 3, 10),
        );
        final repo = _FakeTaskRepo(initialTasks: [existingTask]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskRepositoryProvider.overrideWithValue(repo),
              clockProvider.overrideWithValue(clock),
              calendarBillsProvider.overrideWith(
                (ref, monthDate) => const Stream.empty(),
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
              supportedLocales: [Locale('pt', 'BR')],
              home: CalendarPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Prompt and suggestions button should not appear
        expect(
          find.text('Que tal ver sugestões para a rotina da sua casa?'),
          findsNothing,
        );
        expect(find.text('Ver sugestões para a casa'), findsNothing);
      });
    },
  );
}
