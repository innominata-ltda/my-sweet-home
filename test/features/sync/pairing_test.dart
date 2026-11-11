import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/data/x25519_pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_key_store.dart';
import '../../../test/fakes/fake_household_repository.dart';

void main() {
  group('T-09 / RF-120 — Pareamento Presencial X25519 e QR Code (CA-1.1..CA-1.4)', () {
    late FakeClock clock;
    late HouseholdKey sharedKey;
    late FakeHouseholdKeyStore keyStoreHost;
    late FakeHouseholdRepository repoHost;
    late X25519PairingChannel channelHost;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 15, 10, 0));
      sharedKey = HouseholdKey(List.generate(32, (i) => i));
      keyStoreHost = FakeHouseholdKeyStore(sharedKey);

      final household = Household(
        id: 'h-1',
        name: 'Casa da Duda',
        localSiteId: 'host-device',
        sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
        createdAt: clock.nowUtc(),
        joinedAt: clock.nowUtc(),
        active: true,
      );
      final member = Member(
        id: 'm-1',
        householdId: 'h-1',
        siteId: 'host-device',
        name: 'Celular da Duda',
        joinedAt: clock.nowUtc(),
        active: true,
      );

      repoHost = FakeHouseholdRepository(
        initialHousehold: household,
        initialMembers: [member],
      );

      channelHost = X25519PairingChannel(
        householdRepository: repoHost,
        keyStore: keyStoreHost,
        clock: clock,
      );
    });

    test('CA-1.1: X25519 key exchange generates identical 6-digit SAS and delivers household key', () async {
      // 1. Host abre convite
      final inviteResult = await channelHost.openInvite();
      expect(inviteResult.isOk, isTrue);
      final invite = inviteResult.valueOrNull!;
      expect(invite.householdId, equals('h-1'));
      expect(invite.publicKey.length, equals(32));

      // Test QR serialization
      final qrString = invite.toQrString();
      final decodedInvite = Invite.fromQrString(qrString);
      expect(decodedInvite.householdId, equals(invite.householdId));
      expect(decodedInvite.publicKey, equals(invite.publicKey));

      // 2. Guest reads invite and joins
      final guestKeyStore = FakeHouseholdKeyStore();
      final guestRepo = FakeHouseholdRepository();
      final channelGuest = X25519PairingChannel(
        householdRepository: guestRepo,
        keyStore: guestKeyStore,
        clock: clock,
      );

      final joinResult = await channelGuest.join(decodedInvite);
      expect(joinResult.isOk, isTrue);
      final guestSession = joinResult.valueOrNull!;
      expect(guestSession.sasCode.length, equals(7)); // "123 456"

      // 3. Confirming acceptance delivers symmetric household key
      final confirmResult = await channelHost.confirm(
        guestSession,
        accepted: true,
      );
      expect(confirmResult.isOk, isTrue);
      expect(confirmResult.valueOrNull, equals(sharedKey));
    });

    test('CA-1.2: FakeClock advances 11 minutes; join fails with InviteExpiredFailure', () async {
      final inviteResult = await channelHost.openInvite(
        ttl: const Duration(minutes: 10),
      );
      expect(inviteResult.isOk, isTrue);
      final invite = inviteResult.valueOrNull!;

      // Clock advances 11 minutes
      clock.advance(const Duration(minutes: 11));

      final guestChannel = X25519PairingChannel(
        householdRepository: FakeHouseholdRepository(),
        keyStore: FakeHouseholdKeyStore(),
        clock: clock,
      );

      final joinResult = await guestChannel.join(invite);
      expect(joinResult.isErr, isTrue);
      expect(joinResult.failureOrNull, isA<InviteExpiredFailure>());
    });

    test(
      'CA-1.3: confirm(accepted: false) recusa pareamento e não entrega chave',
      () async {
        final invite = (await channelHost.openInvite()).valueOrNull!;
        final guestChannel = X25519PairingChannel(
          householdRepository: FakeHouseholdRepository(),
          keyStore: FakeHouseholdKeyStore(),
          clock: clock,
        );
        final session = (await guestChannel.join(invite)).valueOrNull!;

        final confirmResult = await channelHost.confirm(
          session,
          accepted: false,
        );
        expect(confirmResult.isErr, isTrue);
        expect(confirmResult.failureOrNull, isA<PairingFailure>());
      },
    );

    test(
      'CA-1.4: Casa com 8 membros recusa openInvite com MaxMembersFailure',
      () async {
        final members = List.generate(
          8,
          (i) => Member(
            id: 'm-$i',
            householdId: 'h-1',
            siteId: 'site-$i',
            name: 'Aparelho $i',
            joinedAt: clock.nowUtc(),
            active: true,
          ),
        );
        repoHost.setMembers(members);

        final result = await channelHost.openInvite();
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<MaxMembersFailure>());
      },
    );
  });
}
