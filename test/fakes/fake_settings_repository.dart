import 'package:my_sweet_home/core/settings/settings_repository.dart';

/// Deterministic fake of [SettingsRepository] for unit and widget tests.
class FakeSettingsRepository implements SettingsRepository {
  bool cloudOcrAllowed;
  bool deleteReceiptPhotoEnabled;
  bool cloudBackupAllowed;
  bool hideValuesEnabled;
  bool householdSyncAllowed;
  bool householdSyncRemoteAllowed;
  bool visualEffectsEnabled;
  bool onboardingCompleted;
  bool householdTutorialCompleted;

  FakeSettingsRepository({
    this.cloudOcrAllowed = false,
    this.deleteReceiptPhotoEnabled = true,
    this.cloudBackupAllowed = false,
    this.hideValuesEnabled = false,
    this.householdSyncAllowed = false,
    this.householdSyncRemoteAllowed = false,
    this.visualEffectsEnabled = true,
    this.onboardingCompleted = false,
    this.householdTutorialCompleted = false,
  });

  @override
  Future<bool> isCloudOcrAllowed() async => cloudOcrAllowed;

  @override
  Future<void> setCloudOcrAllowed(bool value) async {
    cloudOcrAllowed = value;
  }

  @override
  Future<bool> isDeleteReceiptPhotoEnabled() async => deleteReceiptPhotoEnabled;

  @override
  Future<void> setDeleteReceiptPhotoEnabled(bool value) async {
    deleteReceiptPhotoEnabled = value;
  }

  @override
  Future<bool> isCloudBackupAllowed() async => cloudBackupAllowed;

  @override
  Future<void> setCloudBackupAllowed(bool value) async {
    cloudBackupAllowed = value;
  }

  @override
  Future<bool> isHideValuesEnabled() async => hideValuesEnabled;

  @override
  Future<void> setHideValuesEnabled(bool value) async {
    hideValuesEnabled = value;
  }

  @override
  Future<bool> isHouseholdSyncAllowed() async => householdSyncAllowed;

  @override
  Future<void> setHouseholdSyncAllowed(bool value) async {
    householdSyncAllowed = value;
  }

  @override
  Future<bool> isHouseholdSyncRemoteAllowed() async =>
      householdSyncRemoteAllowed;

  @override
  Future<void> setHouseholdSyncRemoteAllowed(bool value) async {
    householdSyncRemoteAllowed = value;
  }

  @override
  Future<bool> isVisualEffectsEnabled() async => visualEffectsEnabled;

  @override
  Future<void> setVisualEffectsEnabled(bool value) async {
    visualEffectsEnabled = value;
  }

  @override
  Future<bool> isOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    onboardingCompleted = value;
  }

  @override
  Future<bool> isHouseholdTutorialCompleted() async =>
      householdTutorialCompleted;

  @override
  Future<void> setHouseholdTutorialCompleted(bool value) async {
    householdTutorialCompleted = value;
  }
}
