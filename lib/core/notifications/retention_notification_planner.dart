import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';

class RetentionMessage {
  final String title;
  final String body;

  const RetentionMessage({required this.title, required this.body});
}

typedef RetentionMessageBuilder = RetentionMessage Function(int daysSinceOpen);

/// Plans local retention reminders using a Fibonacci day-interval backoff
/// (`3, 5, 8, 13, 21, 34, 55` days) at 10:00 local time.
class RetentionNotificationPlanner {
  static const List<int> fibonacciDays = [3, 5, 8, 13, 21, 34, 55];
  static const int scheduledHour = 10;
  static const int scheduledMinute = 0;

  const RetentionNotificationPlanner();

  static String notificationIdForDays(int days) => 'retention_fib_$days';

  static List<String> get allNotificationIds =>
      fibonacciDays.map(notificationIdForDays).toList(growable: false);

  List<ScheduledNotification> plan({
    required DateTime anchorLocal,
    required DateTime nowLocal,
    required RetentionMessageBuilder messageBuilder,
  }) {
    final notifications = <ScheduledNotification>[];
    for (final days in fibonacciDays) {
      final scheduledAt = DateTime(
        anchorLocal.year,
        anchorLocal.month,
        anchorLocal.day + days,
        scheduledHour,
        scheduledMinute,
      );
      if (!scheduledAt.isAfter(nowLocal)) {
        continue;
      }
      final message = messageBuilder(days);
      notifications.add(
        ScheduledNotification(
          id: notificationIdForDays(days),
          title: message.title,
          body: message.body,
          scheduledAt: scheduledAt,
        ),
      );
    }
    return notifications;
  }
}
