import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/sync/domain/calendar_owner_port.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';

/// Guarda de titularidade do Google Calendar na casa compartilhada (RF-121, RN-334, T-16).
///
/// Ensures at most one household device synchronizes tasks with Google Calendar,
/// avoiding duplicate events and cloud concurrency.
class CalendarOwnerGuard implements CalendarOwnerPort {
  static const String settingKey = 'sync_calendar_owner_site_id';

  final HouseholdRepository householdRepository;
  final AppDatabase db;
  final Clock clock;

  const CalendarOwnerGuard({
    required this.householdRepository,
    required this.db,
    this.clock = const SystemClock(),
  });

  @override
  Future<bool> canLinkGoogleCalendar() async {
    final household = (await householdRepository.getHousehold()).valueOrNull;
    if (household == null || !household.active) {
      return true;
    }

    final setting = await (db.select(
      db.settings,
    )..where((tbl) => tbl.key.equals(settingKey))).getSingleOrNull();

    if (setting == null || setting.value.isEmpty) {
      return true;
    }

    return setting.value == household.localSiteId;
  }

  @override
  Future<bool> claimCalendarOwnership() async {
    final household = (await householdRepository.getHousehold()).valueOrNull;
    if (household == null || !household.active) {
      return true;
    }

    final setting = await (db.select(
      db.settings,
    )..where((tbl) => tbl.key.equals(settingKey))).getSingleOrNull();

    if (setting != null &&
        setting.value.isNotEmpty &&
        setting.value != household.localSiteId) {
      return false;
    }

    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(settingKey),
            value: Value(household.localSiteId),
            updatedAt: Value(clock.nowUtc().toIso8601String()),
          ),
        );

    return true;
  }

  @override
  Future<void> releaseCalendarOwnership() async {
    final household = (await householdRepository.getHousehold()).valueOrNull;
    if (household == null) return;

    final setting = await (db.select(
      db.settings,
    )..where((tbl) => tbl.key.equals(settingKey))).getSingleOrNull();

    if (setting?.value == household.localSiteId) {
      await (db.delete(
        db.settings,
      )..where((tbl) => tbl.key.equals(settingKey))).go();
    }
  }
}
