import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/notifying_task_repository.dart';
import 'package:my_sweet_home/features/tasks/domain/task_reminder_planner.dart';

import '../../fakes/recording_scheduler.dart';

import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

class FakeTaskRepository implements TaskRepository {
  Task? upsertReturn;
  Task? completeReturn;
  Task? uncompleteReturn;
  List<Task>? dirtySinceReturn;
  TrashTicket? removeReturn;

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    return Ok(completeReturn!);
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    return Ok(uncompleteReturn ?? completeReturn!);
  }

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async {
    return Ok(dirtySinceReturn!);
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    return Ok(
      removeReturn ??
          TrashTicket(table: 'tasks', id: 't_1', deletedAt: DateTime.now()),
    );
  }

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    return Ok(upsertReturn!);
  }

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async {
    return Ok([]);
  }

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async {
    return Ok(task);
  }

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async {
    return const Ok(null);
  }
}

void main() {
  late FakeTaskRepository inner;
  late RecordingScheduler scheduler;
  late Clock clock;
  late TaskReminderPlanner planner;
  late NotifyingTaskRepository repository;

  setUp(() {
    inner = FakeTaskRepository();
    scheduler = RecordingScheduler();
    clock = SystemClock();
    planner = const DefaultTaskReminderPlanner();

    repository = NotifyingTaskRepository(
      inner: inner,
      scheduler: scheduler,
      planner: planner,
      clock: clock,
    );
  });

  test('upsert schedules notification for new task', () async {
    final newTask = NewTask(
      title: 'Comprar leite',
      dueAt: clock.nowUtc().add(const Duration(hours: 5)),
      allDay: false,
    );

    final returnedTask = Task(
      id: 'task_1',
      title: 'Comprar leite',
      allDay: false,
      isCompleted: false,
      dueAt: newTask.dueAt,
      syncState: SyncState.dirty,
      createdAt: clock.nowUtc(),
      updatedAt: clock.nowUtc(),
    );

    inner.upsertReturn = returnedTask;

    final result = await repository.upsert(newTask);

    expect(result.isOk, isTrue);
    expect(scheduler.scheduled.length, 1);
    expect(scheduler.scheduled.first.id, 'task_task_1');
  });

  test(
    'complete cancels notification and schedules for new recurring task',
    () async {
      final taskId = 'task_1';
      final completedTask = Task(
        id: taskId,
        title: 'Tomar remÃ©dio',
        allDay: false,
        isCompleted: true,
        recurringRuleId: 'rule_1',
        syncState: SyncState.dirty,
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      );

      final newTask = Task(
        id: 'task_2',
        title: 'Tomar remÃ©dio',
        allDay: false,
        isCompleted: false,
        dueAt: clock.nowUtc().add(const Duration(days: 1)),
        recurringRuleId: 'rule_1',
        syncState: SyncState.dirty,
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      );

      inner.completeReturn = completedTask;
      inner.dirtySinceReturn = [newTask];

      // Let's pretend there was already a notification for task_1
      await scheduler.schedule(mySweetHomeNotificationDummy(id: 'task_task_1'));

      final result = await repository.complete(taskId);

      expect(result.isOk, isTrue);

      // task_task_1 should be cancelled, task_task_2 scheduled
      expect(scheduler.scheduled.length, 1);
      expect(scheduler.scheduled.first.id, 'task_task_2');
    },
  );

  test('remove cancels notification', () async {
    final taskId = 'task_1';

    // Dummy schedule
    await scheduler.schedule(mySweetHomeNotificationDummy(id: 'task_task_1'));

    await repository.remove(taskId, alsoRemote: true);

    expect(scheduler.scheduled.isEmpty, isTrue);
  });
}

ScheduledNotification mySweetHomeNotificationDummy({required String id}) {
  return ScheduledNotification(
    id: id,
    title: 'title',
    body: 'body',
    scheduledAt: DateTime.now().add(const Duration(hours: 1)),
  );
}
