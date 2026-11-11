abstract interface class BillsPreferences {
  Future<bool> get hasDismissedPermissionWarning;
  Future<void> dismissPermissionWarning();
}
