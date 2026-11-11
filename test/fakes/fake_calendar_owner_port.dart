import 'package:my_sweet_home/core/sync/domain/calendar_owner_port.dart';

/// Fake of [CalendarOwnerPort] for unit and integration tests.
class FakeCalendarOwnerPort implements CalendarOwnerPort {
  bool canLink;
  String? ownerSiteId;
  String currentSiteId;

  FakeCalendarOwnerPort({
    this.canLink = true,
    this.ownerSiteId,
    this.currentSiteId = 'local-site-1',
  });

  @override
  Future<bool> canLinkGoogleCalendar() async {
    if (ownerSiteId == null) return canLink;
    return ownerSiteId == currentSiteId;
  }

  @override
  Future<bool> claimCalendarOwnership() async {
    if (ownerSiteId == null || ownerSiteId == currentSiteId) {
      ownerSiteId = currentSiteId;
      return true;
    }
    return false;
  }

  @override
  Future<void> releaseCalendarOwnership() async {
    if (ownerSiteId == currentSiteId) {
      ownerSiteId = null;
    }
  }
}
