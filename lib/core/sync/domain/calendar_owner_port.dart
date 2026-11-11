/// Port for checking exclusive ownership of Google Calendar integration (RN-334).
abstract interface class CalendarOwnerPort {
  /// Returns whether current device can link tasks to Google Calendar (RN-334).
  ///
  /// If the app is not in a shared household, returns `true`.
  /// In a shared household, only the registered owner device may link.
  Future<bool> canLinkGoogleCalendar();

  /// Attempts to register current device as owner of Google Calendar synchronization.
  /// Returns `true` if claim succeeded or if already the owner.
  Future<bool> claimCalendarOwnership();

  /// Releases ownership so another household device may link if desired.
  Future<void> releaseCalendarOwnership();
}
