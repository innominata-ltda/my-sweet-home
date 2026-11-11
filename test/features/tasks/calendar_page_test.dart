import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';

// Fake Repository para o teste
class FakeTaskRepository implements TaskRepository {
  final List<Task> tasks = [];

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    final task = Task(
      id: 'fake_id',
      title: t.title,
      allDay: t.allDay,
      dueAt: t.dueAt,
      isCompleted: false,
      syncState: SyncState.synced,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    tasks.add(task);
    return Ok(task);
  }

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(isCompleted: true);
      tasks[idx] = updated;
      return Ok(updated);
    }
    throw UnimplementedError();
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(isCompleted: false);
      tasks[idx] = updated;
      return Ok(updated);
    }
    throw UnimplementedError();
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    tasks.removeWhere((t) => t.id == id);
    return Ok(TrashTicket(table: 'tasks', id: id, deletedAt: DateTime.now()));
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async {
    return Ok(tasks);
  }

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async {
    return Ok([]);
  }

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async {
    return Ok([]);
  }

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async {
    return Ok(tasks);
  }

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async {
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
    return Ok(task);
  }

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async {
    tasks.removeWhere((t) => t.id == id);
    return const Ok(null);
  }
}

class FakeClock implements Clock {
  final DateTime _now;
  FakeClock(this._now);

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime todayUtc() => DateTime.utc(_now.year, _now.month, _now.day);
}

void main() {
  testWidgets('Create task from calendar day (T-05)', (tester) async {
    final repo = FakeTaskRepository();
    final clock = FakeClock(DateTime.utc(2023, 10, 15));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(clock),
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
          home: const CalendarPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FAB is present
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    // Click FAB to open QuickAddTaskSheet
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify Title text field is present
    expect(find.byType(TextField), findsOneWidget);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Nova Tarefa Teste');
    await tester.pump();

    // Click Save
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify task was added to repository
    expect(repo.tasks.length, 1);
    expect(repo.tasks.first.title, 'Nova Tarefa Teste');
    // Verify it was added to the currently focused date (today by default)
    expect(repo.tasks.first.dueAt, DateTime.utc(2023, 10, 15));
    expect(repo.tasks.first.allDay, isTrue);

    // Now test picking another date from month view
    // Go to month view
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();

    // Click on day 10
    // Wait, day 10 is visible on the calendar
    await tester.tap(find.text('10').first);
    await tester.pumpAndSettle();

    // Now we are back in Day view
    // Click FAB
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Enter text
    await tester.enterText(find.byType(TextField), 'Tarefa Dia 10');
    await tester.pump();

    // Click Save
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Verify task was added for day 10
    expect(repo.tasks.length, 2);
    expect(repo.tasks.last.title, 'Tarefa Dia 10');
    expect(repo.tasks.last.dueAt, DateTime.utc(2023, 10, 10));
  });
}
