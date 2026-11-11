/// Systems integration tests in My Sweet Home bootstrap (T-V4).
///
/// Verifies integration between:
/// - CA-9.1: Cascade restore purchase <-> expense within 30 days.
/// - CA-9.2: Trash sweep for records > 30 days with idempotent double run.
/// - CA-10.1: Recurrence materialization for all three kinds (expense, bill, task)
///   with double run on same day without duplicate creation.
///
/// Demonstra o bootstrap completo com [FakeClock], [AppDatabase.memory()],
/// [DefaultMaterializeRecurrences] e [DriftTrashPolicy].
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/bootstrap.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_materializer.dart';

void main() {
  group('T-V4: Subsystems Integration in Bootstrap (CA-9.1, CA-9.2, CA-10.1)', () {
    late AppDatabase db;
    late FakeClock clock;
    late DriftTrashPolicy trashPolicy;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));
      trashPolicy = DriftTrashPolicy(db: db, clock: clock);
    });

    tearDown(() async {
      await db.close();
    });

    test('Full cycle: bootstrap with materializer and trash, idempotent double '
        'run on same day, and 31 days advance purges expired', () async {
      // ---------------------------------------------------------------------
      // 1. Initial setup of materializers (CA-10.1)
      // ---------------------------------------------------------------------
      final expenseMat = FakeMaterializer(
        kind: RecurrenceKind.expense,
        pendingCount: 2,
      );
      final billMat = FakeMaterializer(
        kind: RecurrenceKind.bill,
        pendingCount: 1,
      );
      final taskMat = FakeMaterializer(
        kind: RecurrenceKind.task,
        pendingCount: 3,
      );

      final materializerUseCase = DefaultMaterializeRecurrences(
        materializers: [expenseMat, billMat, taskMat],
        clock: clock,
      );

      // ---------------------------------------------------------------------
      // 2. Database population (CA-9.1 and CA-9.2)
      // ---------------------------------------------------------------------
      // Item deleted 31 days ago (> 30 days: must be purged on first sweep)
      final deleted31DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 31))
          .toIso8601String();
      await _insertTask(
        db,
        id: 'task-31d',
        title: 'Task deleted 31 days ago',
        deletedAt: deleted31DaysAgo,
      );

      // Item deleted 29 days ago (<= 30 days: must remain in trash)
      final deleted29DaysAgo = clock
          .nowUtc()
          .subtract(const Duration(days: 29))
          .toIso8601String();
      await _insertTask(
        db,
        id: 'task-29d',
        title: 'Task deleted 29 days ago',
        deletedAt: deleted29DaysAgo,
      );

      // Active non-deleted item
      await _insertTask(db, id: 'task-active', title: 'Tarefa ativa');

      // Linked purchase and expense to test CA-9.1 (cascade restore)
      const purchaseId = 'purch-flow';
      const expenseId = 'exp-flow';
      await _insertLinkedPurchaseAndExpense(
        db,
        purchaseId: purchaseId,
        expenseId: expenseId,
      );
      // Exclui a compra logicamente hoje (2026-03-10 08:00)
      final deleteResult = await trashPolicy.softDelete(
        'purchases',
        purchaseId,
      );
      expect(deleteResult.isOk, isTrue);
      final purchaseTicket = deleteResult.valueOrNull!;

      // ---------------------------------------------------------------------
      // 3. First bootstrap execution on 2026-03-10 08:00
      // ---------------------------------------------------------------------
      final boot1 = await bootstrap(
        materializerUseCase,
        trashPolicy: trashPolicy,
      );

      expect(boot1.isOk, isTrue);
      final report1 = boot1.valueOrNull!;

      // CA-10.1: Materialization runs once for all three kinds
      expect(report1[RecurrenceKind.expense], 2);
      expect(report1[RecurrenceKind.bill], 1);
      expect(report1[RecurrenceKind.task], 3);
      expect(expenseMat.callCount, 1);
      expect(billMat.callCount, 1);
      expect(taskMat.callCount, 1);

      // CA-9.2: Only 31-day item is physically removed
      expect(report1.sweptTrashCount, 1);

      final task31AfterBoot1 = await _queryTask(db, 'task-31d');
      final task29AfterBoot1 = await _queryTask(db, 'task-29d');
      final taskActiveAfterBoot1 = await _queryTask(db, 'task-active');
      final purchaseAfterBoot1 = await _queryPurchase(db, purchaseId);
      final expenseAfterBoot1 = await _queryExpense(db, expenseId);

      expect(
        task31AfterBoot1,
        isNull,
        reason: 'Deleted 31 days ago must be purged',
      );
      expect(
        task29AfterBoot1,
        isNotNull,
        reason: 'Deleted 29 days ago must remain',
      );
      expect(taskActiveAfterBoot1, isNotNull, reason: 'Ativo permanece');
      expect(taskActiveAfterBoot1!.deletedAt, isNull);
      expect(purchaseAfterBoot1!.deletedAt, isNotNull);
      expect(expenseAfterBoot1!.deletedAt, isNotNull);

      // ---------------------------------------------------------------------
      // 4. Double run on same day (app reopening at 14:00)
      // ---------------------------------------------------------------------
      clock.advance(const Duration(hours: 6)); // 2026-03-10 14:00 (mesmo dia)

      final boot2 = await bootstrap(
        materializerUseCase,
        trashPolicy: trashPolicy,
      );

      expect(boot2.isOk, isTrue);
      final report2 = boot2.valueOrNull!;

      // CA-10.1: Reopening on same day creates no new occurrence
      expect(report2[RecurrenceKind.expense], 0);
      expect(report2[RecurrenceKind.bill], 0);
      expect(report2[RecurrenceKind.task], 0);

      // CA-9.2: Double daily sweep on same day changes nothing (idempotent)
      expect(report2.sweptTrashCount, 0);

      final task29AfterBoot2 = await _queryTask(db, 'task-29d');
      expect(task29AfterBoot2, isNotNull);
      expect(task29AfterBoot2!.deletedAt, deleted29DaysAgo);

      // ---------------------------------------------------------------------
      // 5. CA-9.1: Restoration within 30 days
      // ---------------------------------------------------------------------
      // Advances 5 days (2026-03-15) — well within 30-day retention window
      clock.advance(const Duration(days: 5));

      final restoreResult = await trashPolicy.restore(purchaseTicket);
      expect(restoreResult.isOk, isTrue);

      final restoredPurchase = await _queryPurchase(db, purchaseId);
      final restoredExpense = await _queryExpense(db, expenseId);

      expect(restoredPurchase, isNotNull);
      expect(restoredExpense, isNotNull);
      expect(restoredPurchase!.deletedAt, isNull);
      expect(restoredExpense!.deletedAt, isNull);
      expect(restoredPurchase.expenseId, expenseId);
      expect(restoredExpense.purchaseId, purchaseId);

      // Adds new item deleted today (2026-03-15)
      await _insertTask(
        db,
        id: 'task-will-expire',
        title: 'Deleted on 03/15, will expire in 31 days',
        deletedAt: clock.nowUtc().toIso8601String(),
      );

      // ---------------------------------------------------------------------
      // 6. 31 days clock advance and new bootstrap
      // ---------------------------------------------------------------------
      // Advances 31 days: clock goes to 2026-04-15
      // Agora:
      // - 'task-29d' was deleted on 02/09 (~65 days ago) -> MUST be deleted
      // - 'task-will-expire' was deleted on 03/15 (31 days ago) -> MUST be deleted
      // - 'task-active' -> permanece
      // - 'purch-flow' e 'exp-flow' (restauradas) -> permanecem
      clock.advance(const Duration(days: 31));

      // Sets new pending items for materializers on this new day
      expenseMat.pendingCount = 1;
      billMat.pendingCount = 1;
      taskMat.pendingCount = 1;

      final boot3 = await bootstrap(
        materializerUseCase,
        trashPolicy: trashPolicy,
      );

      expect(boot3.isOk, isTrue);
      final report3 = boot3.valueOrNull!;

      // Materialization runs normally on new day
      expect(report3[RecurrenceKind.expense], 1);
      expect(report3[RecurrenceKind.bill], 1);
      expect(report3[RecurrenceKind.task], 1);

      // Ambas as tarefas expiradas (> 30 dias) foram purgadas
      expect(report3.sweptTrashCount, 2);

      final task29AfterBoot3 = await _queryTask(db, 'task-29d');
      final taskWillExpireAfterBoot3 = await _queryTask(db, 'task-will-expire');
      final activeAfterBoot3 = await _queryTask(db, 'task-active');
      final purchaseAfterBoot3 = await _queryPurchase(db, purchaseId);
      final expenseAfterBoot3 = await _queryExpense(db, expenseId);

      expect(
        task29AfterBoot3,
        isNull,
        reason: 'Deleted > 30 days ago was deleted',
      );
      expect(
        taskWillExpireAfterBoot3,
        isNull,
        reason: 'Deleted 31 days ago was deleted',
      );
      expect(
        activeAfterBoot3,
        isNotNull,
        reason: 'Ativo nunca deve ser apagado',
      );
      expect(
        purchaseAfterBoot3,
        isNotNull,
        reason: 'Compra restaurada nunca deve ser apagada',
      );
      expect(purchaseAfterBoot3!.deletedAt, isNull);
      expect(
        expenseAfterBoot3,
        isNotNull,
        reason: 'Despesa restaurada nunca deve ser apagada',
      );
      expect(expenseAfterBoot3!.deletedAt, isNull);

      // ---------------------------------------------------------------------
      // 7. New double run on 2026-04-15
      // ---------------------------------------------------------------------
      clock.advance(const Duration(hours: 3));
      final boot4 = await bootstrap(
        materializerUseCase,
        trashPolicy: trashPolicy,
      );

      expect(boot4.isOk, isTrue);
      final report4 = boot4.valueOrNull!;
      expect(report4.sweptTrashCount, 0);
      expect(report4[RecurrenceKind.expense], 0);
      expect(report4[RecurrenceKind.bill], 0);
      expect(report4[RecurrenceKind.task], 0);
    });

    test(
      'bootstrap propagates materialization error without running trash sweep',
      () async {
        final failingMat = FakeMaterializer(
          kind: RecurrenceKind.expense,
          failure: const StorageFailure(detail: 'disk failure'),
        );
        final materializerUseCase = DefaultMaterializeRecurrences(
          materializers: [failingMat],
          clock: clock,
        );

        // Insere um item expirado (> 30 dias)
        final deleted31DaysAgo = clock
            .nowUtc()
            .subtract(const Duration(days: 31))
            .toIso8601String();
        await _insertTask(
          db,
          id: 'task-exp',
          title: 'Exp',
          deletedAt: deleted31DaysAgo,
        );

        final result = await bootstrap(
          materializerUseCase,
          trashPolicy: trashPolicy,
        );

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());

        // Sweep should not have run due to previous failure
        final taskExp = await _queryTask(db, 'task-exp');
        expect(
          taskExp,
          isNotNull,
          reason: 'Trash must not be swept on initial failure',
        );
      },
    );

    test(
      'bootstrap supports multiple trash sweepers via trashSweepers',
      () async {
        final mat = FakeMaterializer(
          kind: RecurrenceKind.task,
          pendingCount: 1,
        );
        final materializerUseCase = DefaultMaterializeRecurrences(
          materializers: [mat],
          clock: clock,
        );

        final deleted35DaysAgo = clock
            .nowUtc()
            .subtract(const Duration(days: 35))
            .toIso8601String();
        await _insertTask(
          db,
          id: 'task-multi',
          title: 'Multi',
          deletedAt: deleted35DaysAgo,
        );

        final result = await bootstrap(
          materializerUseCase,
          trashSweepers: [trashPolicy],
        );

        expect(result.isOk, isTrue);
        expect(result.valueOrNull!.sweptTrashCount, 1);
        expect(await _queryTask(db, 'task-multi'), isNull);
      },
    );
  });
}

// -----------------------------------------------------------------------------
// Test helpers for database insertion and query
// -----------------------------------------------------------------------------

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
          purchasedAt: '2026-03-10T08:00:00Z',
          totalCents: 4500,
          source: 'manual',
          deletedAt: Value(deletedAt),
        ),
      );
  await db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          id: expenseId,
          amountCents: 4500,
          occurredOn: '2026-03-10',
          purchaseId: Value(purchaseId),
          deletedAt: Value(deletedAt),
        ),
      );
  await db.customStatement(
    'UPDATE purchases SET expense_id = ? WHERE id = ?;',
    [expenseId, purchaseId],
  );
}

Future<Task?> _queryTask(AppDatabase db, String id) async {
  return (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
}

Future<Purchase?> _queryPurchase(AppDatabase db, String id) async {
  return (db.select(
    db.purchases,
  )..where((p) => p.id.equals(id))).getSingleOrNull();
}

Future<Expense?> _queryExpense(AppDatabase db, String id) async {
  return (db.select(
    db.expenses,
  )..where((e) => e.id.equals(id))).getSingleOrNull();
}
