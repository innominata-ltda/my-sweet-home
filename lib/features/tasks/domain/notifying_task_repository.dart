import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/domain/task_reminder_planner.dart';

class NotifyingTaskRepository implements TaskRepository {
  final TaskRepository inner;
  final NotificationSchedulerPort scheduler;
  final TaskReminderPlanner planner;
  final Clock clock;
  final QuietHours quietHours;

  const NotifyingTaskRepository({
    required this.inner,
    required this.scheduler,
    required this.planner,
    required this.clock,
    this.quietHours = const QuietHours(),
  });

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    final result = await inner.upsert(t);
    if (result.isOk) {
      final task = result.valueOrNull!;
      await _scheduleFor(task);
    }
    return result;
  }

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    final before = clock.nowUtc();
    final result = await inner.complete(id);
    if (result.isOk) {
      final task = result.valueOrNull!;
      await scheduler.cancel('task_${task.id}');

      if (task.recurringRuleId != null) {
        final dirtiesResult = await inner.dirtySince(before);
        if (dirtiesResult.isOk) {
          final dirties = dirtiesResult.valueOrNull!;
          for (final dirty in dirties) {
            if (dirty.recurringRuleId == task.recurringRuleId &&
                !dirty.isCompleted &&
                dirty.id != task.id) {
              await _scheduleFor(dirty);
            }
          }
        }
      }
    }
    return result;
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    final result = await inner.uncomplete(id);
    if (result.isOk) {
      final task = result.valueOrNull!;
      await _scheduleFor(task);
    }
    return result;
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    final result = await inner.remove(id, alsoRemote: alsoRemote);
    if (result.isOk) {
      await scheduler.cancel('task_$id');
    }
    return result;
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) =>
      inner.inRange(r);

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() =>
      inner.withoutDueDate();

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) =>
      inner.dirtySince(mark);

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() =>
      inner.allTasksForSync();

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) =>
      inner.saveSyncedTask(task);

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) =>
      inner.deleteLocalPermanently(id);

  Future<void> _scheduleFor(Task task) async {
    await scheduler.cancel('task_${task.id}');
    final notifications = planner.plan(
      task: task,
      now: clock.nowUtc(),
      quiet: quietHours,
    );
    for (final n in notifications) {
      await scheduler.schedule(n);
    }
  }
}
