import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/settings/drift_settings_repository.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  group('DriftSettingsRepository (RN-235, REPO-009, RN-333)', () {
    late AppDatabase db;
    late DriftSettingsRepository repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = DriftSettingsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('cloud_backup consent is false by default (offline-first)', () async {
      expect(await repository.isCloudBackupAllowed(), isFalse);
    });

    test('setCloudBackupAllowed altera e persiste no banco', () async {
      await repository.setCloudBackupAllowed(true);
      expect(await repository.isCloudBackupAllowed(), isTrue);

      await repository.setCloudBackupAllowed(false);
      expect(await repository.isCloudBackupAllowed(), isFalse);
    });

    test('cloud_ocr consent is false by default', () async {
      expect(await repository.isCloudOcrAllowed(), isFalse);
    });

    test('setCloudOcrAllowed altera e persiste no banco', () async {
      await repository.setCloudOcrAllowed(true);
      expect(await repository.isCloudOcrAllowed(), isTrue);
    });

    test('delete_receipt_photo is true by default', () async {
      expect(await repository.isDeleteReceiptPhotoEnabled(), isTrue);
    });

    test('setDeleteReceiptPhotoEnabled altera e persiste no banco', () async {
      await repository.setDeleteReceiptPhotoEnabled(false);
      expect(await repository.isDeleteReceiptPhotoEnabled(), isFalse);
    });

    test('hide_values is false by default', () async {
      expect(await repository.isHideValuesEnabled(), isFalse);
    });

    test('setHideValuesEnabled altera e persiste no banco', () async {
      await repository.setHideValuesEnabled(true);
      expect(await repository.isHideValuesEnabled(), isTrue);
      await repository.setHideValuesEnabled(false);
      expect(await repository.isHideValuesEnabled(), isFalse);
    });

    test('household_sync consent is false by default', () async {
      expect(await repository.isHouseholdSyncAllowed(), isFalse);
    });

    test('setHouseholdSyncAllowed altera e persiste no banco', () async {
      await repository.setHouseholdSyncAllowed(true);
      expect(await repository.isHouseholdSyncAllowed(), isTrue);
      await repository.setHouseholdSyncAllowed(false);
      expect(await repository.isHouseholdSyncAllowed(), isFalse);
    });

    test('household_sync_remote consent is false by default', () async {
      expect(await repository.isHouseholdSyncRemoteAllowed(), isFalse);
    });

    test('setHouseholdSyncRemoteAllowed altera e persiste no banco', () async {
      await repository.setHouseholdSyncRemoteAllowed(true);
      expect(await repository.isHouseholdSyncRemoteAllowed(), isTrue);
      await repository.setHouseholdSyncRemoteAllowed(false);
      expect(await repository.isHouseholdSyncRemoteAllowed(), isFalse);
    });

    test('visual_effects_enabled is true by default (RF-014)', () async {
      expect(await repository.isVisualEffectsEnabled(), isTrue);
    });

    test('setVisualEffectsEnabled altera e persiste no banco', () async {
      await repository.setVisualEffectsEnabled(false);
      expect(await repository.isVisualEffectsEnabled(), isFalse);
      await repository.setVisualEffectsEnabled(true);
      expect(await repository.isVisualEffectsEnabled(), isTrue);
    });

    test('onboarding_completed is false by default (RF-009)', () async {
      expect(await repository.isOnboardingCompleted(), isFalse);
    });

    test('setOnboardingCompleted altera e persiste no banco', () async {
      await repository.setOnboardingCompleted(true);
      expect(await repository.isOnboardingCompleted(), isTrue);
      await repository.setOnboardingCompleted(false);
      expect(await repository.isOnboardingCompleted(), isFalse);
    });

    test(
      'settingsRepositoryProvider resolves repository with db and clock',
      () async {
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(const SystemClock()),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(settingsRepositoryProvider);
        expect(repo, isA<DriftSettingsRepository>());
        expect(await repo.isHouseholdSyncRemoteAllowed(), isFalse);
      },
    );
  });
}
