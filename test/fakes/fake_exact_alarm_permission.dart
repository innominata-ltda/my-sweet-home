import 'package:my_sweet_home/core/notifications/exact_alarm_permission_port.dart';

/// Fake of [ExactAlarmPermissionPort] for unit tests (CA-4.5).
class FakeExactAlarmPermission implements ExactAlarmPermissionPort {
  bool canSchedule;
  int openSettingsCalls = 0;

  FakeExactAlarmPermission([this.canSchedule = true]);

  @override
  Future<bool> canScheduleExact() async => canSchedule;

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }
}
