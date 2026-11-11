import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// In-memory fake of [PairingChannel] for unit and integration tests (CA-1.1..CA-1.4).
class FakePairingChannel implements PairingChannel {
  final Clock clock;
  final HouseholdKey householdKey;
  int memberCount;
  String currentHouseholdId;
  String currentHouseholdName;

  FakePairingChannel({
    required this.clock,
    required this.householdKey,
    this.memberCount = 1,
    this.currentHouseholdId = 'house-fake-1',
    this.currentHouseholdName = 'Casa Fake',
  });

  Invite? lastGeneratedInvite;

  @override
  Future<Result<Invite, Failure>> openInvite({
    Duration ttl = const Duration(minutes: 10),
    String? lanHost,
    int? lanPort,
  }) async {
    if (memberCount >= 8) {
      return const Err(MaxMembersFailure());
    }

    final invite = Invite(
      householdId: currentHouseholdId,
      householdName: currentHouseholdName,
      publicKey: List.generate(32, (i) => i),
      expiresAt: clock.nowUtc().add(ttl),
      lanHost: '192.168.1.100',
      lanPort: 54321,
    );
    lastGeneratedInvite = invite;
    return Ok(invite);
  }

  @override
  Future<Result<PairingSession, Failure>> join(Invite invite) async {
    if (invite.isExpired(clock.nowUtc())) {
      return const Err(InviteExpiredFailure());
    }

    final session = PairingSession(
      sessionId: 'session-fake-123',
      invite: invite,
      guestPublicKey: List.generate(32, (i) => 255 - i),
      sasCode: '742 915',
    );
    return Ok(session);
  }

  @override
  Future<Result<HouseholdKey, Failure>> confirm(
    PairingSession session, {
    required bool accepted,
  }) async {
    if (!accepted) {
      return const Err(PairingFailure('Pairing cancelled by user.'));
    }
    memberCount++;
    return Ok(householdKey);
  }
}
