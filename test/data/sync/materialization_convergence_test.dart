import 'package:drift/drift.dart' hide Column;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task, Category;
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart' as bills_domain;
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/data/recurrence/expense_materializer.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/tasks/data/task_dao.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

import '../../fakes/fake_clock.dart';

void main() {
  const deterministicIdGen = UuidV5DeterministicIdGenerator();

  group(
    // Recurrent materialization convergence
    'Convergencia de Materializacao Recorrente (CA-5.4, RF-124, RN-324)',
    () {
      late AppDatabase dbA;
      late AppDatabase dbB;

      setUp(() async {
        dbA = AppDatabase.memory();
        dbB = AppDatabase.memory();

        // Setup initial categories
        await dbA
            .into(dbA.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat_housing',
                name: 'Moradia',
                kind: 'expense',
                iconKey: 'home',
              ),
            );
        await dbB
            .into(dbB.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat_housing',
                name: 'Moradia',
                kind: 'expense',
                iconKey: 'home',
              ),
            );
      });

      tearDown(() async {
        await dbA.close();
        await dbB.close();
      });

      test('CA-5.4: dois aparelhos offline materializam conta fixa do mesmo mes -> ids identicos e sem duplicacao', () async {
        final billRepoA = DriftBillRepository(dbA);
        final billRepoB = DriftBillRepository(dbB);
        final paymentRepoA = DriftBillPaymentRepository(dbA);
        final paymentRepoB = DriftBillPaymentRepository(dbB);

        // Ambas as instalacoes tem a mesma conta fixa com o mesmo ID
        const billId = 'bill-aluguel-001';
        final newBill = bills_domain.NewBill(
          id: billId,
          title: 'Aluguel',
          categoryId: const CategoryId('cat_housing'),
          dueDay: 10,
          recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
          amount: const Money(150000),
          isEstimated: false,
        );
        await billRepoA.upsert(newBill);
        await billRepoB.upsert(newBill);

        // Materializador em A e em B
        final matA = BillMaterializer(
          billRepo: billRepoA,
          paymentRepo: paymentRepoA,
          dueDatePolicy: const StandardDueDatePolicy(),
        );
        final matB = BillMaterializer(
          billRepo: billRepoB,
          paymentRepo: paymentRepoB,
          dueDatePolicy: const StandardDueDatePolicy(),
        );

        final instant = DateTime.utc(2026, 11, 15);
        final resA = await matA.materializeUpTo(instant);
        final resB = await matB.materializeUpTo(instant);

        expect(resA.isOk, isTrue);
        expect(resB.isOk, isTrue);

        final paymentsA = await (dbA.select(
          dbA.billPayments,
        )..where((tbl) => tbl.billId.equals(billId))).get();
        final paymentsB = await (dbB.select(
          dbB.billPayments,
        )..where((tbl) => tbl.billId.equals(billId))).get();

        expect(paymentsA.length, equals(paymentsB.length));
        expect(paymentsA.length, greaterThan(0));

        final uuidV5Pattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        );

        for (var i = 0; i < paymentsA.length; i++) {
          expect(
            paymentsA[i].id,
            equals(paymentsB[i].id),
            reason: 'Payment ID must be identical across devices for same rule+date',
          );
          expect(
            paymentsA[i].id,
            matches(uuidV5Pattern),
            reason: 'Payment ID deve ser UUID v5 deterministico (RN-324)',
          );
          final dueDate = DateTime.parse(paymentsA[i].dueOn).toUtc();
          expect(
            paymentsA[i].id,
            equals(billRepoA.deterministicPaymentId(billId, dueDate)),
          );
          expect(paymentsA[i].dueOn, equals(paymentsB[i].dueOn));
        }

        // Ao aplicar/mesclar os pagamentos de B em A (simulando sync com insertOrIgnore)
        for (final p in paymentsB) {
          await dbA
              .into(dbA.billPayments)
              .insert(
                BillPaymentsCompanion.insert(
                  id: p.id,
                  billId: Value(p.billId),
                  dueOn: p.dueOn,
                  status: p.status,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

        final mergedPayments = await (dbA.select(
          dbA.billPayments,
        )..where((tbl) => tbl.billId.equals(billId))).get();
        expect(
          mergedPayments.length,
          equals(paymentsA.length),
          reason: 'No duplicate payments allowed after merge',
        );
      });

      test('materializacao de despesas recorrentes em A e B produz IDs identicos e deterministas', () async {
        const idGen = UuidV7Generator();

        const ruleId = 'rec-rule-supermercado';
        await dbA
            .into(dbA.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: ruleId,
                kind: 'expense',
                rrule: 'FREQ=MONTHLY;INTERVAL=1',
                startsOn: '2026-10-01',
                title: 'Feira Mensal',
                amountCents: const Value(30000),
                categoryId: const Value('cat_housing'),
              ),
            );
        await dbB
            .into(dbB.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: ruleId,
                kind: 'expense',
                rrule: 'FREQ=MONTHLY;INTERVAL=1',
                startsOn: '2026-10-01',
                title: 'Feira Mensal',
                amountCents: const Value(30000),
                categoryId: const Value('cat_housing'),
              ),
            );

        final expMatA = ExpenseMaterializer(db: dbA, idGenerator: idGen);
        final expMatB = ExpenseMaterializer(db: dbB, idGenerator: idGen);

        final instant = DateTime.utc(2026, 10, 22);
        await expMatA.materializeUpTo(instant);
        await expMatB.materializeUpTo(instant);

        final expA = await (dbA.select(
          dbA.expenses,
        )..where((tbl) => tbl.recurringRuleId.equals(ruleId))).get();
        final expB = await (dbB.select(
          dbB.expenses,
        )..where((tbl) => tbl.recurringRuleId.equals(ruleId))).get();

        expect(expA.length, equals(1));
        expect(expB.length, equals(1));
        expect(expA.first.id, equals(expB.first.id));
        expect(
          expA.first.id,
          equals(deterministicIdGen.forOccurrence(ruleId, '2026-10-01')),
        );

        // Simulating sync from B to A: no duplicate created
        for (final e in expB) {
          await dbA
              .into(dbA.expenses)
              .insert(
                ExpensesCompanion.insert(
                  id: e.id,
                  amountCents: e.amountCents,
                  occurredOn: e.occurredOn,
                  recurringRuleId: Value(e.recurringRuleId),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

        final mergedExp = await (dbA.select(
          dbA.expenses,
        )..where((tbl) => tbl.recurringRuleId.equals(ruleId))).get();
        expect(mergedExp.length, equals(1));
      });

      test('conclusao de tarefa recorrente em A e B gera proxima ocorrencia com mesmo ID deterministico', () async {
        final clock = FakeClock(DateTime.utc(2026, 10, 22, 10, 0));
        const idGen = UuidV7Generator();
        final trashPolicyA = DriftTrashPolicy.system(db: dbA);
        final trashPolicyB = DriftTrashPolicy.system(db: dbB);

        final taskDaoA = TaskDao(
          db: dbA,
          clock: clock,
          idGenerator: idGen,
          trashPolicy: trashPolicyA,
        );
        final taskDaoB = TaskDao(
          db: dbB,
          clock: clock,
          idGenerator: idGen,
          trashPolicy: trashPolicyB,
        );

        const ruleId = 'FREQ=DAILY;INTERVAL=7';
        final dueAt = DateTime.utc(2026, 10, 22, 14, 0);

        // Inserir tarefa em A
        final createdA = await taskDaoA.upsert(
          NewTask(
            title: 'Regar plantas',
            allDay: true,
            dueAt: dueAt,
            recurringRuleId: ruleId,
          ),
        );
        expect(createdA.isOk, isTrue);
        final taskId = createdA.valueOrNull!.id;

        // Cria a regra correspondente em B
        final ruleRowA = await (dbA.select(dbA.recurringRules)).getSingle();
        await dbB
            .into(dbB.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: ruleRowA.id,
                kind: 'task',
                rrule: ruleId,
                startsOn: ruleRowA.startsOn,
                title: 'Regar plantas',
              ),
            );

        // Inserir mesma tarefa em B (simulando sync da tarefa inicial)
        final nowIso = clock.nowUtc().toIso8601String();
        await dbB
            .into(dbB.tasks)
            .insert(
              TasksCompanion.insert(
                id: taskId,
                title: 'Regar plantas',
                allDay: const Value(true),
                dueAt: Value(dueAt.toUtc().toIso8601String()),
                recurringRuleId: Value(ruleRowA.id),
                syncState: const Value('synced'),
                createdAt: Value(nowIso),
                updatedAt: Value(nowIso),
              ),
            );

        // Ambas as instalacoes concluem a tarefa
        await taskDaoA.complete(taskId);
        await taskDaoB.complete(taskId);

        final allA = await taskDaoA.allTasksForSync();
        final allB = await taskDaoB.allTasksForSync();

        expect(allA.isOk, isTrue);
        expect(allB.isOk, isTrue);

        final uncompletedA = allA.valueOrNull!
            .where((t) => !t.isCompleted)
            .toList();
        final uncompletedB = allB.valueOrNull!
            .where((t) => !t.isCompleted)
            .toList();

        expect(uncompletedA.length, equals(1));
        expect(uncompletedB.length, equals(1));
        expect(
          uncompletedA.first.id,
          equals(uncompletedB.first.id),
          reason: 'Proxima ocorrencia recorrente da tarefa deve ter o mesmo ID deterministico em A e B',
        );
      });
    },
  );
}
