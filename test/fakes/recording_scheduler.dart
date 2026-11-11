import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';

class RecordingScheduler implements NotificationSchedulerPort {
  final List<ScheduledNotification> _scheduled = [];
  PermissionState _permission = PermissionState.granted;

  List<ScheduledNotification> get scheduled => List.unmodifiable(_scheduled);

  void setPermission(PermissionState permission) {
    _permission = permission;
  }

  @override
  Future<Result<void, Failure>> schedule(ScheduledNotification n) async {
    _scheduled.removeWhere((e) => e.id == n.id);
    _scheduled.add(n);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> cancel(String id) async {
    _scheduled.removeWhere((e) => e.id == id);
    return const Ok(null);
  }

  @override
  Future<List<ScheduledNotification>> pending() async {
    return scheduled;
  }

  @override
  Future<PermissionState> permission() async {
    return _permission;
  }

  @override
  Future<Result<void, Failure>> rescheduleAllAfterBoot() async {
    return const Ok(null);
  }
}
