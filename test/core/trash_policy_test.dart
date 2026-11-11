/// Unit and integration tests for TrashPolicy (T-22).
///
/// RN-014: Single contract in lib/core/.
/// RN-015: Soft delete (deleted_at), 5s undo, 30 days retention,
///         idempotent daily sweep.
/// RN-016: Cascade restoration via link (purchase → expense).
/// CA-9.1: Restoration within 30 days restores purchase and expense without orphan FK.
/// CA-9.2: Sweep removes only records > 30 days; running twice is idempotent.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';

import '../fakes/fake_clock.dart';

void main() {
  group('TrashPolicy — RN-014..016, CA-9.1, CA-9.2 (T-22)', () {
    late AppDatabase db;
    late FakeClock clock;
    late DriftTrashPolicy policy;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 9, 23, 12, 0));
      policy = DriftTrashPolicy(db: db, clock: clock);
    });

    tearDown(() async {
      await db.close();
    });

    // -------------------------------------------------------------------------
    // Configurations and constants
    // -------------------------------------------------------------------------
    test('undoWindow and retention have values specified by RN-015', () {
      expect(policy.undoWindow, const Duration(seconds: 5));
      expect(policy.retention, const Duration(days: 30));
    });

    // -------------------------------------------------------------------------
    // softDelete
    // -------------------------------------------------------------------------
    test('softDelete marca deleted_at corretamente', () async {
      const taskId = 'task-1';
      await _insertTask(db, id: taskId, title: 'Lavar louça');

      final result = await policy.softDelete('tasks', taskId);
      expect(result, isA<Ok<TrashTicket, Failure>>());

      final ticket = result.valueOrNull!;
      expect(ticket.table, 'tasks');
      expect(ticket.id, taskId);
      expect(ticket.deletedAt, clock.nowUtc());
      expect(ticket.parentId, isNull);

      final row = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(row.deletedAt, clock.nowUtc().toIso8601String());
    });

    test(
      'softDelete em registro inexistente retorna NotFoundFailure',
      () async {
        final result = await policy.softDelete('tasks', 'nao-existe');
        expect(result, isA<Err<TrashTicket, Failure>>());
        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('softDelete on unsupported table returns StorageFailure', () async {
      final result = await policy.softDelete('products', 'p1');
      expect(result, isA<Err<TrashTicket, Failure>>());
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    // -------------------------------------------------------------------------
    // restore
    // -------------------------------------------------------------------------
    test('restore within 5s undoes soft deletion', () async {
      const taskId = 'task-2';
      await _insertTask(db, id: taskId, title: 'Comprar frutas');

      final deleteResult = await policy.softDelete('tasks', taskId);
      expect(deleteResult, isA<Ok<TrashTicket, Failure>>());
      final ticket = deleteResult.valueOrNull!;

      // Advances clock within 5-second window
      clock.advance(const Duration(seconds: 3));
      expect(
        clock.nowUtc().difference(ticket.deletedAt) <= policy.undoWindow,
        isTrue,
      );

      final restoreResult = await policy.restore(ticket);
      expect(restoreResult, isA<Ok<void, Failure>>());

      final row = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(row.deletedAt, isNull);
    });

    test('restore em cascata (compra → despesa)', () async {
      const purchaseId = 'purch-1';
      const expenseId = 'exp-1';
      await _insertLinkedPurchaseAndExpense(
        db,
        purchaseId: purchaseId,
        expenseId: expenseId,
      );

      // Exclui a compra
      final deleteResult = await policy.softDelete('purchases', purchaseId);
      expect(deleteResult, isA<Ok<TrashTicket, Failure>>());
      final ticket = deleteResult.valueOrNull!;

      // Verifies purchase AND expense were marked as deleted
      var purchaseRow = await (db.select(
        db.purchases,
      )..where((p) => p.id.equals(purchaseId))).getSingle();
      var expenseRow = await (db.select(
        db.expenses,
      )..where((e) => e.id.equals(expenseId))).getSingle();
      expect(purchaseRow.deletedAt, isNotNull);
      expect(expenseRow.deletedAt, isNotNull);

      // Advances clock to 15 days (within 30-day retention window)
      clock.advance(const Duration(days: 15));

      // Restaura a compra
      final restoreResult = await policy.restore(ticket);
      expect(restoreResult, isA<Ok<void, Failure>>());

      // CA-9.1: purchase AND expense return, no FK points to deleted row
      purchaseRow = await (db.select(
        db.purchases,
      )..where((p) => p.id.equals(purchaseId))).getSingle();
      expenseRow = await (db.select(
        db.expenses,
      )..where((e) => e.id.equals(expenseId))).getSingle();

      expect(purchaseRow.deletedAt, isNull);
      expect(expenseRow.deletedAt, isNull);
      expect(purchaseRow.expenseId, expenseId);
      expect(expenseRow.purchaseId, purchaseId);
    });

    test('restore em cascata inversa (despesa → compra)', () async {
      const purchaseId = 'purch-2';
      const expenseId = 'exp-2';
      await _insertLinkedPurchaseAndExpense(
        db,
        purchaseId: purchaseId,
        expenseId: expenseId,
      );

      // Exclui a despesa
      final deleteResult = await policy.softDelete('expenses', expenseId);
      expect(deleteResult, isA<Ok<TrashTicket, Failure>>());
      final ticket = deleteResult.valueOrNull!;
      expect(ticket.parentId, purchaseId);

      // Both deleted
      var purchaseRow = await (db.select(
        db.purchases,
      )..where((p) => p.id.equals(purchaseId))).getSingle();
      var expenseRow = await (db.select(
        db.expenses,
      )..where((e) => e.id.equals(expenseId))).getSingle();
      expect(purchaseRow.deletedAt, isNotNull);
      expect(expenseRow.deletedAt, isNotNull);

      // Restaura despesa
      final restoreResult = await policy.restore(ticket);
      expect(restoreResult, isA<Ok<void, Failure>>());

      purchaseRow = await (db.select(
        db.purchases,
      )..where((p) => p.id.equals(purchaseId))).getSingle();
      expenseRow = await (db.select(
        db.expenses,
      )..where((e) => e.id.equals(expenseId))).getSingle();

      expect(purchaseRow.deletedAt, isNull);
      expect(expenseRow.deletedAt, isNull);
    });

    test('restore em registro inexistente retorna NotFoundFailure', () async {
      final ticket = TrashTicket(
        table: 'tasks',
        id: 'nao-existe',
        deletedAt: clock.nowUtc(),
      );
      final result = await policy.restore(ticket);
      expect(result, isA<Err<void, Failure>>());
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('restore on unsupported table returns StorageFailure', () async {
      final ticket = TrashTicket(
        table: 'categories',
        id: 'c1',
        deletedAt: clock.nowUtc(),
      );
      final result = await policy.restore(ticket);
      expect(result, isA<Err<void, Failure>>());
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    // -------------------------------------------------------------------------
    // sweepExpired
    // -------------------------------------------------------------------------
    test('sweepExpired removes only records > 30 days', () async {
      // CA-9.2: Given a record deleted 31 days ago and another 29 days ago
      final deleted31DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 31))
          .toIso8601String();
      final deleted29DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 29))
          .toIso8601String();

      await _insertTask(
        db,
        id: 'task-31d',
        title: 'Deleted 31 days ago',
        deletedAt: deleted31DaysAgo,
      );
      await _insertTask(
        db,
        id: 'task-29d',
        title: 'Deleted 29 days ago',
        deletedAt: deleted29DaysAgo,
      );

      final result = await policy.sweepExpired();
      expect(result, isA<Ok<int, Failure>>());
      expect(result.valueOrNull, 1);

      // Only the 31-day record is permanently removed
      final task31 = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals('task-31d'))).getSingleOrNull();
      final task29 = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals('task-29d'))).getSingleOrNull();

      expect(task31, isNull);
      expect(task29, isNotNull);
      expect(task29!.deletedAt, deleted29DaysAgo);
    });

    test(
      'sweepExpired is idempotent (running twice produces same result)',
      () async {
        final deleted31DaysAgo = clock
            .nowUtc()
            .subtract(const Duration(days: 31))
            .toIso8601String();
        final deleted29DaysAgo = clock
            .nowUtc()
            .subtract(const Duration(days: 29))
            .toIso8601String();

        await _insertTask(
          db,
          id: 'task-31d',
          title: 'Deleted 31 days ago',
          deletedAt: deleted31DaysAgo,
        );
        await _insertTask(
          db,
          id: 'task-29d',
          title: 'Deleted 29 days ago',
          deletedAt: deleted29DaysAgo,
        );

        // 1st run: removes 31-day record
        final first = await policy.sweepExpired();
        expect(first, isA<Ok<int, Failure>>());
        expect(first.valueOrNull, 1);

        // 2nd run on same day: no row to remove
        final second = await policy.sweepExpired();
        expect(second, isA<Ok<int, Failure>>());
        expect(second.valueOrNull, 0);

        // State remains identical
        final task31 = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('task-31d'))).getSingleOrNull();
        final task29 = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('task-29d'))).getSingleOrNull();

        expect(task31, isNull);
        expect(task29, isNotNull);
        expect(task29!.deletedAt, deleted29DaysAgo);
      },
    );

    test('sweepExpired does not remove records < 30 days', () async {
      final deleted1DayAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final deleted15DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 15))
          .toIso8601String();
      final deleted29DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 29))
          .toIso8601String();

      await _insertTask(
        db,
        id: 'task-1d',
        title: 'Ontem',
        deletedAt: deleted1DayAgo,
      );
      await _insertTask(
        db,
        id: 'task-15d',
        title: '15 dias',
        deletedAt: deleted15DaysAgo,
      );
      await _insertTask(
        db,
        id: 'task-29d',
        title: '29 dias',
        deletedAt: deleted29DaysAgo,
      );
      await _insertTask(
        db,
        id: 'task-active',
        title: 'Ativa (sem deleted_at)',
        deletedAt: null,
      );

      final result = await policy.sweepExpired();
      expect(result, isA<Ok<int, Failure>>());
      expect(result.valueOrNull, 0);

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 4);
    });

    test('sweepExpired with linked expired purchase and expense removes both without FK error', () async {
      const purchaseId = 'purch-exp';
      const expenseId = 'exp-exp';
      final deleted35DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 35))
          .toIso8601String();

      await _insertLinkedPurchaseAndExpense(
        db,
        purchaseId: purchaseId,
        expenseId: expenseId,
        deletedAt: deleted35DaysAgo,
      );

      final result = await policy.sweepExpired();
      expect(result, isA<Ok<int, Failure>>());
      expect(result.valueOrNull, 2);

      final p = await (db.select(
        db.purchases,
      )..where((row) => row.id.equals(purchaseId))).getSingleOrNull();
      final e = await (db.select(
        db.expenses,
      )..where((row) => row.id.equals(expenseId))).getSingleOrNull();

      expect(p, isNull);
      expect(e, isNull);
    });

    // -------------------------------------------------------------------------
    // Uso exclusivo de Clock (RN-004)
    // -------------------------------------------------------------------------
    test(
      'softDelete + restore + sweepExpired usam Clock, nunca DateTime.now()',
      () async {
        final fixedInstant = DateTime.utc(2026, 1, 10, 9, 15);
        clock.setTo(fixedInstant);

        await _insertTask(db, id: 'task-c1', title: 'Clock Task');

        // softDelete usa clock.nowUtc()
        final deleteResult = await policy.softDelete('tasks', 'task-c1');
        final ticket = deleteResult.valueOrNull!;
        expect(ticket.deletedAt, fixedInstant);

        final row = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('task-c1'))).getSingle();
        expect(row.deletedAt, fixedInstant.toIso8601String());

        // Advances 20 days in FakeClock: still retained
        clock.advance(const Duration(days: 20));
        var sweepResult = await policy.sweepExpired();
        expect(sweepResult.valueOrNull, 0);

        // Advances another 11 days in FakeClock (total 31 days): now expires
        clock.advance(const Duration(days: 11));
        sweepResult = await policy.sweepExpired();
        expect(sweepResult.valueOrNull, 1);

        final expiredRow = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('task-c1'))).getSingleOrNull();
        expect(expiredRow, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // TrashTicket e TrashEntry
    // -------------------------------------------------------------------------
    test('TrashTicket and TrashEntry conversions and equality', () {
      final now = DateTime.utc(2026, 9, 23, 10, 0);
      final ticket1 = TrashTicket(
        table: 'tasks',
        id: 't1',
        deletedAt: now,
        parentId: 'p1',
      );
      final ticket2 = TrashTicket(
        table: 'tasks',
        id: 't1',
        deletedAt: now,
        parentId: 'p1',
      );
      final ticket3 = TrashTicket(table: 'tasks', id: 't2', deletedAt: now);

      expect(ticket1, equals(ticket2));
      expect(ticket1.hashCode, equals(ticket2.hashCode));
      expect(ticket1, isNot(equals(ticket3)));
      expect(ticket1.toString(), contains('TrashTicket'));

      final entry = ticket1.toEntry();
      expect(entry.table, 'tasks');
      expect(entry.id, 't1');
      expect(entry.deletedAt, now);
      expect(entry.parentId, 'p1');

      final convertedBack = entry.toTicket();
      expect(convertedBack, equals(ticket1));

      final entry2 = TrashEntry(
        table: 'tasks',
        id: 't1',
        deletedAt: now,
        parentId: 'p1',
      );
      expect(entry, equals(entry2));
      expect(entry.hashCode, equals(entry2.hashCode));
      expect(entry.toString(), contains('TrashEntry'));
    });
  });
}

// ---------------------------------------------------------------------------
// Insertion helpers for testing
// ---------------------------------------------------------------------------

Future<void> _insertTask(
  AppDatabase db, {
  required String id,
  required String title,
  String? deletedAt,
}) async {
  await db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          id: id,
          title: title,
          deletedAt: Value(deletedAt),
        ),
      );
}

Future<void> _insertLinkedPurchaseAndExpense(
  AppDatabase db, {
  required String purchaseId,
  required String expenseId,
  String? deletedAt,
}) async {
  await db
      .into(db.purchases)
      .insert(
        PurchasesCompanion.insert(
          id: purchaseId,
          purchasedAt: '2026-09-23T10:00:00Z',
          totalCents: 5000,
          source: 'manual',
          deletedAt: Value(deletedAt),
        ),
      );
  await db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          id: expenseId,
          amountCents: 5000,
          occurredOn: '2026-09-23',
          purchaseId: Value(purchaseId),
          deletedAt: Value(deletedAt),
        ),
      );
  await db.customStatement(
    'UPDATE purchases SET expense_id = ? WHERE id = ?;',
    [expenseId, purchaseId],
  );
}
