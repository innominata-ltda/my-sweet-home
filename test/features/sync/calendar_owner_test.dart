import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/data/calendar_owner_guard.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_repository.dart';

void main() {
  group('T-16 / RN-334 — Unique Google Calendar Ownership in Household', () {
    late AppDatabase db;
    late FakeHouseholdRepository repo;
    late FakeClock clock;
    late CalendarOwnerGuard guard;

    setUp(() {
      db = AppDatabase.memory();
      repo = FakeHouseholdRepository();
      clock = FakeClock(DateTime.utc(2026, 3, 15));
      guard = CalendarOwnerGuard(
        householdRepository: repo,
        db: db,
        clock: clock,
      );
    });

    tearDown(() async {
      await db.close();
      repo.dispose();
    });

    test('when no active household, any device can link', () async {
      expect(await guard.canLinkGoogleCalendar(), isTrue);
      expect(await guard.claimCalendarOwnership(), isTrue);
    });

    test(
      'quando há casa ativa e sem proprietário registrado, permite vincular',
      () async {
        final now = DateTime.utc(2026, 3, 15);
        final household = Household(
          id: 'h-1',
          name: 'Casa da Duda',
          localSiteId: 'site-device-1',
          sharedAreas: {SyncArea.catalog, SyncArea.home},
          createdAt: now,
          joinedAt: now,
          active: true,
        );
        repo.setHousehold(household);

        expect(await guard.canLinkGoogleCalendar(), isTrue);
      },
    );

    test('apenas um aparelho pode reivindicar titularidade do Google Calendar (RN-334)', () async {
      final now = DateTime.utc(2026, 3, 15);
      final householdDevice1 = Household(
        id: 'h-1',
        name: 'Casa da Duda',
        localSiteId: 'site-device-1',
        sharedAreas: {SyncArea.catalog, SyncArea.home},
        createdAt: now,
        joinedAt: now,
        active: true,
      );
      repo.setHousehold(householdDevice1);

      // Aparelho 1 reivindica
      expect(await guard.claimCalendarOwnership(), isTrue);
      expect(await guard.canLinkGoogleCalendar(), isTrue);

      // Aparelho 2 tenta na mesma casa
      final householdDevice2 = Household(
        id: 'h-1',
        name: 'Casa da Duda',
        localSiteId: 'site-device-2',
        sharedAreas: {SyncArea.catalog, SyncArea.home},
        createdAt: now,
        joinedAt: now,
        active: true,
      );
      final repoDevice2 = FakeHouseholdRepository(
        initialHousehold: householdDevice2,
      );
      final guardDevice2 = CalendarOwnerGuard(
        householdRepository: repoDevice2,
        db: db,
        clock: clock,
      );

      // Device 2 is blocked
      expect(await guardDevice2.canLinkGoogleCalendar(), isFalse);
      expect(await guardDevice2.claimCalendarOwnership(), isFalse);

      // Aparelho 1 libera titularidade
      await guard.releaseCalendarOwnership();

      // Aparelho 2 agora pode reivindicar
      expect(await guardDevice2.canLinkGoogleCalendar(), isTrue);
      expect(await guardDevice2.claimCalendarOwnership(), isTrue);
    });
  });
}
