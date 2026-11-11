import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_storage_port.dart';

class FakeBatteryWarningStorage implements BatteryWarningStoragePort {
  bool hasSeen;

  FakeBatteryWarningStorage({this.hasSeen = false});

  @override
  Future<bool> hasSeenWarning() async {
    return hasSeen;
  }

  @override
  Future<void> markWarningAsSeen() async {
    hasSeen = true;
  }
}
