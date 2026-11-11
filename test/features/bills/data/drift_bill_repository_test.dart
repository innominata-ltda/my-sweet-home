import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';

import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart' as domain;
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart'
    as domain;
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  late AppDatabase db;
  late DriftBillRepository billRepo;
  late DriftBillPaymentRepository paymentRepo;

  setUp(() async {
    db = AppDatabase.memory();
    billRepo = DriftBillRepository(db);
    paymentRepo = DriftBillPaymentRepository(db);

    await db
        .into(db.categories)
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
    await db.close();
  });

  test('upsert salva e active() retorna a conta', () async {
    final newBill = domain.NewBill(
      title: 'Aluguel',
      categoryId: const CategoryId('cat_housing'),
      dueDay: 5,
      recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
      amount: const Money(150000),
      isEstimated: false,
    );

    final res = await billRepo.upsert(newBill);
    expect(res.isOk, isTrue, reason: res.failureOrNull?.toString());
    final bill = res.valueOrNull!;
    expect(bill.title, 'Aluguel');

    final actives = await billRepo.active();
    expect(actives.valueOrNull!.length, 1);
  });

  test('upsertOccurrences salva pagamentos no mes', () async {
    final res1 = await billRepo.upsert(
      domain.NewBill(
        title: 'Luz',
        categoryId: const CategoryId('cat_housing'),
        dueDay: 10,
        recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
        isEstimated: true,
      ),
    );
    expect(res1.isOk, isTrue, reason: res1.failureOrNull?.toString());
    final bill = res1.valueOrNull!;

    final dueOn = DateTime.utc(2026, 10, 10);
    final payment = domain.BillPayment(id: 'p1', billId: bill.id, dueOn: dueOn);

    final res = await paymentRepo.upsertOccurrences([payment]);
    expect(res.isOk, isTrue);
    expect(res.valueOrNull, 1);

    final monthRes = await paymentRepo.ofMonth(const YearMonth('2026-10'));
    final list = monthRes.valueOrNull!;
    expect(list.length, 1);
    expect(list.first.paidOn, isNull);

    // markPaid
    final paidOn = DateTime.utc(2026, 10, 11);
    final markRes = await paymentRepo.markPaid(
      payment.id,
      amount: const Money(12000),
      paidOn: paidOn,
    );
    expect(markRes.isOk, isTrue);
    expect(markRes.valueOrNull!.paidOn, isNotNull);
    expect(markRes.valueOrNull!.paidAmount, const Money(12000));

    // byId
    final byIdRes = await paymentRepo.byId(payment.id);
    expect(byIdRes.isOk, isTrue);
    expect(byIdRes.valueOrNull?.paidAmount, const Money(12000));

    // historyOf
    final histRes = await paymentRepo.historyOf(bill.id);
    expect(histRes.isOk, isTrue);
    expect(histRes.valueOrNull!.length, 1);

    // unmarkPaid
    final unmarkRes = await paymentRepo.unmarkPaid(payment.id);
    expect(unmarkRes.isOk, isTrue);
    expect(unmarkRes.valueOrNull!.paidOn, isNull);

    // pause, byId e delete no billRepo
    final billById = await billRepo.byId(bill.id);
    expect(billById.isOk, isTrue);
    expect(billById.valueOrNull?.title, 'Luz');

    final pauseRes = await billRepo.pause(bill.id);
    expect(pauseRes.isOk, isTrue);
    final billPaused = await billRepo.byId(bill.id);
    expect(billPaused.valueOrNull?.isPaused, isTrue);

    final delRes = await billRepo.delete(bill.id);
    expect(delRes.isOk, isTrue);
    final billDeleted = await billRepo.byId(bill.id);
    expect(billDeleted.valueOrNull, isNull);
  });

  test('deleting bill with linked expense preserves referential integrity without FK error', () async {
    final res = await billRepo.upsert(
      domain.NewBill(
        title: 'Internet',
        categoryId: const CategoryId('cat_housing'),
        dueDay: 15,
        recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
        amount: const Money(12000),
        isEstimated: false,
      ),
    );
    expect(res.isOk, isTrue);
    final bill = res.valueOrNull!;

    // Cria fatura/pagamento
    final payment = domain.BillPayment(
      id: 'pay_internet_1',
      billId: bill.id,
      dueOn: DateTime.utc(2026, 10, 15),
    );
    await paymentRepo.upsertOccurrences([payment]);

    // Insere despesa vinculada diretamente a conta fixa
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'exp_internet_1',
            amountCents: 12000,
            occurredOn: '2026-10-15',
            categoryId: const Value('cat_housing'),
            billId: Value(bill.id),
          ),
        );

    // Insere despesa associada via fatura (expenseId)
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'exp_internet_2',
            amountCents: 12000,
            occurredOn: '2026-11-15',
            categoryId: const Value('cat_housing'),
            billId: Value(bill.id),
          ),
        );
    await (db.update(db.billPayments)..where((t) => t.id.equals(payment.id)))
        .write(const BillPaymentsCompanion(expenseId: Value('exp_internet_2')));

    // Exclui a conta fixa
    final delRes = await billRepo.delete(bill.id);
    expect(delRes.isOk, isTrue, reason: delRes.failureOrNull?.toString());

    // Bill must no longer exist
    final billCheck = await billRepo.byId(bill.id);
    expect(billCheck.valueOrNull, isNull);

    // Invoice record must no longer exist
    final payCheck = await paymentRepo.byId(payment.id);
    expect(payCheck.valueOrNull, isNull);

    // As despesas continuam no banco, porem sem vinculo de billId
    final exp1 = await (db.select(
      db.expenses,
    )..where((t) => t.id.equals('exp_internet_1'))).getSingle();
    expect(exp1.billId, isNull);

    final exp2 = await (db.select(
      db.expenses,
    )..where((t) => t.id.equals('exp_internet_2'))).getSingle();
    expect(exp2.billId, isNull);
  });
}
