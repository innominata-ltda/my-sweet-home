library;

import 'dart:convert';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Falha indicando que o convite de pareamento ultrapassou o tempo limite (CA-1.2).
final class InviteExpiredFailure extends Failure {
  final String message;
  const InviteExpiredFailure([
    this.message = 'O convite expirou. Gere um novo convite para parear.',
  ]);

  @override
  String toString() => 'InviteExpiredFailure: $message';
}

/// Falha geral de pareamento.
final class PairingFailure extends Failure {
  final String message;
  final Object? cause;
  const PairingFailure(this.message, [this.cause]);

  @override
  String toString() => 'PairingFailure: $message';
}

/// Failure when maximum limit of 8 devices in household is reached (RN-306, CA-1.4).
final class MaxMembersFailure extends Failure {
  final String message;
  const MaxMembersFailure([
    this.message = 'A casa já atingiu o limite de 8 membros.',
  ]);

  @override
  String toString() => 'MaxMembersFailure: $message';
}

/// In-person invitation with QR code encoded payload.
final class Invite {
  final String householdId;
  final String householdName;
  final List<int> publicKey;
  final DateTime expiresAt;
  final String? lanHost;
  final int? lanPort;
  final List<int>? sealedKey;
  final List<String>? sharedAreas;
  final String? hostSiteId;
  final String? hostDeviceName;

  const Invite({
    required this.householdId,
    required this.householdName,
    required this.publicKey,
    required this.expiresAt,
    this.lanHost,
    this.lanPort,
    this.sealedKey,
    this.sharedAreas,
    this.hostSiteId,
    this.hostDeviceName,
  });

  bool isExpired(DateTime now) => now.isAfter(expiresAt);

  /// Derives deterministic 6-digit SAS code ("123 456") from ephemeral invite public key.
  String get sasCode => deriveSasFromPublicKey(publicKey);

  static String deriveSasFromPublicKey(List<int> pubKey) {
    if (pubKey.isEmpty) return '000 000';
    // 32-bit FNV-1a deterministic hash over X25519 public key bytes
    var hash = 0x811c9dc5;
    for (final b in pubKey) {
      hash ^= (b & 0xff);
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final num = hash % 1000000;
    final str = num.toString().padLeft(6, '0');
    return '${str.substring(0, 3)} ${str.substring(3)}';
  }

  String toQrString() {
    final map = {
      'h': householdId,
      'n': householdName,
      'k': base64Encode(publicKey),
      'e': expiresAt.toUtc().toIso8601String(),
      if (lanHost != null) 'lh': lanHost,
      if (lanPort != null) 'lp': lanPort,
      if (sealedKey != null) 'sk': base64Encode(sealedKey!),
      if (sharedAreas != null) 'sa': sharedAreas,
      if (hostSiteId != null) 'hs': hostSiteId,
      if (hostDeviceName != null) 'hn': hostDeviceName,
    };
    return 'mshsync://invite?data=${base64UrlEncode(utf8.encode(jsonEncode(map)))}';
  }

  static Invite fromQrString(String qr) {
    final trimmed = qr.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('QR code vazio');
    }
    String? data;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('data')) {
      data = uri.queryParameters['data'];
    } else if (!trimmed.contains('://')) {
      data = trimmed;
    }
    if (data == null || data.isEmpty) {
      throw const FormatException('QR code inválido');
    }
    final normalized = base64Url.normalize(data);
    final json = jsonDecode(
      utf8.decode(base64Url.decode(normalized)),
    ) as Map<String, dynamic>;
    return Invite(
      householdId: json['h'] as String,
      householdName: json['n'] as String,
      publicKey: base64Decode(json['k'] as String),
      expiresAt: DateTime.parse(json['e'] as String),
      lanHost: json['lh'] as String?,
      lanPort: json['lp'] as int?,
      sealedKey: json['sk'] != null ? base64Decode(json['sk'] as String) : null,
      sharedAreas: (json['sa'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      hostSiteId: json['hs'] as String?,
      hostDeviceName: json['hn'] as String?,
    );
  }
}

/// Pairing session with 6-digit confirmation code (Short Authentication String - SAS).
final class PairingSession {
  final String sessionId;
  final Invite invite;
  final List<int> guestPublicKey;
  final String sasCode;

  const PairingSession({
    required this.sessionId,
    required this.invite,
    required this.guestPublicKey,
    required this.sasCode,
  });
}

/// In-person pairing channel between two devices via QR and SAS confirmation (RN-303, RN-304, CA-1.1..CA-1.4).
abstract interface class PairingChannel {
  /// Generates invite (QR code payload) with limited lifetime (default: 10 minutes).
  Future<Result<Invite, Failure>> openInvite({
    Duration ttl = const Duration(minutes: 10),
    String? lanHost,
    int? lanPort,
  });

  /// Joins household by reading [invite]. Returns session with 6-digit code (SAS).
  Future<Result<PairingSession, Failure>> join(Invite invite);

  /// Confirms session after mutual validation of 6-digit code.
  /// If [accepted] is true, concludes [HouseholdKey] exchange.
  Future<Result<HouseholdKey, Failure>> confirm(
    PairingSession session, {
    required bool accepted,
  });
}
