/// Contract and single implementation of soft delete (trash).
///
/// RN-014: Soft delete MUST have a single contract ([TrashPolicy],
/// in `lib/core/`), used across all features. No per-feature trash implementations.
///
/// RN-015: Deleting MUST be logical (`deleted_at`), with 5-second undo
/// in the interface and 30-day retention. Sweeping expired items (> 30 days)
/// MUST run once per day, on first use of the day, and MUST be idempotent.
///
/// RN-016: Restoration MUST cascade through links: restoring a purchase
/// restores its generated expense; restoring a record MUST NOT leave
/// dangling references pointing to deleted rows.
library;

import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';

// ---------------------------------------------------------------------------
// Trash ticket / entry models
// ---------------------------------------------------------------------------

/// Ticket issued upon performing soft delete to allow undo operations.
final class TrashTicket {
  const TrashTicket({
    required this.table,
    required this.id,
    required this.deletedAt,
    this.parentId,
  });

  /// Table name where record was soft-deleted.
  final String table;

  /// ID of the soft-deleted record.
  final String id;

  /// UTC timestamp when deletion occurred.
  final DateTime deletedAt;

  /// Parent ID or cascade link, if applicable.
  final String? parentId;

  /// Converts to [TrashEntry].
  TrashEntry toEntry() => TrashEntry(
    table: table,
    id: id,
    deletedAt: deletedAt,
    parentId: parentId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashTicket &&
          runtimeType == other.runtimeType &&
          table == other.table &&
          id == other.id &&
          deletedAt == other.deletedAt &&
          parentId == other.parentId;

  @override
  int get hashCode => Object.hash(table, id, deletedAt, parentId);

  @override
  String toString() =>
      'TrashTicket(table: $table, id: $id, deletedAt: $deletedAt, parentId: $parentId)';
}

/// Trash entry representing a soft-deleted record.
final class TrashEntry {
  const TrashEntry({
    required this.table,
    required this.id,
    required this.deletedAt,
    this.parentId,
  });

  final String table;
  final String id;
  final DateTime deletedAt;
  final String? parentId;

  /// Converts to [TrashTicket].
  TrashTicket toTicket() => TrashTicket(
    table: table,
    id: id,
    deletedAt: deletedAt,
    parentId: parentId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashEntry &&
          runtimeType == other.runtimeType &&
          table == other.table &&
          id == other.id &&
          deletedAt == other.deletedAt &&
          parentId == other.parentId;

  @override
  int get hashCode => Object.hash(table, id, deletedAt, parentId);

  @override
  String toString() =>
      'TrashEntry(table: $table, id: $id, deletedAt: $deletedAt, parentId: $parentId)';
}

// ---------------------------------------------------------------------------
// Trash policy contract (single application-wide contract — RN-014)
// ---------------------------------------------------------------------------

/// Application-wide soft delete contract.
abstract interface class TrashPolicy {
  /// Marks record as soft-deleted (`deleted_at`),
  /// cascading to dependent records when applicable (RN-015, RN-016).
  Future<Result<TrashTicket, Failure>> softDelete(String table, String id);

  /// Restores record and its cascading dependencies (RN-016).
  Future<Result<void, Failure>> restore(TrashTicket ticket);

  /// Sweeps and physically removes records past retention (> 30 days).
  ///
  /// Idempotent: running multiple times on the same day produces the same state.
  Future<Result<int, Failure>> sweepExpired();

  /// Time window for immediate UI undo (5 seconds — RN-015).
  Duration get undoWindow;

  /// Trash retention period before hard deletion (30 days — RN-015).
  Duration get retention;
}

// ---------------------------------------------------------------------------
// Drift implementation of trash policy
// ---------------------------------------------------------------------------

/// Implementation of [TrashPolicy] backed by Drift database ([AppDatabase]).
final class DriftTrashPolicy implements TrashPolicy {
  DriftTrashPolicy({required this.db, required this.clock});

  DriftTrashPolicy.system({required this.db}) : clock = const SystemClock();

  final AppDatabase db;
  final Clock clock;

  static const Set<String> _supportedTables = {
    'purchases',
    'expenses',
    'tasks',
  };

  @override
  Duration get undoWindow => const Duration(seconds: 5);

  @override
  Duration get retention => const Duration(days: 30);

  @override
  Future<Result<TrashTicket, Failure>> softDelete(
    String table,
    String id,
  ) async {
    final normalizedTable = table.trim().toLowerCase();
    if (!_supportedTables.contains(normalizedTable)) {
      return Err(
        StorageFailure(detail: 'Table "$table" does not support soft delete'),
      );
    }

    try {
      return await db.transaction(() async {
        final rows = await db
            .customSelect(
              'SELECT * FROM $normalizedTable WHERE id = ?;',
              variables: [Variable.withString(id)],
            )
            .get();

        if (rows.isEmpty) {
          return Err(NotFoundFailure(what: 'Record not found: $table.$id'));
        }

        final now = clock.nowUtc();
        final nowIso = now.toIso8601String();
        String? parentId;

        if (normalizedTable == 'purchases') {
          final expenseId = rows.first.readNullable<String>('expense_id');
          await db.customStatement(
            'UPDATE purchases SET deleted_at = ? WHERE id = ?;',
            [nowIso, id],
          );
          if (expenseId != null) {
            await db.customStatement(
              'UPDATE expenses SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL;',
              [nowIso, expenseId],
            );
          }
          await db.customStatement(
            'UPDATE expenses SET deleted_at = ? WHERE purchase_id = ? AND deleted_at IS NULL;',
            [nowIso, id],
          );
        } else if (normalizedTable == 'expenses') {
          parentId = rows.first.readNullable<String>('purchase_id');
          await db.customStatement(
            'UPDATE expenses SET deleted_at = ? WHERE id = ?;',
            [nowIso, id],
          );
          if (parentId != null) {
            await db.customStatement(
              'UPDATE purchases SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL;',
              [nowIso, parentId],
            );
          }
          await db.customStatement(
            'UPDATE purchases SET deleted_at = ? WHERE expense_id = ? AND deleted_at IS NULL;',
            [nowIso, id],
          );
        } else if (normalizedTable == 'tasks') {
          await db.customStatement(
            'UPDATE tasks SET deleted_at = ? WHERE id = ?;',
            [nowIso, id],
          );
        }

        return Ok(
          TrashTicket(table: table, id: id, deletedAt: now, parentId: parentId),
        );
      });
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Error deleting $table.$id: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> restore(TrashTicket ticket) async {
    final normalizedTable = ticket.table.trim().toLowerCase();
    if (!_supportedTables.contains(normalizedTable)) {
      return Err(
        StorageFailure(
          detail: 'Table "${ticket.table}" does not support soft delete',
        ),
      );
    }

    try {
      return await db.transaction(() async {
        final rows = await db
            .customSelect(
              'SELECT * FROM $normalizedTable WHERE id = ?;',
              variables: [Variable.withString(ticket.id)],
            )
            .get();

        if (rows.isEmpty) {
          return Err(
            NotFoundFailure(
              what: 'Record not found: ${ticket.table}.${ticket.id}',
            ),
          );
        }

        if (normalizedTable == 'purchases') {
          final expenseId = rows.first.readNullable<String>('expense_id');
          await db.customStatement(
            'UPDATE purchases SET deleted_at = NULL WHERE id = ?;',
            [ticket.id],
          );
          if (expenseId != null) {
            await db.customStatement(
              'UPDATE expenses SET deleted_at = NULL WHERE id = ?;',
              [expenseId],
            );
          }
          await db.customStatement(
            'UPDATE expenses SET deleted_at = NULL WHERE purchase_id = ?;',
            [ticket.id],
          );
          if (ticket.parentId != null) {
            await db.customStatement(
              'UPDATE expenses SET deleted_at = NULL WHERE id = ?;',
              [ticket.parentId],
            );
          }
        } else if (normalizedTable == 'expenses') {
          final purchaseId = rows.first.readNullable<String>('purchase_id');
          await db.customStatement(
            'UPDATE expenses SET deleted_at = NULL WHERE id = ?;',
            [ticket.id],
          );
          if (purchaseId != null) {
            await db.customStatement(
              'UPDATE purchases SET deleted_at = NULL WHERE id = ?;',
              [purchaseId],
            );
          }
          await db.customStatement(
            'UPDATE purchases SET deleted_at = NULL WHERE expense_id = ?;',
            [ticket.id],
          );
          if (ticket.parentId != null) {
            await db.customStatement(
              'UPDATE purchases SET deleted_at = NULL WHERE id = ?;',
              [ticket.parentId],
            );
          }
        } else if (normalizedTable == 'tasks') {
          await db.customStatement(
            'UPDATE tasks SET deleted_at = NULL WHERE id = ?;',
            [ticket.id],
          );
        }

        return const Ok(null);
      });
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Error restoring record: ${ticket.table}.${ticket.id}: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<int, Failure>> sweepExpired() async {
    try {
      return await db.transaction(() async {
        final now = clock.nowUtc();
        final expiredPurchases = <String>[];
        final expiredExpenses = <String>[];
        final expiredTasks = <String>[];

        final purchaseRows = await db
            .customSelect(
              'SELECT id, deleted_at FROM purchases WHERE deleted_at IS NOT NULL;',
            )
            .get();
        for (final row in purchaseRows) {
          final dStr = row.read<String>('deleted_at');
          final d = DateTime.tryParse(dStr);
          if (d != null && now.difference(d.toUtc()) >= retention) {
            expiredPurchases.add(row.read<String>('id'));
          }
        }

        final expenseRows = await db
            .customSelect(
              'SELECT id, deleted_at FROM expenses WHERE deleted_at IS NOT NULL;',
            )
            .get();
        for (final row in expenseRows) {
          final dStr = row.read<String>('deleted_at');
          final d = DateTime.tryParse(dStr);
          if (d != null && now.difference(d.toUtc()) >= retention) {
            expiredExpenses.add(row.read<String>('id'));
          }
        }

        final taskRows = await db
            .customSelect(
              'SELECT id, deleted_at FROM tasks WHERE deleted_at IS NOT NULL;',
            )
            .get();
        for (final row in taskRows) {
          final dStr = row.read<String>('deleted_at');
          final d = DateTime.tryParse(dStr);
          if (d != null && now.difference(d.toUtc()) >= retention) {
            expiredTasks.add(row.read<String>('id'));
          }
        }

        final totalCount =
            expiredPurchases.length +
            expiredExpenses.length +
            expiredTasks.length;

        if (totalCount == 0) {
          return const Ok(0);
        }

        // Disconnect foreign keys before hard deletion
        for (final pId in expiredPurchases) {
          await db.customStatement(
            'UPDATE price_points SET purchase_item_id = NULL WHERE purchase_item_id IN (SELECT id FROM purchase_items WHERE purchase_id = ?);',
            [pId],
          );
          await db.customStatement(
            'UPDATE expenses SET purchase_id = NULL WHERE purchase_id = ?;',
            [pId],
          );
          await db.customStatement(
            'UPDATE purchases SET expense_id = NULL WHERE id = ?;',
            [pId],
          );
        }

        for (final eId in expiredExpenses) {
          await db.customStatement(
            'UPDATE purchases SET expense_id = NULL WHERE expense_id = ?;',
            [eId],
          );
          await db.customStatement(
            'UPDATE bill_payments SET expense_id = NULL WHERE expense_id = ?;',
            [eId],
          );
        }

        for (final pId in expiredPurchases) {
          await db.customStatement('DELETE FROM purchases WHERE id = ?;', [
            pId,
          ]);
        }
        for (final eId in expiredExpenses) {
          await db.customStatement('DELETE FROM expenses WHERE id = ?;', [eId]);
        }
        for (final tId in expiredTasks) {
          await db.customStatement('DELETE FROM tasks WHERE id = ?;', [tId]);
        }

        return Ok(totalCount);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Error sweeping trash: $e', cause: e));
    }
  }
}
