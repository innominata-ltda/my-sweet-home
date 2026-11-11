import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';

import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';

class QuietHours {
  final int startHour;
  final int endHour;
  final int pushToHour;

  const QuietHours({
    this.startHour = 22,
    this.endHour = 7,
    this.pushToHour = 8,
  });

  /// Adjusts time if falling within night silence window (RN-140).
  /// Espera e retorna Data/Hora locais.
  DateTime adjust(DateTime dt) {
    if (dt.hour >= startHour || dt.hour < endHour) {
      final targetDate = dt.hour >= startHour
          ? dt.add(const Duration(days: 1))
          : dt;
      return DateTime(
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

/// PURE. Takes occurrence and returns schedules; does not schedule anything.
abstract interface class ReminderPlanner {
  List<ScheduledNotification> plan({
    required BillPayment payment,
    required String billTitle,
    required int daysBefore,
    required DateTime now,
    required QuietHours quiet,
  });
}

class DefaultReminderPlanner implements ReminderPlanner {
  const DefaultReminderPlanner();

  @override
  List<ScheduledNotification> plan({
    required BillPayment payment,
    required String billTitle,
    required int daysBefore,
    required DateTime now,
    required QuietHours quiet,
  }) {
    if (payment.paidOn != null) {
      return const []; // does not plan for already paid occurrence (RN-134)
    }

    final notifications = <ScheduledNotification>[];

    // dueDate vem como um dia exato, geralmente em UTC (00:00:00Z).
    // Plan notification in local timezone.
    final advanceDate = payment.dueOn.subtract(Duration(days: daysBefore));
    final advanceTime = DateTime(
      advanceDate.year,
      advanceDate.month,
      advanceDate.day,
      9,
    );

    if (advanceTime.isAfter(now)) {
      notifications.add(
        ScheduledNotification(
          id: '${payment.id}_advance',
          title: 'Conta a vencer',
          body: '$billTitle vence em $daysBefore dias.',
          scheduledAt: quiet.adjust(advanceTime),
        ),
      );
    }

    final dueDate = payment.dueOn;
    final dueTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 9);

    if (dueTime.isAfter(now)) {
      notifications.add(
        ScheduledNotification(
          id: '${payment.id}_due',
          title: 'Conta vence hoje',
          body: '$billTitle vence hoje.',
          scheduledAt: quiet.adjust(dueTime),
        ),
      );
    }

    return notifications;
  }
}
