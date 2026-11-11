library;

import '../../../core/config/security_limits.dart';
import '../../../core/sync/domain/version_vector.dart';
import '../../../data/sync/tombstones.dart';

/// Pure policy for tombstone removal eligibility and compaction (RN-428, RN-429, CA-5.6).
final class CompactionPolicy {
  final SecurityLimits limits;

  const CompactionPolicy(this.limits);

  /// Removable tombstone: `(nowUtc - purgedAt) > limits.tombstoneRetention`
  /// E todo membro ativo em [acks] confirmou `ack[t.hlc.siteId] >= t.hlc`.
  bool canPurgeTombstone(
    RowTombstone t,
    Map<String, VersionVector> acks,
    DateTime nowUtc,
  ) {
    final purgedAtUtc = DateTime.tryParse(t.purgedAt)?.toUtc();
    if (purgedAtUtc == null) return false;

    final age = nowUtc.toUtc().difference(purgedAtUtc);
    if (age <= limits.tombstoneRetention) {
      return false;
    }

    for (final ackVector in acks.values) {
      if (!ackVector.covers(t.hlc)) {
        return false;
      }
    }

    return true;
  }
}
