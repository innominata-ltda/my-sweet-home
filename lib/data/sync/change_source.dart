library;

import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/result/result.dart';
import '../../core/sync/domain/column_version.dart';
import '../../core/sync/domain/hlc.dart';
import '../../core/sync/domain/sync_table_registry.dart';
import '../../core/sync/domain/version_vector.dart';
import '../database/database.dart';

/// Port for obtaining column versions and local version vector.
abstract interface class ChangeSource {
  /// Returns all column versions recorded locally that are NOT yet
  /// covered by the [peer] vector and belong to the specified [areas].
  Future<Result<List<ColumnVersion>, Failure>> changesNotCoveredBy(
    VersionVector peer,
    Set<SyncArea> areas,
  );

  /// Returns the current version vector summarizing the highest known HLC per device.
  Future<VersionVector> localVector();
}

/// Drift implementation of [ChangeSource] on local SQLite.
class DriftChangeSource implements ChangeSource {
  final AppDatabase db;
  final SyncTableRegistry registry;

  DriftChangeSource({required this.db, required this.registry});

  @override
  Future<Result<List<ColumnVersion>, Failure>> changesNotCoveredBy(
    VersionVector peer,
    Set<SyncArea> areas,
  ) async {
    try {
      final conditions = <String>[];
      final variables = <Variable>[];

      if (peer.maxBySite.isNotEmpty) {
        final siteClauses = <String>[];
        for (final entry in peer.maxBySite.entries) {
          siteClauses.add('(site_id = ? AND hlc > ?)');
          variables.add(Variable.withString(entry.key));
          variables.add(Variable.withString(entry.value.pack()));
        }
        final knownPlaceholders = List.filled(
          peer.maxBySite.length,
          '?',
        ).join(', ');
        for (final siteId in peer.maxBySite.keys) {
          variables.add(Variable.withString(siteId));
        }
        conditions.add(
          '(${siteClauses.join(' OR ')} OR site_id NOT IN ($knownPlaceholders))',
        );
      }

      final whereClause = conditions.isEmpty
          ? ''
          : 'WHERE ${conditions.join(' AND ')}';

      final cvRows = await db
          .customSelect(
            'SELECT table_name, row_id, column_name, hlc, site_id '
            'FROM sync_column_versions $whereClause ORDER BY hlc ASC',
            variables: variables,
          )
          .get();

      final candidates = <_PendingCol>[];
      for (final row in cvRows) {
        final table = row.data['table_name'] as String;
        final rowId = row.data['row_id'] as String;
        final column = row.data['column_name'] as String;
        final rawHlc = row.data['hlc'] as String;

        final hlc = Hlc.parse(rawHlc);
        if (peer.covers(hlc)) {
          continue;
        }

        final spec = registry.findTable(table);
        if (spec == null || spec.derived) {
          continue;
        }

        if (spec.excludedColumns.contains(column)) {
          continue;
        }

        candidates.add(
          _PendingCol(
            table: table,
            rowId: rowId,
            column: column,
            hlc: hlc,
            spec: spec,
          ),
        );
      }

      if (candidates.isEmpty) {
        return const Ok([]);
      }

      // Agrupa candidatos por tabela para minimizar queries ao banco
      final candidatesByTable = <String, List<_PendingCol>>{};
      for (final c in candidates) {
        candidatesByTable.putIfAbsent(c.table, () => []).add(c);
      }

      final results = <ColumnVersion>[];

      for (final entry in candidatesByTable.entries) {
        final table = entry.key;
        final tableCandidates = entry.value;
        final spec = tableCandidates.first.spec;

        final byRowId = <String, List<_PendingCol>>{};
        for (final c in tableCandidates) {
          byRowId.putIfAbsent(c.rowId, () => []).add(c);
        }

        final rowIds = byRowId.keys.toList();

        if (table == 'recipe_tags') {
          for (final rowId in rowIds) {
            final colonIdx = rowId.indexOf(':');
            if (colonIdx == -1) continue;
            final recipeId = rowId.substring(0, colonIdx);
            final tag = rowId.substring(colonIdx + 1);

            final rows = await db
                .customSelect(
                  'SELECT * FROM recipe_tags WHERE recipe_id = ? AND tag = ?',
                  variables: [
                    Variable.withString(recipeId),
                    Variable.withString(tag),
                  ],
                )
                .get();

            if (rows.isEmpty) {
              // Record no longer exists: clean up orphan version
              await db.customStatement(
                'DELETE FROM sync_column_versions WHERE table_name = ? AND row_id = ?',
                ['recipe_tags', rowId],
              );
              continue;
            }
            final rowData = rows.first.data;
            if (!areas.contains(spec.areaOf(rowData))) continue;

            for (final col in byRowId[rowId]!) {
              results.add(
                ColumnVersion(
                  table: col.table,
                  rowId: col.rowId,
                  column: col.column,
                  value: rowData[col.column],
                  hlc: col.hlc,
                ),
              );
            }
          }
        } else {
          const chunkSize = 200;
          for (var i = 0; i < rowIds.length; i += chunkSize) {
            final chunk = rowIds.sublist(
              i,
              math.min(i + chunkSize, rowIds.length),
            );
            final placeholders = List.filled(chunk.length, '?').join(',');
            final rows = await db
                .customSelect(
                  'SELECT * FROM $table WHERE id IN ($placeholders)',
                  variables: chunk.map(Variable.withString).toList(),
                )
                .get();

            final foundIds = rows
                .map((qr) => qr.data['id'] as String?)
                .whereType<String>()
                .toSet();
            final missingIds = chunk.toSet().difference(foundIds);
            for (final missingId in missingIds) {
              // Row purged from database: remove accumulated orphan versions
              await db.customStatement(
                'DELETE FROM sync_column_versions WHERE table_name = ? AND row_id = ?',
                [table, missingId],
              );
            }

            for (final qr in rows) {
              final rowData = qr.data;
              final id = rowData['id'] as String?;
              if (id == null) continue;

              if (!areas.contains(spec.areaOf(rowData))) {
                continue;
              }

              final colsForRow = byRowId[id];
              if (colsForRow != null) {
                for (final col in colsForRow) {
                  results.add(
                    ColumnVersion(
                      table: col.table,
                      rowId: col.rowId,
                      column: col.column,
                      value: rowData[col.column],
                      hlc: col.hlc,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      // Sort monotonically by HLC to guarantee causal consistency
      results.sort((a, b) => a.hlc.compareTo(b.hlc));
      return Ok(results);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Failed to query uncovered changes: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<VersionVector> localVector() async {
    final map = <String, Hlc>{};

    // 1. Recorded column versions
    final cvRows = await db
        .customSelect(
          'SELECT site_id, MAX(hlc) AS max_hlc FROM sync_column_versions GROUP BY site_id',
        )
        .get();
    for (final row in cvRows) {
      final siteId = row.data['site_id'] as String?;
      final maxHlc = row.data['max_hlc'] as String?;
      if (siteId != null && maxHlc != null) {
        map[siteId] = Hlc.parse(maxHlc);
      }
    }

    // 2. Tombstones de linhas purgadas
    final tombRows = await db
        .customSelect('SELECT hlc FROM sync_row_tombstones')
        .get();
    for (final row in tombRows) {
      final rawHlc = row.data['hlc'] as String?;
      if (rawHlc != null) {
        final hlc = Hlc.parse(rawHlc);
        final current = map[hlc.siteId];
        if (current == null || hlc.compareTo(current) > 0) {
          map[hlc.siteId] = hlc;
        }
      }
    }

    // 3. Vetores conhecidos de aparelhos pareados da casa ativa
    final peerRows = await db
        .customSelect(
          'SELECT site_id, hlc FROM sync_peer_vectors '
          'WHERE household_id = (SELECT id FROM sync_household WHERE active = 1 LIMIT 1)',
        )
        .get();
    for (final row in peerRows) {
      final siteId = row.data['site_id'] as String?;
      final rawHlc = row.data['hlc'] as String?;
      if (siteId != null && rawHlc != null) {
        final hlc = Hlc.parse(rawHlc);
        final current = map[siteId];
        if (current == null || hlc.compareTo(current) > 0) {
          map[siteId] = hlc;
        }
      }
    }

    return VersionVector(map);
  }
}

final class _PendingCol {
  final String table;
  final String rowId;
  final String column;
  final Hlc hlc;
  final SyncTableSpec spec;

  const _PendingCol({
    required this.table,
    required this.rowId,
    required this.column,
    required this.hlc,
    required this.spec,
  });
}
