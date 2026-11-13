/// Repository for querying and updating application settings and user consents.
///
/// **Rule REPO-009:** No data leaves the device without explicit per-action consent.
/// Consents are stored with strict offline/denied defaults.
abstract interface class SettingsRepository {
  /// Returns `true` if user granted prior consent in settings
  /// for cloud OCR processing (`cloud_ocr`).
  ///
  /// Default: `false` (offline by default, explicit opt-in required - RN-190).
  Future<bool> isCloudOcrAllowed();

  /// Sets user prior consent state for cloud OCR.
  Future<void> setCloudOcrAllowed(bool value);

  /// Returns `true` if automatic deletion of receipt photo after processing is enabled.
  ///
  /// Default: `true` (enabled by default - RN-202, RF-048, CA-6.1).
  Future<bool> isDeleteReceiptPhotoEnabled();

  /// Sets whether receipt photo must be deleted after processing.
  Future<void> setDeleteReceiptPhotoEnabled(bool value);

  /// Returns `true` if user granted prior consent in settings
  /// for encrypted cloud backup (`cloud_backup`).
  ///
  /// Default: `false` (offline by default, explicit opt-in required - RN-235, REPO-009).
  Future<bool> isCloudBackupAllowed();

  /// Sets user prior consent state for cloud backup.
  Future<void> setCloudBackupAllowed(bool value);

  /// Returns `true` if "hide values" privacy setting is active.
  ///
  /// When active, monetary amounts must be masked on home screen widgets
  /// while app is backgrounded or device is locked (RN-253, CA-3.2).
  ///
  /// Default: `false` (values visible by default).
  Future<bool> isHideValuesEnabled();

  /// Sets whether "hide values" privacy setting is active.
  Future<void> setHideValuesEnabled(bool value);

  /// Returns `true` if user granted consent for local household synchronization (`household_sync`).
  ///
  /// Default: `false` (offline by default, explicit opt-in required - RF-120, REPO-009).
  Future<bool> isHouseholdSyncAllowed();

  /// Sets user consent for local network household synchronization.
  Future<void> setHouseholdSyncAllowed(bool value);

  /// Returns `true` if user granted consent for remote cloud household synchronization (`household_sync_remote`).
  ///
  /// Default: `false` (offline by default, explicit opt-in required - RF-127, REPO-009).
  Future<bool> isHouseholdSyncRemoteAllowed();

  /// Sets user consent for remote cloud household synchronization.
  Future<void> setHouseholdSyncRemoteAllowed(bool value);

  /// Returns `true` if visual effects (particles and animations) are enabled.
  ///
  /// Default: `true` (RF-014).
  Future<bool> isVisualEffectsEnabled();

  /// Sets whether visual effects are enabled.
  Future<void> setVisualEffectsEnabled(bool value);

  /// Returns `true` if initial mascot onboarding has been completed.
  ///
  /// Default: `false` (RF-009).
  Future<bool> isOnboardingCompleted();

  /// Sets whether initial mascot onboarding has been completed.
  Future<void> setOnboardingCompleted(bool value);

  /// Returns `true` if household shared tutorial has been displayed to user.
  ///
  /// Default: `false` (RN-392).
  Future<bool> isHouseholdTutorialCompleted();

  /// Sets whether household shared tutorial has been completed.
  Future<void> setHouseholdTutorialCompleted(bool value);

  /// Returns the preferred app locale ID (`'system'` or a registered locale ID).
  ///
  /// Default: `'system'`.
  Future<String> getAppLocale();

  /// Persists the preferred app locale ID (`'system'` or a registered locale ID).
  Future<void> setAppLocale(String localeId);

  /// Returns the preferred receipt OCR format ID (`'auto'` or a registered format ID).
  ///
  /// Default: `'auto'`.
  Future<String> getReceiptFormat();

  /// Persists the preferred receipt OCR format ID (`'auto'` or a registered format ID).
  Future<void> setReceiptFormat(String formatId);
}
