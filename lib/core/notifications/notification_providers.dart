import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/notifications/adapters/exact_alarm_permission_adapter.dart';
import 'package:my_sweet_home/core/notifications/local_notification_scheduler.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/retention_notification_coordinator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';

final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final notificationSchedulerProvider = Provider<NotificationSchedulerPort>((
  ref,
) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  final reschedulers = <Future<Result<void, Failure>> Function()>[];
  final scheduler = LocalNotificationScheduler(
    plugin,
    exactAlarmPermission: ExactAlarmPermissionAdapter(plugin: plugin),
    reschedulers: reschedulers,
  );
  reschedulers.add(() {
    return RetentionNotificationCoordinator(
      scheduler: scheduler,
      settings: ref.read(settingsRepositoryProvider),
    ).rescheduleRemainingAfterBoot();
  });
  return scheduler;
});

final retentionNotificationCoordinatorProvider =
    Provider<RetentionNotificationCoordinator>((ref) {
      return RetentionNotificationCoordinator(
        scheduler: ref.watch(notificationSchedulerProvider),
        settings: ref.watch(settingsRepositoryProvider),
      );
    });
