library;

import 'column_version.dart';
import 'hlc.dart';

/// LWW (Last-Write-Wins) per-column merge algorithm.
///
/// Implements RN-320, RN-321, RN-322, and RN-323:
/// - Idempotent: applying the same version multiple times has no side effects.
/// - Commutative: arrival order of batches/versions produces the same final state.
/// - Associative: intermediate groupings do not alter the winning version.
abstract interface class LwwMerge {
  const factory LwwMerge() = DefaultLwwMerge;

  /// Returns incoming versions that supersede the local state.
  ///
  /// An incoming version wins if:
  /// 1. There is no local version for the key ([ColumnVersion.key]); OR
  /// 2. Its HLC is strictly greater than local HLC ([Hlc.compareTo] > 0).
  ///
  /// If there are multiple versions for the same key in [incoming],
  /// only the highest HLC version competes against local state.
  List<ColumnVersion> winners(
    List<ColumnVersion> incoming,
    Map<String, Hlc> localByKey,
  );
}

/// Standard deterministic implementation of [LwwMerge].
final class DefaultLwwMerge implements LwwMerge {
  const DefaultLwwMerge();

  @override
  List<ColumnVersion> winners(
    List<ColumnVersion> incoming,
    Map<String, Hlc> localByKey,
  ) {
    if (incoming.isEmpty) return const [];

    // 1. Deduplicate incoming by key, keeping strictly highest HLC version.
    final bestIncomingByKey = <String, ColumnVersion>{};
    for (final candidate in incoming) {
      final current = bestIncomingByKey[candidate.key];
      if (current == null || candidate.hlc.compareTo(current.hlc) > 0) {
        bestIncomingByKey[candidate.key] = candidate;
      }
    }

    // 2. Filter against localByKey: only wins if strictly greater than local HLC.
    final winningList = <ColumnVersion>[];
    for (final entry in bestIncomingByKey.entries) {
      final key = entry.key;
      final winningCandidate = entry.value;
      final localHlc = localByKey[key];

      if (localHlc == null || winningCandidate.hlc.compareTo(localHlc) > 0) {
        winningList.add(winningCandidate);
      }
    }

    // 3. Deterministic sorting by key for full reproducibility.
    winningList.sort((a, b) => a.key.compareTo(b.key));
    return winningList;
  }
}
