import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_storage_port.dart';

class BatteryWarningStorageAdapter implements BatteryWarningStoragePort {
  final AppDatabase _db;
  final Clock _clock;

  BatteryWarningStorageAdapter(this._db, this._clock);

  @override
  Future<bool> hasSeenWarning() async {
    final query = _db.select(_db.settings)
      ..where((tbl) => tbl.key.equals('has_seen_battery_warning'));
    final result = await query.getSingleOrNull();
    return result?.value == 'true';
  }

  @override
  Future<void> markWarningAsSeen() async {
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            key: 'has_seen_battery_warning',
            value: 'true',
            updatedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
