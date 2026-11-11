library;

import '../../../../core/notifications/notification_scheduler_port.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/domain/derived_data_rebuilder.dart';
import '../../../../core/time/clock.dart';
import '../../../../data/database/database.dart';
import '../../domain/models.dart' as domain;
import '../../domain/task_reminder_planner.dart';

/// Reschedules or cancels task notifications after sync batch application (RN-327).
final class TasksDerivedDataRebuilder implements DerivedDataRebuilder {
  final AppDatabase db;
  final NotificationSchedulerPort scheduler;
  final TaskReminderPlanner planner;
  final Clock clock;

  const TasksDerivedDataRebuilder({
    required this.db,
    required this.scheduler,
    this.planner = const DefaultTaskReminderPlanner(),
    this.clock = const SystemClock(),
  });

  @override
  Set<String> get watchesTables => const {'tasks'};

  @override
  Future<Result<void, Failure>> rebuild(Set<String> touchedRowIds) async {
    try {
      final now = clock.nowLocal();
      const quiet = QuietHours();

      final query = db.select(db.tasks);
      if (touchedRowIds.isNotEmpty) {
        query.where((tbl) => tbl.id.isIn(touchedRowIds));
      }

      final tasks = await query.get();

      for (final t in tasks) {
        // If task was completed, deleted or has no due date
        if (t.isCompleted || t.deletedAt != null || t.dueAt == null) {
          await scheduler.cancel('task_${t.id}');
          continue;
        }

        final domainTask = domain.Task(
          id: t.id,
          title: t.title,
          notes: t.notes,
          dueAt: t.dueAt != null ? DateTime.parse(t.dueAt!) : null,
          allDay: t.allDay,
          isCompleted: t.isCompleted,
          completedAt: t.completedAt != null
              ? DateTime.parse(t.completedAt!)
              : null,
          recurringRuleId: t.recurringRuleId,
          remoteEventId: t.remoteEventId,
          remoteEtag: t.remoteEtag,
          syncState: t.syncState != null
              ? domain.SyncState.values.firstWhere(
                  (e) => e.name == t.syncState,
                  orElse: () => domain.SyncState.synced,
                )
              : domain.SyncState.synced,
          sourcePresetId: t.sourcePresetId,
          createdAt: t.createdAt != null
              ? DateTime.parse(t.createdAt!)
              : clock.nowUtc(),
          updatedAt: t.updatedAt != null
              ? DateTime.parse(t.updatedAt!)
              : clock.nowUtc(),
          deletedAt: t.deletedAt != null ? DateTime.parse(t.deletedAt!) : null,
        );

        final notifications = planner.plan(
          task: domainTask,
          now: now,
          quiet: quiet,
        );

        for (final n in notifications) {
          await scheduler.schedule(n);
        }
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao reagendar notificações de tarefas: $e',
          cause: e,
        ),
      );
    }
  }
}
