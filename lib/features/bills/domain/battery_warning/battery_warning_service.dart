import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_optimization_port.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_storage_port.dart';

class BatteryWarningService {
  final BatteryOptimizationPort _optimization;
  final BatteryWarningStoragePort _storage;

  BatteryWarningService(this._optimization, this._storage);

  /// Returns true if battery optimization warning should be displayed when saving a bill.
  Future<bool> shouldShowWarningOnSave() async {
    if (!_optimization.isAndroid) return false;
    final hasSeen = await _storage.hasSeenWarning();
    if (hasSeen) return false;

    await _storage.markWarningAsSeen();
    return true;
  }

  /// Returns true if permanent warning banner should be displayed.
  Future<bool> shouldShowPersistentHint() async {
    if (!_optimization.isAndroid) return false;
    return await _storage.hasSeenWarning();
  }

  /// Opens battery optimization settings screen.
  Future<void> openSettings() async {
    await _optimization.openSettings();
  }
}
