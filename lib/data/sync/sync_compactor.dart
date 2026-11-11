library;

import 'package:drift/drift.dart';

import '../../core/config/security_limits.dart';
import '../../core/sync/domain/hlc.dart';
import '../../core/sync/domain/version_vector.dart';
import '../../core/time/clock.dart';
import '../../features/sync/domain/compaction_policy.dart';
import '../database/database.dart';
import 'member_ack_store.dart';
import 'tombstones.dart';

/// Execution report of sync metadata compaction (RN-428, RN-429).
final class CompactionReport {
  final int purgedTombstonesCount;
  final int purgedColumnVersionsCount;
  final VersionVector newHorizon;

  const CompactionReport({
    this.purgedTombstonesCount = 0,
    this.purgedColumnVersionsCount = 0,
    this.newHorizon = VersionVector.empty,
  });

  @override
  String toString() =>
      'CompactionReport(tombstones: $purgedTombstonesCount, columnVersions: $purgedColumnVersionsCount, horizon: $newHorizon)';
}

/// Compactor of tombstones and sync metadata (RN-428, RN-429, CA-5.5, CA-5.6, CA-5.7).
final class SyncCompactor {
  final AppDatabase db;
  final MemberAckStore memberAckStore;
  final TombstoneStore tombstoneStore;
  final CompactionPolicy policy;
  final Clock clock;
  final String? householdId;

  SyncCompactor({
    required this.db,
    MemberAckStore? memberAckStore,
    TombstoneStore? tombstoneStore,
    CompactionPolicy? policy,
    this.clock = const SystemClock(),
    this.householdId,
  }) : memberAckStore = memberAckStore ?? MemberAckStore(db: db, clock: clock),
       tombstoneStore = tombstoneStore ?? TombstoneStore(db: db, clock: clock),
       policy = policy ?? const CompactionPolicy(SecurityLimits());

  /// Removes eligible tombstones + `column_versions` of those tombstone rows and advances horizon by origin.
  Future<CompactionReport> compact() async {
    final resolvedHouseholdId = await _resolveHouseholdId();
    if (resolvedHouseholdId == null) {
      return const CompactionReport();
    }

    final acks = await memberAckStore.activeMemberAcks(resolvedHouseholdId);
    if (acks.isEmpty) {
      return CompactionReport(newHorizon: await horizon());
    }

    final nowUtc = clock.nowUtc();
    final allTombstones = await tombstoneStore.getAllTombstones();

    var purgedTombstones = 0;
    var purgedColumnVersions = 0;

    await db.transaction(() async {
      final horizonUpdates = <String, Hlc>{};

      void trackHorizon(Hlc hlc) {
        final cur = horizonUpdates[hlc.siteId];
        if (cur == null || hlc.compareTo(cur) > 0) {
          horizonUpdates[hlc.siteId] = hlc;
        }
      }

      for (final tombstone in allTombstones) {
        final allAcked = acks.values.every((v) => v.covers(tombstone.hlc));

        // If all active members already confirmed the tombstone, residual column versions are superseded (CA-5.5)
        if (allAcked) {
          final cvRows = await db
              .customSelect(
                'SELECT hlc FROM sync_column_versions WHERE table_name = ? AND row_id = ?;',
                variables: [
                  Variable.withString(tombstone.table),
                  Variable.withString(tombstone.rowId),
                ],
              )
              .get();
          for (final row in cvRows) {
            trackHorizon(Hlc.parse(row.data['hlc'] as String));
          }
          if (cvRows.isNotEmpty) {
            await db.customStatement(
              'DELETE FROM sync_column_versions WHERE table_name = ? AND row_id = ?;',
              [tombstone.table, tombstone.rowId],
            );
            purgedColumnVersions += cvRows.length;
          }
        }

        // Eligible tombstone (retention > 90 days + all active acks) is removed and advances horizon (CA-5.6, CA-5.7)
        if (policy.canPurgeTombstone(tombstone, acks, nowUtc)) {
          await db.customStatement(
            'DELETE FROM sync_row_tombstones WHERE id = ?;',
            [tombstone.id],
          );
          purgedTombstones++;
          trackHorizon(tombstone.hlc);
        }
      }

      // When tombstones are purged, also advance the common horizon confirmed by all active members per origin
      if (purgedTombstones > 0 && acks.isNotEmpty) {
        final allOrigins = <String>{};
        for (final v in acks.values) {
          allOrigins.addAll(v.maxBySite.keys);
        }
        for (final origin in allOrigins) {
          Hlc? minAckedForOrigin;
          var coveredByAll = true;
          for (final v in acks.values) {
            final memberHlc = v.maxBySite[origin];
            if (memberHlc == null) {
              coveredByAll = false;
              break;
            }
            if (minAckedForOrigin == null ||
                memberHlc.compareTo(minAckedForOrigin) < 0) {
              minAckedForOrigin = memberHlc;
            }
          }
          if (coveredByAll && minAckedForOrigin != null) {
            trackHorizon(minAckedForOrigin);
          }
        }
      }

      for (final entry in horizonUpdates.entries) {
        await db.customStatement(
          '''
          INSERT INTO sync_compaction_horizon (household_id, origin_site_id, hlc)
          VALUES (?, ?, ?)
          ON CONFLICT (household_id, origin_site_id) DO UPDATE SET
            hlc = CASE WHEN excluded.hlc > sync_compaction_horizon.hlc THEN excluded.hlc ELSE sync_compaction_horizon.hlc END;
          ''',
          [resolvedHouseholdId, entry.key, entry.value.pack()],
        );
      }
    });

    final updatedHorizon = await horizon();
    return CompactionReport(
      purgedTombstonesCount: purgedTombstones,
      purgedColumnVersionsCount: purgedColumnVersions,
      newHorizon: updatedHorizon,
    );
  }

  /// Returns the current compaction horizon vector of the active household.
  Future<VersionVector> horizon() async {
    final resolvedHouseholdId = await _resolveHouseholdId();
    if (resolvedHouseholdId == null) {
      return VersionVector.empty;
    }

    final rows = await db
        .customSelect(
          'SELECT origin_site_id, hlc FROM sync_compaction_horizon WHERE household_id = ?;',
          variables: [Variable.withString(resolvedHouseholdId)],
        )
        .get();

    final map = <String, Hlc>{};
    for (final row in rows) {
      final originSiteId = row.data['origin_site_id'] as String;
      final hlc = Hlc.parse(row.data['hlc'] as String);
      final current = map[originSiteId];
      if (current == null || hlc.compareTo(current) > 0) {
        map[originSiteId] = hlc;
      }
    }
    return VersionVector(Map.unmodifiable(map));
  }

  Future<String?> _resolveHouseholdId() async {
    if (householdId != null && householdId!.isNotEmpty) {
      return householdId;
    }
    final activeRows = await db
        .customSelect('SELECT id FROM sync_household WHERE active = 1 LIMIT 1;')
        .get();
    if (activeRows.isNotEmpty) {
      return activeRows.first.data['id'] as String;
    }
    final memberRows = await db
        .customSelect('SELECT household_id FROM sync_members LIMIT 1;')
        .get();
    if (memberRows.isNotEmpty) {
      return memberRows.first.data['household_id'] as String;
    }
    final ackRows = await db
        .customSelect('SELECT household_id FROM sync_member_acks LIMIT 1;')
        .get();
    if (ackRows.isNotEmpty) {
      return ackRows.first.data['household_id'] as String;
    }
    final horizonRows = await db
        .customSelect(
          'SELECT household_id FROM sync_compaction_horizon LIMIT 1;',
        )
        .get();
    if (horizonRows.isNotEmpty) {
      return horizonRows.first.data['household_id'] as String;
    }
    return null;
  }
}
