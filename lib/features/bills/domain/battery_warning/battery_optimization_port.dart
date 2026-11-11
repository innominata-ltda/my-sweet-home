abstract interface class BatteryOptimizationPort {
  bool get isAndroid;
  Future<void> openSettings();
}
