import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/domain/exact_alarm_notice_service.dart';

/// Adaptador SQLite para [ExactAlarmNoticeStoragePort] gravado em `settings` (RN-423, CA-4.5).
class ExactAlarmNoticeStorageAdapter implements ExactAlarmNoticeStoragePort {
  final AppDatabase db;
  final Clock clock;

  static const String _settingsKey = 'has_seen_exact_alarm_notice';

  ExactAlarmNoticeStorageAdapter(this.db, [this.clock = const SystemClock()]);

  @override
  Future<bool> hasSeenNotice() async {
    final query = db.select(db.settings)
      ..where((tbl) => tbl.key.equals(_settingsKey));
    final row = await query.getSingleOrNull();
    return row?.value == 'true';
  }

  @override
  Future<void> markNoticeAsSeen() async {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            key: _settingsKey,
            value: 'true',
            updatedAt: Value(clock.nowUtc().toIso8601String()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
