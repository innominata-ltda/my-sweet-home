library;

import 'package:drift/drift.dart';

import '../../core/sync/domain/hlc.dart';
import '../../core/sync/domain/version_vector.dart';
import '../../core/time/clock.dart';
import '../database/database.dart';

/// Storage of version vector acknowledgments (acks) per household member (RN-428, RN-429).
final class MemberAckStore {
  final AppDatabase db;
  final Clock clock;

  MemberAckStore({required this.db, this.clock = const SystemClock()});

  /// Records (with monotonic merge by origin) the [senderVector] confirmed by [memberSiteId].
  Future<void> record(
    String householdId,
    String memberSiteId,
    VersionVector senderVector,
  ) async {
    if (householdId.isEmpty || memberSiteId.isEmpty) return;
    final nowIso = clock.nowUtc().toUtc().toIso8601String();

    for (final entry in senderVector.maxBySite.entries) {
      final originSiteId = entry.key;
      final hlcPacked = entry.value.pack();
      await db.customStatement(
        '''
        INSERT INTO sync_member_acks (household_id, member_site_id, origin_site_id, hlc, updated_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT (household_id, member_site_id, origin_site_id) DO UPDATE SET
          hlc = CASE WHEN excluded.hlc > sync_member_acks.hlc THEN excluded.hlc ELSE sync_member_acks.hlc END,
          updated_at = excluded.updated_at;
        ''',
        [householdId, memberSiteId, originSiteId, hlcPacked, nowIso],
      );
    }
  }

  /// Returns the acknowledgment vectors of all active members of the household [householdId].
  ///
  /// Members marked with `is_active = 0` in `sync_members` are ignored (RN-429).
  /// Active members in `sync_members` who have not yet sent an acknowledgment appear with [VersionVector.empty].
  Future<Map<String, VersionVector>> activeMemberAcks(
    String householdId,
  ) async {
    final memberRows = await db
        .customSelect(
          'SELECT site_id, is_active FROM sync_members WHERE household_id = ?;',
          variables: [Variable.withString(householdId)],
        )
        .get();

    final activeSites = <String>{};
    final inactiveSites = <String>{};
    for (final row in memberRows) {
      final siteId = row.data['site_id'] as String;
      final isActiveRaw = row.data['is_active'];
      final isActive = isActiveRaw == true || isActiveRaw == 1;
      if (isActive) {
        activeSites.add(siteId);
      } else {
        inactiveSites.add(siteId);
      }
    }

    final ackRows = await db
        .customSelect(
          'SELECT member_site_id, origin_site_id, hlc FROM sync_member_acks WHERE household_id = ?;',
          variables: [Variable.withString(householdId)],
        )
        .get();

    final mapByMember = <String, Map<String, Hlc>>{
      for (final siteId in activeSites) siteId: <String, Hlc>{},
    };

    for (final row in ackRows) {
      final memberSiteId = row.data['member_site_id'] as String;
      if (inactiveSites.contains(memberSiteId)) {
        continue;
      }
      final originSiteId = row.data['origin_site_id'] as String;
      final hlc = Hlc.parse(row.data['hlc'] as String);
      final origins = mapByMember.putIfAbsent(
        memberSiteId,
        () => <String, Hlc>{},
      );
      final current = origins[originSiteId];
      if (current == null || hlc.compareTo(current) > 0) {
        origins[originSiteId] = hlc;
      }
    }

    return {
      for (final entry in mapByMember.entries)
        entry.key: VersionVector(Map.unmodifiable(entry.value)),
    };
  }
}
