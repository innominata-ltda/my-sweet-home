import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/natural_key_merger.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tables/sync_triggers.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// [HouseholdRepository] implementation over SQLite via Drift (RF-120, RF-125).
class DriftHouseholdRepository implements HouseholdRepository {
  final AppDatabase db;
  final HouseholdKeyStore keyStore;
  final SettingsRepository settingsRepository;
  final Clock clock;
  final IdGenerator idGenerator;

  AppDatabase get _db => db;
  HouseholdKeyStore get _keyStore => keyStore;
  SettingsRepository get _settingsRepository => settingsRepository;
  Clock get _clock => clock;
  IdGenerator get _idGenerator => idGenerator;

  final SyncTableRegistry _registry;
  final NaturalKeyMerger _naturalKeyMerger;

  DriftHouseholdRepository({
    required this.db,
    required this.keyStore,
    required this.settingsRepository,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7Generator(),
    SyncTableRegistry? registry,
    NaturalKeyMerger? naturalKeyMerger,
  }) : _registry = registry ?? SyncTableRegistryImpl(),
       _naturalKeyMerger = naturalKeyMerger ?? NaturalKeyMerger(clock: clock);

  @override
  Future<Result<Household?, Failure>> getHousehold() async {
    try {
      final rows =
          await (_db.select(_db.syncHouseholds)
                ..where((tbl) => tbl.active.equals(true))
                ..orderBy([(tbl) => OrderingTerm.desc(tbl.joinedAt)]))
              .get();

      if (rows.isEmpty) {
        return const Ok(null);
      }

      if (rows.length > 1) {
        // Auto-recovery: deactivates redundant households keeping most recent
        for (var i = 1; i < rows.length; i++) {
          await (_db.update(_db.syncHouseholds)
                ..where((tbl) => tbl.id.equals(rows[i].id)))
              .write(const SyncHouseholdsCompanion(active: Value(false)));
        }
      }

      return Ok(_mapHousehold(rows.first));
    } catch (e) {
      return Err(HouseholdFailure('Falha ao obter casa', e));
    }
  }

  @override
  Stream<Household?> watchHousehold() {
    return (_db.select(_db.syncHouseholds)
          ..where((tbl) => tbl.active.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.joinedAt)]))
        .watch()
        .map((rows) => rows.isEmpty ? null : _mapHousehold(rows.first));
  }

  @override
  Future<Result<List<Member>, Failure>> getMembers() async {
    try {
      final rows =
          await (_db.select(_db.syncMembers)
                ..where((tbl) => tbl.isActive.equals(true))
                ..orderBy([(tbl) => OrderingTerm.asc(tbl.joinedAt)]))
              .get();

      return Ok(rows.map(_mapMember).toList());
    } catch (e) {
      return Err(HouseholdFailure('Falha ao listar membros', e));
    }
  }

  @override
  Stream<List<Member>> watchMembers() {
    return (_db.select(_db.syncMembers)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.joinedAt)]))
        .watch()
        .map((rows) => rows.map(_mapMember).toList());
  }

  @override
  Future<Result<Household, Failure>> createHousehold({
    required String name,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
  }) async {
    try {
      await _settingsRepository.setHouseholdSyncAllowed(true);

      final householdId = _idGenerator.newId();
      final siteId = _idGenerator.newId();
      final memberId = _idGenerator.newId();
      final nowUtc = _clock.nowUtc();
      final nowIso = nowUtc.toIso8601String();

      final effectiveAreas = SyncTableRegistryImpl.effectiveAreas(sharedAreas);
      final areasString = effectiveAreas.map((a) => a.name).join(',');

      final household = Household(
        id: householdId,
        name: name,
        localSiteId: siteId,
        sharedAreas: effectiveAreas,
        createdAt: nowUtc,
        joinedAt: nowUtc,
      );

      await _db.transaction(() async {
        // Desativa qualquer casa ativa anterior
        await (_db.update(_db.syncHouseholds)
              ..where((tbl) => tbl.active.equals(true)))
            .write(const SyncHouseholdsCompanion(active: Value(false)));
        await (_db.update(_db.syncMembers)
              ..where((tbl) => tbl.isActive.equals(true)))
            .write(const SyncMembersCompanion(isActive: Value(false)));

        await _db
            .into(_db.syncHouseholds)
            .insertOnConflictUpdate(
              SyncHouseholdsCompanion.insert(
                id: householdId,
                name: name,
                localSiteId: siteId,
                sharedAreas: areasString,
                createdAt: nowIso,
                joinedAt: nowIso,
                active: const Value(true),
              ),
            );

        await _db
            .into(_db.syncMembers)
            .insert(
              SyncMembersCompanion.insert(
                id: memberId,
                householdId: householdId,
                siteId: siteId,
                name: deviceName,
                joinedAt: nowIso,
                lastSeenAt: Value(nowIso),
                isActive: const Value(true),
              ),
            );
      });

      final keyResult = await _keyStore.write(key);
      if (keyResult.isErr) {
        return Err(keyResult.failureOrNull!);
      }

      await runInitialBackfill(household);

      return Ok(household);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao criar casa', e));
    }
  }

  @override
  Future<Result<void, Failure>> updateSharedAreas(Set<SyncArea> areas) async {
    try {
      final effective = SyncTableRegistryImpl.effectiveAreas(areas);
      final areasString = effective.map((a) => a.name).join(',');

      await (_db.update(_db.syncHouseholds)
            ..where((tbl) => tbl.active.equals(true)))
          .write(SyncHouseholdsCompanion(sharedAreas: Value(areasString)));

      return const Ok(null);
    } catch (e) {
      return Err(
        HouseholdFailure('Falha ao atualizar áreas compartilhadas', e),
      );
    }
  }

  @override
  Future<Result<int, Failure>> runInitialBackfill(Household household) async {
    try {
      var count = 0;
      final nowMillis = _clock.nowUtc().millisecondsSinceEpoch;
      final hlc = Hlc.now(
        siteId: household.localSiteId,
        nowMillis: nowMillis,
      ).pack();
      final nowIso = _clock.nowUtc().toIso8601String();

      await _db.transaction(() async {
        for (final spec in _registry.tables) {
          final columns = SyncTriggers.syncedTablesAndColumns[spec.table];
          if (columns == null || columns.isEmpty) continue;

          final rows = await _db
              .customSelect('SELECT * FROM ${spec.table}')
              .get();
          for (final row in rows) {
            final rowId = row.data['id']?.toString();
            if (rowId == null) continue;

            final area = spec.areaOf(row.data);
            if (!household.sharedAreas.contains(area)) continue;

            for (final col in columns) {
              if (spec.excludedColumns.contains(col)) continue;

              final inserted = await _db.customInsert(
                'INSERT OR IGNORE INTO sync_column_versions '
                '(table_name, row_id, column_name, hlc, site_id, updated_at) '
                'VALUES (?, ?, ?, ?, ?, ?)',
                variables: [
                  Variable.withString(spec.table),
                  Variable.withString(rowId),
                  Variable.withString(col),
                  Variable.withString(hlc),
                  Variable.withString(household.localSiteId),
                  Variable.withString(nowIso),
                ],
              );
              if (inserted > 0) count++;
            }
          }
        }
      });

      return Ok(count);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao executar backfill inicial', e));
    }
  }

  @override
  Future<Result<bool, Failure>> hasPendingLocalChanges() async {
    try {
      final household = (await getHousehold()).valueOrNull;
      if (household == null) return const Ok(false);

      final members = (await getMembers()).valueOrNull ?? [];
      final otherMembers = members
          .where((m) => m.siteId != household.localSiteId && m.active)
          .toList();

      if (otherMembers.isEmpty) {
        // If this is the only device and local versions exist, changes exist only on this device (CA-6.1)
        final localCount = await _db
            .customSelect(
              'SELECT COUNT(*) AS c FROM sync_column_versions WHERE site_id = ?',
              variables: [Variable.withString(household.localSiteId)],
            )
            .getSingle();
        final c = localCount.data['c'] as int? ?? 0;
        return Ok(c > 0);
      }

      // If there are other members, verify if local versions are uncovered by peer vectors
      final pendingCount = await _db
          .customSelect(
            'SELECT COUNT(*) AS c FROM sync_column_versions v '
            'WHERE v.site_id = ? '
            'AND NOT EXISTS ('
            '  SELECT 1 FROM sync_peer_vectors p '
            '  WHERE p.site_id = v.site_id AND p.hlc >= v.hlc'
            ')',
            variables: [Variable.withString(household.localSiteId)],
          )
          .getSingle();

      final count = pendingCount.data['c'] as int? ?? 0;
      return Ok(count > 0);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao verificar mudanças pendentes', e));
    }
  }

  @override
  Future<Result<void, Failure>> leaveHousehold({required bool keepCopy}) async {
    try {
      final household = (await getHousehold()).valueOrNull;
      if (household == null) return const Ok(null);

      await _db.transaction(() async {
        if (!keepCopy) {
          // Apagar dados compartilhados (CA-7.3)
          for (final spec in _registry.tables) {
            if (spec.derived) continue;
            // Do not delete base products catalog
            if (spec.table != 'products' && spec.table != 'product_aliases') {
              await _db.customStatement('DELETE FROM ${spec.table}');
            }
          }
        }

        // Desativar a casa
        await (_db.update(_db.syncHouseholds)
              ..where((tbl) => tbl.id.equals(household.id)))
            .write(const SyncHouseholdsCompanion(active: Value(false)));

        // Limpar membros e metadados de sync
        await _db.delete(_db.syncMembers).go();
        await _db.customStatement('DELETE FROM sync_column_versions');
        await _db.customStatement('DELETE FROM sync_peer_vectors');
      });

      // Apagar chave segura e revogar consentimento
      await _keyStore.wipe();
      await _settingsRepository.setHouseholdSyncAllowed(false);

      return const Ok(null);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao sair da casa', e));
    }
  }

  @override
  Future<Result<HouseholdJoinPreviewData, Failure>> getJoinPreviewData() async {
    try {
      var homeCount = 0;
      var financeCount = 0;
      var catalogCount = 0;

      for (final spec in _registry.tables) {
        if (spec.derived) continue;

        if (spec.table == 'recurring_rules') {
          final homeRules = await _db
              .customSelect(
                "SELECT COUNT(*) AS c FROM recurring_rules WHERE kind = 'task'",
              )
              .getSingle();
          homeCount += homeRules.read<int>('c');

          final finRules = await _db
              .customSelect(
                "SELECT COUNT(*) AS c FROM recurring_rules WHERE kind IN ('expense', 'bill')",
              )
              .getSingle();
          financeCount += finRules.read<int>('c');
          continue;
        }

        final result = await _db
            .customSelect('SELECT COUNT(*) AS c FROM ${spec.table}')
            .getSingle();
        final count = result.read<int>('c');

        final area = spec.areaOf(const {});
        switch (area) {
          case SyncArea.home:
            homeCount += count;
            break;
          case SyncArea.finance:
            financeCount += count;
            break;
          case SyncArea.catalog:
            catalogCount += count;
            break;
        }
      }

      return Ok(
        HouseholdJoinPreviewData(
          homeRecordsCount: homeCount,
          financeRecordsCount: financeCount,
          catalogRecordsCount: catalogCount,
        ),
      );
    } catch (e) {
      return Err(HouseholdFailure('Falha ao obter prévia dos dados', e));
    }
  }

  @override
  Future<Result<Household, Failure>> joinHousehold({
    required String householdId,
    required String householdName,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
    List<Member> existingMembers = const [],
  }) async {
    try {
      await _settingsRepository.setHouseholdSyncAllowed(true);

      final keyResult = await _keyStore.write(key);
      if (keyResult.isErr) {
        return Err(keyResult.failureOrNull!);
      }

      final siteId = _idGenerator.newId();
      final selfMemberId = _idGenerator.newId();
      final nowUtc = _clock.nowUtc();
      final nowIso = nowUtc.toIso8601String();

      final effectiveAreas = SyncTableRegistryImpl.effectiveAreas(sharedAreas);
      final areasString = effectiveAreas.map((a) => a.name).join(',');

      final household = Household(
        id: householdId,
        name: householdName,
        localSiteId: siteId,
        sharedAreas: effectiveAreas,
        createdAt: nowUtc,
        joinedAt: nowUtc,
      );

      await _db.transaction(() async {
        // Desativa qualquer casa ativa anterior
        await (_db.update(_db.syncHouseholds)
              ..where((tbl) => tbl.active.equals(true)))
            .write(const SyncHouseholdsCompanion(active: Value(false)));
        await (_db.update(_db.syncMembers)
              ..where((tbl) => tbl.isActive.equals(true)))
            .write(const SyncMembersCompanion(isActive: Value(false)));

        await _db
            .into(_db.syncHouseholds)
            .insertOnConflictUpdate(
              SyncHouseholdsCompanion.insert(
                id: householdId,
                name: householdName,
                localSiteId: siteId,
                sharedAreas: areasString,
                createdAt: nowIso,
                joinedAt: nowIso,
                active: const Value(true),
              ),
            );

        await _db
            .into(_db.syncMembers)
            .insert(
              SyncMembersCompanion.insert(
                id: selfMemberId,
                householdId: householdId,
                siteId: siteId,
                name: deviceName,
                joinedAt: nowIso,
                lastSeenAt: Value(nowIso),
                isActive: const Value(true),
              ),
            );

        for (final m in existingMembers) {
          if (m.siteId == siteId) continue;
          await _db
              .into(_db.syncMembers)
              .insertOnConflictUpdate(
                SyncMembersCompanion.insert(
                  id: m.id,
                  householdId: householdId,
                  siteId: m.siteId,
                  name: m.name,
                  joinedAt: m.joinedAt.toUtc().toIso8601String(),
                  lastSeenAt: Value(m.lastSeenAt?.toUtc().toIso8601String()),
                  isActive: Value(m.active),
                ),
              );
        }
      });

      await runInitialBackfill(household);
      await _naturalKeyMerger.mergeAll(_db);

      return Ok(household);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao entrar na casa', e));
    }
  }

  @override
  Future<Result<void, Failure>> removeMember(String memberId) async {
    try {
      await (_db.update(_db.syncMembers)
            ..where((tbl) => tbl.id.equals(memberId)))
          .write(const SyncMembersCompanion(isActive: Value(false)));
      return const Ok(null);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao remover membro', e));
    }
  }

  @override
  Future<Result<void, Failure>> upsertMember({
    required String siteId,
    required String deviceName,
    DateTime? lastSeenAt,
  }) async {
    try {
      final household = (await getHousehold()).valueOrNull;
      if (household == null) return const Ok(null);
      if (siteId == household.localSiteId) return const Ok(null);

      final nowUtc = _clock.nowUtc();
      final nowIso = (lastSeenAt ?? nowUtc).toUtc().toIso8601String();

      final existing = await (_db.select(
        _db.syncMembers,
      )..where((tbl) => tbl.siteId.equals(siteId))).getSingleOrNull();

      if (existing == null) {
        await _db
            .into(_db.syncMembers)
            .insert(
              SyncMembersCompanion.insert(
                id: _idGenerator.newId(),
                householdId: household.id,
                siteId: siteId,
                name: deviceName.isEmpty ? 'Aparelho' : deviceName,
                joinedAt: nowIso,
                lastSeenAt: Value(nowIso),
                isActive: const Value(true),
              ),
            );
      } else {
        await (_db.update(
          _db.syncMembers,
        )..where((tbl) => tbl.id.equals(existing.id))).write(
          SyncMembersCompanion(
            name: deviceName.isNotEmpty
                ? Value(deviceName)
                : const Value.absent(),
            lastSeenAt: Value(nowIso),
            isActive: const Value(true),
          ),
        );
      }
      return const Ok(null);
    } catch (e) {
      return Err(HouseholdFailure('Falha ao atualizar membro', e));
    }
  }

  Household _mapHousehold(SyncHousehold row) {
    final areas = row.sharedAreas
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(
          (s) => SyncArea.values.firstWhere(
            (a) => a.name == s,
            orElse: () => SyncArea.home,
          ),
        )
        .toSet();

    return Household(
      id: row.id,
      name: row.name,
      localSiteId: row.localSiteId,
      sharedAreas: areas,
      createdAt: DateTime.parse(row.createdAt),
      joinedAt: DateTime.parse(row.joinedAt),
      active: row.active,
    );
  }

  Member _mapMember(SyncMember row) {
    return Member(
      id: row.id,
      householdId: row.householdId,
      siteId: row.siteId,
      name: row.name,
      joinedAt: DateTime.parse(row.joinedAt),
      lastSeenAt: row.lastSeenAt == null
          ? null
          : DateTime.parse(row.lastSeenAt!),
      active: row.isActive,
    );
  }
}
