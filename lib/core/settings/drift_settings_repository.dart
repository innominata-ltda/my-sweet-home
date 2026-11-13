import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/regionalization/regionalization_models.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';

/// Implementation of [SettingsRepository] backed by SQLite ([AppDatabase]).
class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;
  final Clock _clock;

  DriftSettingsRepository(this._db, {this._clock = const SystemClock()});

  @override
  Future<bool> isCloudOcrAllowed() async {
    final consent = await (_db.select(
      _db.consents,
    )..where((tbl) => tbl.key.equals('cloud_ocr'))).getSingleOrNull();
    return consent?.granted ?? false;
  }

  @override
  Future<void> setCloudOcrAllowed(bool value) async {
    await _db
        .into(_db.consents)
        .insertOnConflictUpdate(
          ConsentsCompanion(
            key: const Value('cloud_ocr'),
            granted: Value(value),
            grantedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
        );
  }

  @override
  Future<bool> isCloudBackupAllowed() async {
    final consent = await (_db.select(
      _db.consents,
    )..where((tbl) => tbl.key.equals('cloud_backup'))).getSingleOrNull();
    return consent?.granted ?? false;
  }

  @override
  Future<void> setCloudBackupAllowed(bool value) async {
    await _db
        .into(_db.consents)
        .insertOnConflictUpdate(
          ConsentsCompanion(
            key: const Value('cloud_backup'),
            granted: Value(value),
            grantedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
        );
  }

  @override
  Future<bool> isDeleteReceiptPhotoEnabled() async {
    final setting =
        await (_db.select(_db.settings)
              ..where((tbl) => tbl.key.equals('delete_receipt_photo')))
            .getSingleOrNull();
    if (setting == null) return true;
    return setting.value.toLowerCase() == 'true';
  }

  @override
  Future<void> setDeleteReceiptPhotoEnabled(bool value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('delete_receipt_photo'),
            value: Value(value.toString()),
          ),
        );
  }

  @override
  Future<bool> isHideValuesEnabled() async {
    final setting = await (_db.select(
      _db.settings,
    )..where((tbl) => tbl.key.equals('hide_values'))).getSingleOrNull();
    if (setting == null) return false;
    return setting.value.toLowerCase() == 'true';
  }

  @override
  Future<void> setHideValuesEnabled(bool value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('hide_values'),
            value: Value(value.toString()),
          ),
        );
  }

  @override
  Future<bool> isHouseholdSyncAllowed() async {
    final consent = await (_db.select(
      _db.consents,
    )..where((tbl) => tbl.key.equals('household_sync'))).getSingleOrNull();
    return consent?.granted ?? false;
  }

  @override
  Future<void> setHouseholdSyncAllowed(bool value) async {
    await _db
        .into(_db.consents)
        .insertOnConflictUpdate(
          ConsentsCompanion(
            key: const Value('household_sync'),
            granted: Value(value),
            grantedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
        );
  }

  @override
  Future<bool> isHouseholdSyncRemoteAllowed() async {
    final consent =
        await (_db.select(_db.consents)
              ..where((tbl) => tbl.key.equals('household_sync_remote')))
            .getSingleOrNull();
    return consent?.granted ?? false;
  }

  @override
  Future<void> setHouseholdSyncRemoteAllowed(bool value) async {
    await _db
        .into(_db.consents)
        .insertOnConflictUpdate(
          ConsentsCompanion(
            key: const Value('household_sync_remote'),
            granted: Value(value),
            grantedAt: Value(_clock.nowUtc().toIso8601String()),
          ),
        );
  }

  @override
  Future<bool> isVisualEffectsEnabled() async {
    final setting =
        await (_db.select(_db.settings)
              ..where((tbl) => tbl.key.equals('visual_effects_enabled')))
            .getSingleOrNull();
    if (setting == null) return true;
    return setting.value.toLowerCase() == 'true';
  }

  @override
  Future<void> setVisualEffectsEnabled(bool value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('visual_effects_enabled'),
            value: Value(value.toString()),
          ),
        );
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final setting =
        await (_db.select(_db.settings)
              ..where((tbl) => tbl.key.equals('onboarding_completed')))
            .getSingleOrNull();
    if (setting == null) return false;
    return setting.value.toLowerCase() == 'true';
  }

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('onboarding_completed'),
            value: Value(value.toString()),
          ),
        );
  }

  @override
  Future<bool> isHouseholdTutorialCompleted() async {
    final setting =
        await (_db.select(_db.settings)
              ..where((tbl) => tbl.key.equals('household_tutorial_completed')))
            .getSingleOrNull();
    if (setting == null) return false;
    return setting.value.toLowerCase() == 'true';
  }

  @override
  Future<void> setHouseholdTutorialCompleted(bool value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('household_tutorial_completed'),
            value: Value(value.toString()),
          ),
        );
  }

  @override
  Future<String> getAppLocale() async {
    final setting = await (_db.select(
      _db.settings,
    )..where((tbl) => tbl.key.equals('app_locale'))).getSingleOrNull();
    return AppLocaleRegistry.normalizeLocaleId(setting?.value);
  }

  @override
  Future<void> setAppLocale(String localeId) async {
    final normalized = AppLocaleRegistry.normalizeLocaleId(localeId);
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('app_locale'),
            value: Value(normalized),
          ),
        );
  }

  @override
  Future<String> getReceiptFormat() async {
    final setting = await (_db.select(
      _db.settings,
    )..where((tbl) => tbl.key.equals('receipt_format'))).getSingleOrNull();
    return ReceiptFormatCatalog.normalizeFormatId(setting?.value);
  }

  @override
  Future<void> setReceiptFormat(String formatId) async {
    final normalized = ReceiptFormatCatalog.normalizeFormatId(formatId);
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value('receipt_format'),
            value: Value(normalized),
          ),
        );
  }
}
