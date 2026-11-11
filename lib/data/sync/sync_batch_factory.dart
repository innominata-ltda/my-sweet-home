library;

import '../../core/result/result.dart';
import '../../core/sync/domain/sync_table_registry.dart';
import '../../core/sync/domain/version_vector.dart';
import '../../core/time/clock.dart';
import '../../features/sync/domain/ports/household_repository.dart';
import '../database/database.dart';
import 'batch_applier.dart';
import 'change_source.dart';
import 'sync_compactor.dart';
import 'sync_table_registry_impl.dart';
import 'tombstones.dart';

/// Single constructor for outbound [SyncBatch] with compaction horizon support
/// and live row manifest for complete resynchronization (RN-429, CA-5.7).
final class SyncBatchFactory {
  final AppDatabase db;
  final ChangeSource changeSource;
  final TombstoneStore tombstoneStore;
  final SyncCompactor compactor;
  final SyncTableRegistry registry;
  final HouseholdRepository? householdRepository;
  final Clock clock;

  SyncBatchFactory({
    required this.db,
    ChangeSource? changeSource,
    TombstoneStore? tombstoneStore,
    SyncCompactor? compactor,
    SyncTableRegistry? registry,
    this.householdRepository,
    this.clock = const SystemClock(),
  }) : registry = registry ?? SyncTableRegistryImpl(),
       changeSource =
           changeSource ??
           DriftChangeSource(
             db: db,
             registry: registry ?? SyncTableRegistryImpl(),
           ),
       tombstoneStore = tombstoneStore ?? TombstoneStore(db: db, clock: clock),
       compactor = compactor ?? SyncCompactor(db: db, clock: clock);

  /// Builds the [SyncBatch] for a recipient with known version vector [recipientVector].
  ///
  /// If [recipientVector] is below the local compaction horizon (or is `null`
  /// when compaction has already occurred), includes `liveRowManifest` with live IDs per
  /// shared table and sends a full sync so the recipient removes compacted records
  /// without resurrecting them (RN-429, CA-5.7).
  Future<Result<SyncBatch, Failure>> forRecipient(
    VersionVector? recipientVector,
  ) async {
    try {
      final householdInfo = await _resolveHouseholdInfo();
      if (householdInfo == null) {
        return const Err(
          StorageFailure(detail: 'No active household to build batch.'),
        );
      }

      final currentHorizon = await compactor.horizon();
      final belowHorizon = _isBelowHorizon(recipientVector, currentHorizon);

      final effectivePeerVector = belowHorizon
          ? VersionVector.empty
          : (recipientVector ?? VersionVector.empty);

      final changesRes = await changeSource.changesNotCoveredBy(
        effectivePeerVector,
        householdInfo.sharedAreas,
      );
      if (changesRes.isErr) {
        return Err(changesRes.failureOrNull!);
      }

      final changes = changesRes.valueOrNull ?? const [];
      final tombstones = await tombstoneStore.getAllTombstones();
      final localVector = (await changeSource.localVector()).merge(
        currentHorizon,
      );

      Map<String, List<String>>? liveRowManifest;
      if (belowHorizon) {
        liveRowManifest = await _buildLiveRowManifest(
          householdInfo.sharedAreas,
        );
      }

      return Ok(
        SyncBatch(
          householdId: householdInfo.id,
          fromSiteId: householdInfo.localSiteId,
          senderVector: localVector,
          changes: changes,
          purged: tombstones,
          liveRowManifest: liveRowManifest,
        ),
      );
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Failed to build sync batch: $e', cause: e),
      );
    }
  }

  bool _isBelowHorizon(
    VersionVector? recipientVector,
    VersionVector currentHorizon,
  ) {
    if (currentHorizon.maxBySite.isEmpty) {
      return false;
    }
    if (recipientVector == null) {
      return true;
    }
    for (final hlc in currentHorizon.maxBySite.values) {
      if (!recipientVector.covers(hlc)) {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, List<String>>> _buildLiveRowManifest(
    Set<SyncArea> sharedAreas,
  ) async {
    final manifest = <String, List<String>>{};

    for (final table in DriftBatchApplier.tableDependencyOrder) {
      final spec = registry.findTable(table);
      if (spec == null || spec.derived) continue;

      final rows = await db.customSelect('SELECT * FROM $table;').get();
      final liveIds = <String>[];

      for (final row in rows) {
        final data = row.data;
        if (!sharedAreas.contains(spec.areaOf(data))) {
          continue;
        }
        if (table == 'recipe_tags') {
          final recipeId = data['recipe_id'] as String?;
          final tag = data['tag'] as String?;
          if (recipeId != null && tag != null) {
            liveIds.add('$recipeId:$tag');
          }
        } else {
          final id = data['id'] as String?;
          if (id != null) {
            liveIds.add(id);
          }
        }
      }

      manifest[table] = liveIds;
    }

    return manifest;
  }

  Future<_HouseholdMeta?> _resolveHouseholdInfo() async {
    if (householdRepository != null) {
      final res = await householdRepository!.getHousehold();
      final h = res.valueOrNull;
      if (h != null) {
        return _HouseholdMeta(
          id: h.id,
          localSiteId: h.localSiteId,
          sharedAreas: h.sharedAreas,
        );
      }
    }

    final rows = await db
        .customSelect(
          'SELECT id, local_site_id, shared_areas FROM sync_household WHERE active = 1 LIMIT 1;',
        )
        .get();
    if (rows.isEmpty) return null;

    final data = rows.first.data;
    final id = data['id'] as String;
    final localSiteId = data['local_site_id'] as String;
    final areasRaw = (data['shared_areas'] as String?) ?? '';
    final areas = <SyncArea>{};
    for (final part in areasRaw.split(',')) {
      final trimmed = part.trim();
      for (final area in SyncArea.values) {
        if (area.name == trimmed) {
          areas.add(area);
        }
      }
    }
    return _HouseholdMeta(
      id: id,
      localSiteId: localSiteId,
      sharedAreas: areas.isEmpty ? SyncArea.values.toSet() : areas,
    );
  }
}

final class _HouseholdMeta {
  final String id;
  final String localSiteId;
  final Set<SyncArea> sharedAreas;

  const _HouseholdMeta({
    required this.id,
    required this.localSiteId,
    required this.sharedAreas,
  });
}
