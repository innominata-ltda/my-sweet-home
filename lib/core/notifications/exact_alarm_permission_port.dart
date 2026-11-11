/// Port for checking and requesting exact alarm scheduling permissions (RN-423, CA-4.5).
abstract interface class ExactAlarmPermissionPort {
  /// Returns whether the app has permission to schedule exact alarms (e.g. SCHEDULE_EXACT_ALARM on Android 12+ / 14+).
  Future<bool> canScheduleExact();

  /// Opens the operating system settings page where user can grant permission.
  Future<void> openSettings();
}
