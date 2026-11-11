import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

class QuietHours {
  final int startHour;
  final int endHour;
  final int pushToHour;

  const QuietHours({
    this.startHour = 22,
    this.endHour = 7,
    this.pushToHour = 8,
  });

  /// Adjusts time if it falls in night quiet window (RN-152).
  DateTime adjust(DateTime dt) {
    if (dt.hour >= startHour || dt.hour < endHour) {
      final targetDate = dt.hour >= startHour
          ? dt.add(const Duration(days: 1))
          : dt;
      return DateTime.utc(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        pushToHour,
        dt.minute,
      );
    }
    return dt;
  }
}

abstract interface class TaskReminderPlanner {
  List<ScheduledNotification> plan({
    required Task task,
    required DateTime now,
    required QuietHours quiet,
  });
}

class DefaultTaskReminderPlanner implements TaskReminderPlanner {
  const DefaultTaskReminderPlanner();

  @override
  List<ScheduledNotification> plan({
    required Task task,
    required DateTime now,
    required QuietHours quiet,
  }) {
    if (task.isCompleted || task.isDeleted || task.dueAt == null) {
      return const [];
    }

    final notifications = <ScheduledNotification>[];
    DateTime targetTime;

    if (task.allDay) {
      targetTime = DateTime.utc(
        task.dueAt!.year,
        task.dueAt!.month,
        task.dueAt!.day,
        9, // Default to 9:00 AM for all-day tasks
      );
    } else {
      targetTime = task.dueAt!;
    }

    final scheduledTime = quiet.adjust(targetTime);

    if (scheduledTime.isAfter(now)) {
      notifications.add(
        ScheduledNotification(
          id: 'task_${task.id}',
          title: 'Lembrete de Tarefa',
          body: task.title,
          scheduledAt: scheduledTime,
        ),
      );
    }

    return notifications;
  }
}
