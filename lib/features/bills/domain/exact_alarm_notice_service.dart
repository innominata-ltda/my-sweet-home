import 'package:my_sweet_home/core/notifications/exact_alarm_permission_port.dart';

/// Port for persistence of exact alarm notice display state (RN-423, CA-4.5).
abstract interface class ExactAlarmNoticeStoragePort {
  Future<bool> hasSeenNotice();
  Future<void> markNoticeAsSeen();
}

/// Domain service that manages exact alarm notice display (RN-423, CA-4.5).
class ExactAlarmNoticeService {
  final ExactAlarmPermissionPort permission;
  final ExactAlarmNoticeStoragePort storage;

  ExactAlarmNoticeService({required this.permission, required this.storage});

  /// Returns `true` if exact alarm warning should be displayed on bills screen.
  /// Displayed only once when permission is not granted.
  Future<bool> shouldShowNotice() async {
    final canSchedule = await permission.canScheduleExact();
    if (canSchedule) return false;

    final hasSeen = await storage.hasSeenNotice();
    if (hasSeen) return false;

    await storage.markNoticeAsSeen();
    return true;
  }

  /// Returns whether permanent banner notice should remain displayed if permission remains denied.
  Future<bool> hasSeenNotice() async {
    return await storage.hasSeenNotice();
  }

  /// Opens system settings for exact alarm permission grant.
  Future<void> openSettings() async {
    await permission.openSettings();
  }
}
