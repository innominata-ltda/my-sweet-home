import 'package:my_sweet_home/core/time/clock.dart';
import 'package:drift/drift.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/domain/bills_preferences.dart';

class DriftBillsPreferences implements BillsPreferences {
  final AppDatabase _db;
  final Clock _clock;

  DriftBillsPreferences(this._db, this._clock);

  @override
  Future<bool> get hasDismissedPermissionWarning async {
    final consent =
        await (_db.select(
              _db.consents,
            )..where((tbl) => tbl.key.equals('dismissed_notification_warning')))
            .getSingleOrNull();
    return consent?.granted ?? false;
  }

  @override
  Future<void> dismissPermissionWarning() async {
    await _db
        .into(_db.consents)
        .insertOnConflictUpdate(
          ConsentsCompanion(
            key: const Value('dismissed_notification_warning'),
            granted: const Value(true),
            grantedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
        );
  }
}
