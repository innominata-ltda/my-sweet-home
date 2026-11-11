abstract interface class BatteryWarningStoragePort {
  Future<bool> hasSeenWarning();
  Future<void> markWarningAsSeen();
}
