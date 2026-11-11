library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/result/result.dart';
import '../../core/sync/domain/column_version.dart';
import '../../core/sync/domain/derived_data_rebuilder.dart';
import '../../core/sync/domain/hlc.dart';
import '../../core/sync/domain/lww_merge.dart';
import '../../core/sync/domain/sync_applied_event.dart';
import '../../core/sync/domain/sync_table_registry.dart';
import '../../core/sync/domain/version_vector.dart';
import '../../core/time/clock.dart';
import '../../features/sync/domain/sync_batch.dart';
import '../database/database.dart';
import 'change_capture.dart';
import 'member_ack_store.dart';
import 'natural_key_merger.dart';
import 'sync_table_registry_impl.dart';
import 'tables/sync_triggers.dart';
import 'tombstones.dart';

export '../../features/sync/domain/sync_batch.dart';

/// Sync batch application report.
final class ApplyReport {
  /// Total number of columns successfully updated.
  final int appliedChangesCount;

  /// Total number of applied tombstones (purged rows).
  final int appliedTombstonesCount;

  /// Names of tables affected by application.
  final Set<String> touchedTables;

  /// Identifiers of rows affected by application.
  final Set<String> touchedRowIds;

  /// Indicates whether bundle had already been applied previously (RN-409, CA-2.7).
  final bool alreadyApplied;

  const ApplyReport({
    this.appliedChangesCount = 0,
    this.appliedTombstonesCount = 0,
    this.touchedTables = const {},
    this.touchedRowIds = const {},
    this.alreadyApplied = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplyReport &&
          runtimeType == other.runtimeType &&
          appliedChangesCount == other.appliedChangesCount &&
          appliedTombstonesCount == other.appliedTombstonesCount &&
          alreadyApplied == other.alreadyApplied &&
          _setEquals(touchedTables, other.touchedTables) &&
          _setEquals(touchedRowIds, other.touchedRowIds);

  @override
  int get hashCode => Object.hash(
    appliedChangesCount,
    appliedTombstonesCount,
    alreadyApplied,
    Object.hashAll(touchedTables),
    Object.hashAll(touchedRowIds),
  );

  @override
  String toString() =>
      'ApplyReport(changes: $appliedChangesCount, purged: $appliedTombstonesCount, alreadyApplied: $alreadyApplied, tables: ${touchedTables.length}, rows: ${touchedRowIds.length})';

  static bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Contract for sync batch applier (RN-328).
abstract interface class BatchApplier {
  /// Atomically applies a received [batch] of changes.
  ///
  /// Guarantees:
  /// 1. Full atomicity (SQLite transaction): either applies all successfully or reverts 100%;
  /// 2. Echo suppression (local triggers do not generate new versions when applying remote changes);
  /// 3. LWW-register resolution per column (RN-320, RN-321);
  /// 4. Suppression of changes to rows purged by tombstone (RN-322);
  /// 5. Atomic update of known version vector (`sync_peer_vectors`).
  Future<Result<ApplyReport, Failure>> apply(SyncBatch batch);

  /// Stream of events emitted when a batch is successfully applied.
  Stream<SyncAppliedEvent> get onBatchApplied;

  /// Releases resources and closes stream controllers.
  void dispose();
}

/// Drift/SQLite implementation of [BatchApplier].
class DriftBatchApplier implements BatchApplier {
  final AppDatabase db;
  final SyncTableRegistry registry;
  final ChangeCapture changeCapture;
  final LwwMerge lwwMerge;
  final NaturalKeyMerger naturalKeyMerger;
  final List<DerivedDataRebuilder> rebuilders;
  final Clock clock;

  final StreamController<SyncAppliedEvent> _appliedEventsController =
      StreamController<SyncAppliedEvent>.broadcast();

  DriftBatchApplier({
    required this.db,
    SyncTableRegistry? registry,
    ChangeCapture? changeCapture,
    this.lwwMerge = const DefaultLwwMerge(),
    this.naturalKeyMerger = const NaturalKeyMerger(),
    this.rebuilders = const [],
    this.clock = const SystemClock(),
  }) : registry = registry ?? SyncTableRegistryImpl(),
       changeCapture = changeCapture ?? ChangeCapture(db: db, clock: clock);

  /// Current protocol version supported by this application version.
  static const int currentProtocolVersion = 1;

  /// Topological dependency order between tables for inserts and updates.
  /// Parents must be inserted before children to satisfy foreign keys.
  static const List<String> tableDependencyOrder = [
    'categories',
    'stores',
    'products',
    'product_aliases',
    'recipes',
    'recipe_tags',
    'recipe_ingredients',
    'shopping_lists',
    'shopping_items',
    'recurring_rules',
    'bills',
    'purchases',
    'purchase_items',
    'bill_payments',
    'expenses',
    'budgets',
    'tasks',
    'stock_items',
    'checklist_items',
  ];

  @override
  Stream<SyncAppliedEvent> get onBatchApplied =>
      _appliedEventsController.stream;

  @override
  void dispose() {
    _appliedEventsController.close();
  }

  @override
  Future<Result<ApplyReport, Failure>> apply(SyncBatch batch) async {
    // 1. Validate protocol version (RN-329, CA-5.8)
    if (batch.protocolVersion != currentProtocolVersion) {
      return Err(
        ValidationFailure(
          fields: {
            'protocol_version':
                'Incompatible protocol version (${batch.protocolVersion}). '
                'Update the app to synchronize with the household',
          },
        ),
      );
    }

    // 2. Validate basic metadata integrity
    if (batch.householdId.trim().isEmpty || batch.fromSiteId.trim().isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'batch': 'householdId and fromSiteId cannot be empty.'},
        ),
      );
    }

    // 3. Validate tables and columns of changes (security / integrity)
    for (final change in batch.changes) {
      final spec = registry.findTable(change.table);
      if (spec == null || spec.derived) {
        return Err(
          ValidationFailure(
            fields: {
              'table': 'Non-syncable or invalid table: "${change.table}".',
            },
          ),
        );
      }
      final allowedCols = SyncTriggers.syncedTablesAndColumns[change.table];
      final isSyncable =
          allowedCols != null && allowedCols.contains(change.column);
      final isExcluded = spec.excludedColumns.contains(change.column);
      if (!isSyncable && !isExcluded) {
        return Err(
          ValidationFailure(
            fields: {
              'column':
                  'Non-syncable or unknown column: "${change.table}.${change.column}".',
            },
          ),
        );
      }
    }

    // 4. Validate tombstone tables
    for (final tombstone in batch.purged) {
      final spec = registry.findTable(tombstone.table);
      if (spec == null || spec.derived) {
        return Err(
          ValidationFailure(
            fields: {
              'purged_table': 'Invalid tombstone table: "${tombstone.table}".',
            },
          ),
        );
      }
    }

    try {
      // Run under remote echo guard to disable local triggers
      final report = await changeCapture.runAsRemote(() async {
        return await db.transaction(() async {
          // Defer foreign keys to check only at transaction commit
          await db.customStatement('PRAGMA defer_foreign_keys = ON;');

          final touchedTables = <String>{};
          final touchedRowIds = <String>{};
          int appliedChangesCount = 0;
          int appliedTombstonesCount = 0;

          // A. Load existing local tombstones and compaction horizon
          final localTombstonesMap = <String, Hlc>{};
          final tombstoneRows = await db
              .customSelect(
                'SELECT table_name, row_id, hlc FROM sync_row_tombstones',
              )
              .get();
          for (final row in tombstoneRows) {
            final t = row.data['table_name'] as String;
            final r = row.data['row_id'] as String;
            localTombstonesMap['$t:$r'] = Hlc.parse(row.data['hlc'] as String);
          }

          var horizonVector = VersionVector.empty;
          final horizonRows = await db
              .customSelect(
                'SELECT origin_site_id, hlc FROM sync_compaction_horizon WHERE household_id = ?;',
                variables: [Variable.withString(batch.householdId)],
              )
              .get();
          for (final row in horizonRows) {
            horizonVector = horizonVector.update(
              Hlc.parse(row.data['hlc'] as String),
            );
          }
          if (horizonVector.maxBySite.isEmpty) {
            final allHorizonRows = await db
                .customSelect('SELECT hlc FROM sync_compaction_horizon;')
                .get();
            for (final row in allHorizonRows) {
              horizonVector = horizonVector.update(
                Hlc.parse(row.data['hlc'] as String),
              );
            }
          }

          // B. Aplicar tombstones remotos (batch.purged) em ordem reversa
          final sortedPurged = List<RowTombstone>.from(batch.purged)
            ..sort((a, b) => _compareTableReverseOrder(a.table, b.table));

          for (final tombstone in sortedPurged) {
            final key = '${tombstone.table}:${tombstone.rowId}';
            final localHlc = localTombstonesMap[key];

            // If local already has tombstone with greater or equal HLC, ignore
            if (localHlc != null && localHlc.compareTo(tombstone.hlc) >= 0) {
              continue;
            }

            // Disconnect FK references to avoid constraint violations
            await _disconnectForeignKeysForDelete(
              tombstone.table,
              tombstone.rowId,
            );

            // Physically delete the row in the local database
            if (tombstone.table == 'recipe_tags') {
              final parts = tombstone.rowId.split(':');
              final recipeId = parts[0];
              final tag = parts.length > 1 ? parts.sublist(1).join(':') : '';
              await db.customStatement(
                'DELETE FROM recipe_tags WHERE recipe_id = ? AND tag = ?;',
                [recipeId, tag],
              );
            } else {
              await db.customStatement(
                'DELETE FROM ${tombstone.table} WHERE id = ?;',
                [tombstone.rowId],
              );
            }

            // Clean up column versions recorded for this row
            await db.customStatement(
              'DELETE FROM sync_column_versions WHERE table_name = ? AND row_id = ?;',
              [tombstone.table, tombstone.rowId],
            );

            // Save tombstone in sync_row_tombstones
            await db.customStatement(
              '''
              INSERT OR REPLACE INTO sync_row_tombstones (id, table_name, row_id, hlc, purged_at)
              VALUES (?, ?, ?, ?, ?);
              ''',
              [
                tombstone.id,
                tombstone.table,
                tombstone.rowId,
                tombstone.hlc.pack(),
                tombstone.purgedAt,
              ],
            );
            localTombstonesMap[key] = tombstone.hlc;

            touchedTables.add(tombstone.table);
            touchedRowIds.add(tombstone.rowId);
            appliedTombstonesCount++;
          }

          // B2. Aplicar liveRowManifest apagando linhas locais <= horizonte ausentes no manifesto (RN-429, CA-5.7)
          if (batch.liveRowManifest != null) {
            var effectiveManifestHorizon = horizonVector.merge(
              batch.senderVector,
            );
            for (final ch in batch.changes) {
              effectiveManifestHorizon = effectiveManifestHorizon.update(
                ch.hlc,
              );
            }
            for (final p in batch.purged) {
              effectiveManifestHorizon = effectiveManifestHorizon.update(p.hlc);
            }

            final manifestTables = batch.liveRowManifest!.keys.toList()
              ..sort(_compareTableReverseOrder);

            for (final table in manifestTables) {
              final spec = registry.findTable(table);
              if (spec == null || spec.derived) continue;

              final liveIds = batch.liveRowManifest![table]!.toSet();
              final localRows = await db
                  .customSelect(
                    table == 'recipe_tags'
                        ? 'SELECT recipe_id, tag FROM recipe_tags;'
                        : 'SELECT id FROM $table;',
                  )
                  .get();

              for (final row in localRows) {
                final String localRowId;
                if (table == 'recipe_tags') {
                  final recipeId = row.data['recipe_id'] as String?;
                  final tag = row.data['tag'] as String?;
                  if (recipeId == null || tag == null) continue;
                  localRowId = '$recipeId:$tag';
                } else {
                  final id = row.data['id'] as String?;
                  if (id == null) continue;
                  localRowId = id;
                }

                if (liveIds.contains(localRowId)) {
                  continue;
                }

                final cvRows = await db
                    .customSelect(
                      'SELECT hlc FROM sync_column_versions WHERE table_name = ? AND row_id = ?;',
                      variables: [
                        Variable.withString(table),
                        Variable.withString(localRowId),
                      ],
                    )
                    .get();

                final allAtOrBelowHorizon =
                    cvRows.isNotEmpty &&
                    cvRows.every(
                      (r) => effectiveManifestHorizon.covers(
                        Hlc.parse(r.data['hlc'] as String),
                      ),
                    );
                if (!allAtOrBelowHorizon) {
                  continue;
                }

                await _disconnectForeignKeysForDelete(table, localRowId);
                if (table == 'recipe_tags') {
                  final parts = localRowId.split(':');
                  final recipeId = parts[0];
                  final tag = parts.length > 1
                      ? parts.sublist(1).join(':')
                      : '';
                  await db.customStatement(
                    'DELETE FROM recipe_tags WHERE recipe_id = ? AND tag = ?;',
                    [recipeId, tag],
                  );
                } else {
                  await db.customStatement('DELETE FROM $table WHERE id = ?;', [
                    localRowId,
                  ]);
                }
                await db.customStatement(
                  'DELETE FROM sync_column_versions WHERE table_name = ? AND row_id = ?;',
                  [table, localRowId],
                );
                touchedTables.add(table);
                touchedRowIds.add(localRowId);
                appliedTombstonesCount++;
              }
            }
          }

          // C. Filter changes suppressed by tombstones or excluded columns
          final survivingChanges = <ColumnVersion>[];
          for (final change in batch.changes) {
            final key = '${change.table}:${change.rowId}';
            if (localTombstonesMap.containsKey(key)) {
              // Anti-resurrection (RN-322): permanently purged row cannot be resurrected by column changes.
              continue;
            }

            final spec = registry.findTable(change.table);
            if (spec != null && spec.excludedColumns.contains(change.column)) {
              continue;
            }

            survivingChanges.add(change);
          }

          // D. Query local versions for field-level LWW resolution
          final localByKey = <String, Hlc>{};
          if (survivingChanges.isNotEmpty) {
            final rowIds = survivingChanges
                .map((c) => c.rowId)
                .toSet()
                .toList();
            final List<QueryRow> cvRows;
            if (rowIds.length <= 500) {
              final placeholders = List.filled(rowIds.length, '?').join(', ');
              cvRows = await db
                  .customSelect(
                    'SELECT table_name, row_id, column_name, hlc FROM sync_column_versions WHERE row_id IN ($placeholders)',
                    variables: rowIds.map(Variable.withString).toList(),
                  )
                  .get();
            } else {
              cvRows = await db
                  .customSelect(
                    'SELECT table_name, row_id, column_name, hlc FROM sync_column_versions',
                  )
                  .get();
            }
            for (final row in cvRows) {
              final t = row.data['table_name'] as String;
              final r = row.data['row_id'] as String;
              final c = row.data['column_name'] as String;
              localByKey['$t:$r:$c'] = Hlc.parse(row.data['hlc'] as String);
            }
          }

          final winningChanges = lwwMerge.winners(survivingChanges, localByKey);

          // E. Group winning changes by table and row
          final grouped = <String, Map<String, List<ColumnVersion>>>{};
          for (final ch in winningChanges) {
            grouped
                .putIfAbsent(ch.table, () => {})
                .putIfAbsent(ch.rowId, () => [])
                .add(ch);
          }

          // Sort tables topologically so inserts satisfy constraints
          final sortedTables = grouped.keys.toList()..sort(_compareTableOrder);
          final nowIso = clock.nowUtc().toIso8601String();

          for (final table in sortedTables) {
            final rowsMap = grouped[table]!;
            for (final entry in rowsMap.entries) {
              final rowId = entry.key;
              final changesForRow = entry.value;

              final bool exists;
              if (table == 'recipe_tags') {
                final parts = rowId.split(':');
                final recipeId = parts[0];
                final tag = parts.length > 1 ? parts.sublist(1).join(':') : '';
                final countRes = await db
                    .customSelect(
                      'SELECT COUNT(*) AS c FROM recipe_tags WHERE recipe_id = ? AND tag = ?;',
                      variables: [
                        Variable.withString(recipeId),
                        Variable.withString(tag),
                      ],
                    )
                    .get();
                exists = (countRes.first.data['c'] as int? ?? 0) > 0;
              } else {
                final countRes = await db
                    .customSelect(
                      'SELECT COUNT(*) AS c FROM $table WHERE id = ?;',
                      variables: [Variable.withString(rowId)],
                    )
                    .get();
                exists = (countRes.first.data['c'] as int? ?? 0) > 0;
              }

              if (!exists && horizonVector.maxBySite.isNotEmpty) {
                final allAtOrBelowHorizon = changesForRow.every(
                  (ch) => horizonVector.covers(ch.hlc),
                );
                if (allAtOrBelowHorizon) {
                  // (b) Discard unknown row whose versions <= horizon (RN-429, CA-5.7)
                  continue;
                }
              }

              final colValues = <String, Object?>{};
              for (final ch in changesForRow) {
                colValues[ch.column] = _toSqlValue(ch.value);
              }

              if (exists) {
                if (colValues.isNotEmpty) {
                  final setClauses = colValues.keys
                      .map((c) => '$c = ?')
                      .join(', ');
                  final params = colValues.values.toList();
                  if (table == 'recipe_tags') {
                    final parts = rowId.split(':');
                    final recipeId = parts[0];
                    final tag = parts.length > 1
                        ? parts.sublist(1).join(':')
                        : '';
                    params.add(recipeId);
                    params.add(tag);
                    await db.customStatement(
                      'UPDATE recipe_tags SET $setClauses WHERE recipe_id = ? AND tag = ?;',
                      params,
                    );
                  } else {
                    params.add(rowId);
                    await db.customStatement(
                      'UPDATE $table SET $setClauses WHERE id = ?;',
                      params,
                    );
                  }
                }
              } else {
                if (table == 'recipe_tags') {
                  final parts = rowId.split(':');
                  colValues.putIfAbsent('recipe_id', () => parts[0]);
                  colValues.putIfAbsent(
                    'tag',
                    () => parts.length > 1 ? parts.sublist(1).join(':') : '',
                  );
                } else {
                  colValues.putIfAbsent('id', () => rowId);
                  _applyInsertDefaults(table, colValues, nowIso);
                }
                final colNames = colValues.keys.join(', ');
                final placeholders = List.filled(
                  colValues.length,
                  '?',
                ).join(', ');
                final params = colValues.values.toList();
                await db.customStatement(
                  'INSERT INTO $table ($colNames) VALUES ($placeholders);',
                  params,
                );
              }

              // Write winning column versions to sync_column_versions
              for (final ch in changesForRow) {
                await db.customStatement(
                  '''
                  INSERT OR REPLACE INTO sync_column_versions
                  (table_name, row_id, column_name, hlc, site_id, updated_at)
                  VALUES (?, ?, ?, ?, ?, ?);
                  ''',
                  [
                    ch.table,
                    ch.rowId,
                    ch.column,
                    ch.hlc.pack(),
                    ch.hlc.siteId,
                    nowIso,
                  ],
                );
                appliedChangesCount++;
              }

              touchedTables.add(table);
              touchedRowIds.add(rowId);
            }
          }

          // F. Update sync_peer_vectors
          final peerVectorEntries = Map<String, Hlc>.from(
            batch.senderVector.maxBySite,
          );

          // Ensure all origins present in changes or purges have their highest HLC reflected
          for (final ch in batch.changes) {
            final cur = peerVectorEntries[ch.hlc.siteId];
            if (cur == null || ch.hlc.compareTo(cur) > 0) {
              peerVectorEntries[ch.hlc.siteId] = ch.hlc;
            }
          }
          for (final p in batch.purged) {
            final cur = peerVectorEntries[p.hlc.siteId];
            if (cur == null || p.hlc.compareTo(cur) > 0) {
              peerVectorEntries[p.hlc.siteId] = p.hlc;
            }
          }

          for (final entry in peerVectorEntries.entries) {
            final siteId = entry.key;
            final hlc = entry.value;
            await db.customStatement(
              '''
              INSERT INTO sync_peer_vectors (household_id, site_id, hlc, updated_at)
              VALUES (?, ?, ?, ?)
              ON CONFLICT (household_id, site_id) DO UPDATE SET
                hlc = CASE WHEN excluded.hlc > sync_peer_vectors.hlc THEN excluded.hlc ELSE sync_peer_vectors.hlc END,
                updated_at = excluded.updated_at;
              ''',
              [batch.householdId, siteId, hlc.pack(), nowIso],
            );
          }

          // (a) Record sender member acknowledgment in sync_member_acks (RN-428)
          final ackStore = MemberAckStore(db: db, clock: clock);
          await ackStore.record(
            batch.householdId,
            batch.fromSiteId,
            VersionVector(peerVectorEntries),
          );

          // Execute natural identity merges and ambiguous alias detection (RN-326, CA-5.6)
          await naturalKeyMerger.mergeAll(db);

          // Execute derived data rebuilders and notifications (RN-327, CA-5.4, CA-5.6)
          for (final rebuilder in rebuilders) {
            if (rebuilder.watchesTables.any(touchedTables.contains)) {
              await rebuilder.rebuild(touchedRowIds);
            }
          }

          return ApplyReport(
            appliedChangesCount: appliedChangesCount,
            appliedTombstonesCount: appliedTombstonesCount,
            touchedTables: touchedTables,
            touchedRowIds: touchedRowIds,
          );
        });
      });

      if (report.appliedChangesCount > 0 || report.appliedTombstonesCount > 0) {
        _appliedEventsController.add(
          SyncAppliedEvent(
            householdId: batch.householdId,
            fromSiteId: batch.fromSiteId,
            touchedTables: report.touchedTables,
            touchedRowIds: report.touchedRowIds,
            changesAppliedCount: report.appliedChangesCount,
          ),
        );
      }

      return Ok(report);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Failed to apply sync batch: $e', cause: e),
      );
    }
  }

  static Object? _toSqlValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  static int _compareTableOrder(String a, String b) {
    final indexA = tableDependencyOrder.indexOf(a);
    final indexB = tableDependencyOrder.indexOf(b);
    final rankA = indexA == -1 ? 999 : indexA;
    final rankB = indexB == -1 ? 999 : indexB;
    return rankA.compareTo(rankB);
  }

  static int _compareTableReverseOrder(String a, String b) {
    return _compareTableOrder(b, a);
  }

  Future<void> _disconnectForeignKeysForDelete(
    String table,
    String rowId,
  ) async {
    switch (table) {
      case 'purchases':
        await db.customStatement(
          'UPDATE price_points SET purchase_item_id = NULL WHERE purchase_item_id IN (SELECT id FROM purchase_items WHERE purchase_id = ?);',
          [rowId],
        );
        await db.customStatement(
          'UPDATE expenses SET purchase_id = NULL WHERE purchase_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE purchases SET expense_id = NULL WHERE id = ?;',
          [rowId],
        );
      case 'expenses':
        await db.customStatement(
          'UPDATE purchases SET expense_id = NULL WHERE expense_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE bill_payments SET expense_id = NULL WHERE expense_id = ?;',
          [rowId],
        );
      case 'bills':
        await db.customStatement(
          'UPDATE expenses SET bill_id = NULL WHERE bill_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE bill_payments SET bill_id = NULL WHERE bill_id = ?;',
          [rowId],
        );
      case 'recurring_rules':
        await db.customStatement(
          'UPDATE expenses SET recurring_rule_id = NULL WHERE recurring_rule_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE tasks SET recurring_rule_id = NULL WHERE recurring_rule_id = ?;',
          [rowId],
        );
      case 'recipes':
        await db.customStatement(
          'DELETE FROM recipe_tags WHERE recipe_id = ?;',
          [rowId],
        );
      case 'stores':
        await db.customStatement(
          'UPDATE purchases SET store_id = NULL WHERE store_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE shopping_lists SET store_id = NULL WHERE store_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE price_points SET store_id = NULL WHERE store_id = ?;',
          [rowId],
        );
      case 'categories':
        await db.customStatement(
          'UPDATE products SET category_id = NULL WHERE category_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE expenses SET category_id = NULL WHERE category_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE budgets SET category_id = NULL WHERE category_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE bills SET category_id = NULL WHERE category_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE tasks SET category_id = NULL WHERE category_id = ?;',
          [rowId],
        );
      case 'products':
        await db.customStatement(
          'UPDATE purchase_items SET product_id = NULL WHERE product_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE price_points SET product_id = NULL WHERE product_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE shopping_items SET product_id = NULL WHERE product_id = ?;',
          [rowId],
        );
        await db.customStatement(
          'UPDATE recipe_ingredients SET product_id = NULL WHERE product_id = ?;',
          [rowId],
        );
    }
  }

  static void _applyInsertDefaults(
    String table,
    Map<String, Object?> colValues,
    String nowIso,
  ) {
    const tablesWithTimestamps = {
      'products',
      'stores',
      'purchases',
      'shopping_lists',
      'tasks',
      'recipes',
      'expenses',
      'stock_items',
      'checklist_items',
    };
    if (tablesWithTimestamps.contains(table)) {
      colValues.putIfAbsent('created_at', () => nowIso);
      colValues.putIfAbsent('updated_at', () => nowIso);
    }

    switch (table) {
      case 'products':
        colValues.putIfAbsent('canonical_name', () => 'Produto');
        colValues.putIfAbsent('default_unit', () => 'un');
      case 'product_aliases':
        colValues.putIfAbsent('created_at', () => nowIso);
        colValues.putIfAbsent('alias', () => '');
        colValues.putIfAbsent('normalized_alias', () => '');
        colValues.putIfAbsent('source', () => 'user');
      case 'stores':
        colValues.putIfAbsent('name', () => 'Estabelecimento');
      case 'shopping_items':
        colValues.putIfAbsent('source', () => 'manual');
        colValues.putIfAbsent('position', () => 0);
      case 'checklist_items':
        colValues.putIfAbsent('room_category', () => 'geral');
        colValues.putIfAbsent('title', () => '');
        colValues.putIfAbsent('is_marked', () => 0);
        colValues.putIfAbsent('position', () => 0);
      case 'tasks':
        colValues.putIfAbsent('title', () => '');
        colValues.putIfAbsent('all_day', () => 1);
        colValues.putIfAbsent('is_completed', () => 0);
        colValues.putIfAbsent('sync_state', () => 'synced');
      case 'shopping_lists':
        colValues.putIfAbsent('name', () => '');
      case 'purchases':
        colValues.putIfAbsent('purchased_at', () => nowIso);
        colValues.putIfAbsent('total_cents', () => 0);
        colValues.putIfAbsent('source', () => 'manual');
      case 'purchase_items':
        colValues.putIfAbsent('raw_description', () => '');
        colValues.putIfAbsent('position', () => 0);
        colValues.putIfAbsent('total_price_cents', () => 0);
        colValues.putIfAbsent('quantity_milli', () => 1000);
        colValues.putIfAbsent('unit', () => 'un');
        colValues.putIfAbsent('unit_price_cents', () => 0);
      case 'categories':
        colValues.putIfAbsent('name', () => 'Geral');
        colValues.putIfAbsent('kind', () => 'both');
        colValues.putIfAbsent('icon_key', () => 'cart');
      case 'expenses':
        colValues.putIfAbsent('amount_cents', () => 0);
        colValues.putIfAbsent('occurred_on', () => nowIso.split('T').first);
      case 'budgets':
        colValues.putIfAbsent('year_month', () => nowIso.substring(0, 7));
        colValues.putIfAbsent('limit_cents', () => 0);
      case 'recipes':
        colValues.putIfAbsent('title', () => '');
        colValues.putIfAbsent('instructions', () => '');
      case 'recipe_ingredients':
        colValues.putIfAbsent('raw_text', () => '');
        colValues.putIfAbsent('position', () => 0);
      case 'recurring_rules':
        colValues.putIfAbsent('kind', () => 'expense');
        colValues.putIfAbsent('rrule', () => 'FREQ=MONTHLY');
        colValues.putIfAbsent('starts_on', () => nowIso.split('T').first);
        colValues.putIfAbsent('title', () => '');
      case 'bills':
        colValues.putIfAbsent('title', () => '');
        colValues.putIfAbsent('due_day', () => 1);
        colValues.putIfAbsent('is_amount_variable', () => 0);
      case 'bill_payments':
        colValues.putIfAbsent('due_on', () => nowIso.split('T').first);
        colValues.putIfAbsent('status', () => 'pending');
      case 'stock_items':
        colValues.putIfAbsent('low_stock_threshold_milli', () => 0);
        colValues.putIfAbsent('quantity_milli', () => 0);
        colValues.putIfAbsent('unit', () => 'un');
    }
  }
}
