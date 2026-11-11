import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';

/// Porta compartilhada com a SPEC-007. Fake: RecordingScheduler.
abstract interface class NotificationSchedulerPort {
  Future<Result<void, Failure>> schedule(ScheduledNotification n);
  Future<Result<void, Failure>> cancel(String id);
  Future<List<ScheduledNotification>> pending();
  Future<PermissionState> permission();
  Future<Result<void, Failure>> rescheduleAllAfterBoot();
}
