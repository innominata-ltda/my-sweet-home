library;

import 'dart:convert';

import '../../../../core/result/result.dart';
import '../../../../core/sync/domain/column_version.dart';
import '../../../../core/sync/domain/version_vector.dart';
import '../../../../data/sync/tombstones.dart';

/// 256-bit symmetric key (AES-256-GCM) for shared household (ADR-0007, RN-302).
final class HouseholdKey {
  final List<int> bytes;

  const HouseholdKey(this.bytes);

  factory HouseholdKey.fromBase64(String encoded) =>
      HouseholdKey(base64Decode(encoded));

  String toBase64() => base64Encode(bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdKey &&
          runtimeType == other.runtimeType &&
          _listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Cryptographic integrity failure or packet tampering (CA-4.2).
final class IntegrityFailure extends Failure {
  final String detail;
  final Object? cause;

  const IntegrityFailure({required this.detail, this.cause});

  @override
  String toString() => 'IntegrityFailure($detail)';
}

/// Sync protocol version incompatibility failure (CA-5.8, RN-329).
final class IncompatibleProtocolFailure extends Failure {
  final int batchVersion;
  final int supportedVersion;
  final String message;

  const IncompatibleProtocolFailure({
    required this.batchVersion,
    required this.supportedVersion,
    this.message = 'Atualize o app para sincronizar com a casa.',
  });

  @override
  String toString() => 'IncompatibleProtocolFailure($message)';
}

/// Sync batch with column versions, tombstones and optional live rows manifest (RN-328, RN-329, RN-429).
final class SyncBatch {
  static const int currentProtocolVersion = 1;

  final int protocolVersion;
  final String householdId;
  final String fromSiteId;
  final VersionVector senderVector;
  final List<ColumnVersion> changes;
  final List<RowTombstone> purged;
  final Map<String, List<String>>? liveRowManifest;

  const SyncBatch({
    this.protocolVersion = currentProtocolVersion,
    required this.householdId,
    required this.fromSiteId,
    required this.senderVector,
    this.changes = const [],
    this.purged = const [],
    this.liveRowManifest,
  });

  Map<String, dynamic> toJson() => {
    'protocol_version': protocolVersion,
    'household_id': householdId,
    'from_site_id': fromSiteId,
    'sender_vector': senderVector.toJson(),
    'changes': changes.map((c) => c.toJson()).toList(),
    'purged': purged.map((t) => t.toJson()).toList(),
    if (liveRowManifest != null) 'live_row_manifest': liveRowManifest,
  };

  factory SyncBatch.fromJson(Map<String, dynamic> json) {
    final rawManifest = json['live_row_manifest'] as Map?;
    final liveRowManifest = rawManifest?.map(
      (k, v) =>
          MapEntry(k as String, (v as List).map((e) => e as String).toList()),
    );
    return SyncBatch(
      protocolVersion: (json['protocol_version'] as num?)?.toInt() ?? 1,
      householdId: json['household_id'] as String,
      fromSiteId: json['from_site_id'] as String,
      senderVector: VersionVector.fromJson(
        (json['sender_vector'] as Map).cast<String, dynamic>(),
      ),
      changes: ((json['changes'] as List?) ?? const [])
          .map((c) => ColumnVersion.fromJson(c as Map<String, dynamic>))
          .toList(),
      purged: ((json['purged'] as List?) ?? const [])
          .map((t) => RowTombstone.fromJson(t as Map<String, dynamic>))
          .toList(),
      liveRowManifest: liveRowManifest,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncBatch &&
          runtimeType == other.runtimeType &&
          protocolVersion == other.protocolVersion &&
          householdId == other.householdId &&
          fromSiteId == other.fromSiteId &&
          senderVector == other.senderVector &&
          _listEquals(changes, other.changes) &&
          _listEquals(purged, other.purged) &&
          _manifestEquals(liveRowManifest, other.liveRowManifest);

  @override
  int get hashCode => Object.hash(
    protocolVersion,
    householdId,
    fromSiteId,
    senderVector,
    Object.hashAll(changes),
    Object.hashAll(purged),
  );

  static bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _manifestEquals(
    Map<String, List<String>>? a,
    Map<String, List<String>>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherList = b[entry.key];
      if (otherList == null || !_listEquals(entry.value, otherList)) {
        return false;
      }
    }
    return true;
  }
}
