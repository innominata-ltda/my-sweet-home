import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_optimization_port.dart';

class FakeBatteryOptimization implements BatteryOptimizationPort {
  @override
  final bool isAndroid;
  bool settingsOpened = false;

  FakeBatteryOptimization({this.isAndroid = true});

  @override
  Future<void> openSettings() async {
    settingsOpened = true;
  }
}
