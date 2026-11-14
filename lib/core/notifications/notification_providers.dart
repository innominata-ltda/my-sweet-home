import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/notifications/adapters/exact_alarm_permission_adapter.dart';
import 'package:my_sweet_home/core/notifications/local_notification_scheduler.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';

final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final notificationSchedulerProvider = Provider<NotificationSchedulerPort>((
  ref,
) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  return LocalNotificationScheduler(
    plugin,
    exactAlarmPermission: ExactAlarmPermissionAdapter(plugin: plugin),
  );
});
