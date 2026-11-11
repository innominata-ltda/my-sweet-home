library;

import 'package:drift/drift.dart';

import '../../core/id/id_generator.dart';
import '../../core/sync/domain/hlc.dart';
import '../../core/time/clock.dart';
import '../database/database.dart';

/// Represents a permanently deleted record (row tombstone)
/// after the trash purge period or direct physical deletion (RN-322).
final class RowTombstone {
  /// Unique tombstone ID (UUID).
  final String id;

  /// Table name of the purged row.
  final String table;

  /// Primary key of the purged row.
  final String rowId;

  /// Hybrid logical clock (HLC) at the purge moment.
  final Hlc hlc;

  /// Purge timestamp (ISO-8601 UTC).
  final String purgedAt;

  const RowTombstone({
    required this.id,
    required this.table,
    required this.rowId,
    required this.hlc,
    required this.purgedAt,
  });

  /// Canonical key uniquely identifying the purged row.
  String get key => '$table:$rowId';

  /// Serializes to Map/JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'row_id': rowId,
    'hlc': hlc.pack(),
    'purged_at': purgedAt,
  };

  /// Deserializes from Map/JSON.
  factory RowTombstone.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final table =
        (json['table'] ?? json['table_name'] ?? json['tableName']) as String;
    final rowId = (json['row_id'] ?? json['rowId']) as String;
    final rawHlc = json['hlc'];
    final hlc = rawHlc is Hlc ? rawHlc : Hlc.parse(rawHlc as String);
    final purgedAt =
        (json['purged_at'] ?? json['purgedAt'] ?? json['purged_date'])
            as String;

    return RowTombstone(
      id: id,
      table: table,
      rowId: rowId,
      hlc: hlc,
      purgedAt: purgedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RowTombstone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          table == other.table &&
          rowId == other.rowId &&
          hlc == other.hlc &&
          purgedAt == other.purgedAt;

  @override
  int get hashCode => Object.hash(id, table, rowId, hlc, purgedAt);

  @override
  String toString() => 'RowTombstone($table:$rowId @ ${hlc.pack()})';
}

/// Armazenamento e gerenciamento de tombstones em `sync_row_tombstones`.
class TombstoneStore {
  final AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  TombstoneStore({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7Generator(),
  });

  /// Returns all tombstones recorded in local database, with optional filters.
  Future<List<RowTombstone>> getAllTombstones({
    String? table,
    Hlc? sinceHlc,
  }) async {
    final conditions = <String>[];
    final variables = <Variable>[];

    if (table != null) {
      conditions.add('table_name = ?');
      variables.add(Variable.withString(table));
    }
    if (sinceHlc != null) {
      conditions.add('hlc > ?');
      variables.add(Variable.withString(sinceHlc.pack()));
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';
    final rows = await db
        .customSelect(
          'SELECT id, table_name, row_id, hlc, purged_at '
          'FROM sync_row_tombstones $whereClause ORDER BY hlc ASC',
          variables: variables,
        )
        .get();

    return rows.map((r) {
      return RowTombstone(
        id: r.data['id'] as String,
        table: r.data['table_name'] as String,
        rowId: r.data['row_id'] as String,
        hlc: Hlc.parse(r.data['hlc'] as String),
        purgedAt: r.data['purged_at'] as String,
      );
    }).toList();
  }

  /// Returns the tombstone for a specific row, if it exists.
  Future<RowTombstone?> getTombstone(String table, String rowId) async {
    final rows = await db
        .customSelect(
          'SELECT id, table_name, row_id, hlc, purged_at '
          'FROM sync_row_tombstones WHERE table_name = ? AND row_id = ? LIMIT 1',
          variables: [Variable.withString(table), Variable.withString(rowId)],
        )
        .get();

    if (rows.isEmpty) return null;
    final r = rows.first;
    return RowTombstone(
      id: r.data['id'] as String,
      table: r.data['table_name'] as String,
      rowId: r.data['row_id'] as String,
      hlc: Hlc.parse(r.data['hlc'] as String),
      purgedAt: r.data['purged_at'] as String,
    );
  }

  /// Checks if a specific row has a recorded tombstone.
  /// If [atOrBeforeHlc] is provided, also verifies that the tombstone has
  /// an HLC greater than or equal to that HLC (indicating the change was suppressed).
  Future<bool> isTombstoned(
    String table,
    String rowId, {
    Hlc? atOrBeforeHlc,
  }) async {
    final tombstone = await getTombstone(table, rowId);
    if (tombstone == null) return false;
    if (atOrBeforeHlc == null) return true;
    return tombstone.hlc.compareTo(atOrBeforeHlc) >= 0;
  }

  /// Records or updates a [tombstone] in `sync_row_tombstones`.
  Future<void> recordTombstone(RowTombstone tombstone) async {
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO sync_row_tombstones
      (id, table_name, row_id, hlc, purged_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        tombstone.id,
        tombstone.table,
        tombstone.rowId,
        tombstone.hlc.pack(),
        tombstone.purgedAt,
      ],
    );
  }

  /// Records the purge of a row, generating a new ID and saving the tombstone.
  Future<RowTombstone> recordPurge({
    required String table,
    required String rowId,
    required Hlc hlc,
    DateTime? purgedAt,
  }) async {
    final effectivePurgedAt = (purgedAt ?? clock.nowUtc()).toIso8601String();
    final tombstoneId = idGenerator.newId();

    final tombstone = RowTombstone(
      id: tombstoneId,
      table: table,
      rowId: rowId,
      hlc: hlc,
      purgedAt: effectivePurgedAt,
    );

    await recordTombstone(tombstone);
    return tombstone;
  }

  /// Removes old tombstones older than [retention] days (default: 90 days).
  Future<int> sweepExpiredTombstones({
    Duration retention = const Duration(days: 90),
  }) async {
    final cutoff = clock.nowUtc().subtract(retention).toIso8601String();
    final deleted = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM sync_row_tombstones WHERE purged_at < ?',
          variables: [Variable.withString(cutoff)],
        )
        .get();
    final count = deleted.first.data['c'] as int? ?? 0;
    if (count > 0) {
      await db.customStatement(
        'DELETE FROM sync_row_tombstones WHERE purged_at < ?',
        [cutoff],
      );
    }
    return count;
  }

  /// Limpa todos os tombstones gravados.
  Future<void> clearAllTombstones() async {
    await db.customStatement('DELETE FROM sync_row_tombstones');
  }
}
