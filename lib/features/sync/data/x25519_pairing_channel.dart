import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// [PairingChannel] implementation using Diffie-Hellman key exchange over Curve25519 (X25519) (RN-303, RN-304).
class X25519PairingChannel implements PairingChannel {
  final HouseholdRepository householdRepository;
  final HouseholdKeyStore keyStore;
  final Clock clock;
  final IdGenerator idGenerator;
  final X25519 _x25519;
  final Sha256 _sha256;
  final AesGcm _aesGcm = AesGcm.with256bits();

  SimpleKeyPair? _hostKeyPair;

  X25519PairingChannel({
    required this.householdRepository,
    required this.keyStore,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7Generator(),
    X25519? x25519,
    Sha256? sha256,
  }) : _x25519 = x25519 ?? X25519(),
       _sha256 = sha256 ?? Sha256();

  @override
  Future<Result<Invite, Failure>> openInvite({
    Duration ttl = const Duration(minutes: 10),
    String? lanHost,
    int? lanPort,
  }) async {
    try {
      final household = (await householdRepository.getHousehold()).valueOrNull;
      if (household == null) {
        return const Err(
          HouseholdFailure('Nenhuma casa ativa para convidar aparelhos.'),
        );
      }

      final members =
          (await householdRepository.getMembers()).valueOrNull ?? [];
      final activeMembers = members.where((m) => m.active).toList();
      if (activeMembers.length >= 8) {
        return const Err(MaxMembersFailure());
      }

      _hostKeyPair = await _x25519.newKeyPair();
      final hostPublicKey = await _hostKeyPair!.extractPublicKey();
      final pubKeyBytes = hostPublicKey.bytes;
      final sasCode = Invite.deriveSasFromPublicKey(pubKeyBytes);

      List<int>? sealedKeyBytes;
      final householdKey = (await keyStore.read()).valueOrNull;
      if (householdKey != null) {
        sealedKeyBytes = await sealHouseholdKey(
          householdKey: householdKey,
          publicKey: pubKeyBytes,
          sasCode: sasCode,
        );
      }

      final selfMember = activeMembers
          .where((m) => m.siteId == household.localSiteId)
          .firstOrNull;

      final invite = Invite(
        householdId: household.id,
        householdName: household.name,
        publicKey: pubKeyBytes,
        expiresAt: clock.nowUtc().add(ttl),
        sealedKey: sealedKeyBytes,
        sharedAreas: household.sharedAreas.map((a) => a.name).toList(),
        hostSiteId: household.localSiteId,
        hostDeviceName: selfMember?.name ?? household.name,
        lanHost: lanHost,
        lanPort: lanPort,
      );

      return Ok(invite);
    } catch (e) {
      return Err(PairingFailure('Falha ao gerar convite', e));
    }
  }

  @override
  Future<Result<PairingSession, Failure>> join(Invite invite) async {
    try {
      if (invite.isExpired(clock.nowUtc())) {
        return const Err(InviteExpiredFailure());
      }

      // Guest generates its own ephemeral X25519 keypair
      final guestKeyPair = await _x25519.newKeyPair();
      final guestPublicKey = await guestKeyPair.extractPublicKey();

      // Validates that host public key is a valid X25519 key
      final hostPubKey = SimplePublicKey(
        invite.publicKey,
        type: KeyPairType.x25519,
      );
      await _x25519.sharedSecretKey(
        keyPair: guestKeyPair,
        remotePublicKey: hostPubKey,
      );

      final sasCode = Invite.deriveSasFromPublicKey(invite.publicKey);

      final session = PairingSession(
        sessionId: idGenerator.newId(),
        invite: invite,
        guestPublicKey: guestPublicKey.bytes,
        sasCode: sasCode,
      );

      return Ok(session);
    } catch (e) {
      return Err(PairingFailure('Falha ao ingressar no pareamento', e));
    }
  }

  @override
  Future<Result<HouseholdKey, Failure>> confirm(
    PairingSession session, {
    required bool accepted,
  }) async {
    if (!accepted) {
      return const Err(PairingFailure('Pareamento cancelado pelo usuário.'));
    }

    try {
      if (session.invite.isExpired(clock.nowUtc())) {
        return const Err(InviteExpiredFailure());
      }

      if (session.invite.sealedKey != null) {
        final unsealed = await _unsealHouseholdKey(
          sealedBytes: session.invite.sealedKey!,
          publicKey: session.invite.publicKey,
          sasCode: session.sasCode,
        );
        return Ok(unsealed);
      }

      final key = (await keyStore.read()).valueOrNull;
      if (key == null) {
        return const Err(HouseholdFailure('Chave da casa não encontrada.'));
      }

      return Ok(key);
    } catch (e) {
      return Err(PairingFailure('Falha ao confirmar pareamento', e));
    }
  }

  Future<SecretKey> _deriveTransportKey(
    List<int> publicKey,
    String sasCode,
  ) async {
    final normalizedSas = sasCode.replaceAll(RegExp(r'\s+'), '');
    final input = <int>[...publicKey, ...utf8.encode(normalizedSas)];
    final hash = await _sha256.hash(input);
    return SecretKey(hash.bytes);
  }

  Future<List<int>> sealHouseholdKey({
    required HouseholdKey householdKey,
    required List<int> publicKey,
    required String sasCode,
  }) async {
    final transportKey = await _deriveTransportKey(publicKey, sasCode);
    final secretBox = await _aesGcm.encrypt(
      householdKey.bytes,
      secretKey: transportKey,
    );
    return secretBox.concatenation();
  }

  Future<HouseholdKey> _unsealHouseholdKey({
    required List<int> sealedBytes,
    required List<int> publicKey,
    required String sasCode,
  }) async {
    final transportKey = await _deriveTransportKey(publicKey, sasCode);
    final secretBox = SecretBox.fromConcatenation(
      Uint8List.fromList(sealedBytes),
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );
    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: transportKey,
    );
    return HouseholdKey(clearBytes);
  }
}
