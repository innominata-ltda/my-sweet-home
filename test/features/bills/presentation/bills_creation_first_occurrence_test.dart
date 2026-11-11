import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide Bill, BillPayment;
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
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
            id: 'cat_services',
            name: 'Serviços',
            kind: 'expense',
            iconKey: 'service',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('when registering on day 22 a bill due on day 10, first occurrence is next month and nothing in past', () async {
    // Simulates creation on October 22, 2026 with due date on day 10
    final now = DateTime.utc(2026, 10, 22);
    final today = DateTime.utc(now.year, now.month, now.day);
    final yearMonth = YearMonth.of(now);
    const dueDatePolicy = StandardDueDatePolicy();

    final addResult = await billRepo.upsert(
      NewBill(
        id: 'bill_test_1',
        title: 'Internet Fibra',
        categoryId: const CategoryId('cat_services'),
        dueDay: 10,
        recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
        amount: const Money(15000),
        isEstimated: false,
      ),
    );

    expect(addResult.isOk, isTrue);
    final bill = (addResult as Ok<Bill, Failure>).value;

    // Logic identical to bills_page_container
    final thisMonthDue = dueDatePolicy.dueDateFor(
      dueDay: bill.dueDay,
      month: yearMonth,
    );

    final firstMonth = thisMonthDue.isBefore(today)
        ? yearMonth.next
        : yearMonth;
    final firstDueOn = dueDatePolicy.dueDateFor(
      dueDay: bill.dueDay,
      month: firstMonth,
    );

    final firstDueIso =
        '${firstDueOn.year.toString().padLeft(4, '0')}-${firstDueOn.month.toString().padLeft(2, '0')}-${firstDueOn.day.toString().padLeft(2, '0')}';
    const idGen = UuidV5DeterministicIdGenerator();
    await paymentRepo.upsertOccurrences([
      BillPayment(
        id: idGen.forOccurrence(bill.id, firstDueIso),
        billId: bill.id,
        dueOn: firstDueOn,
      ),
    ]);

    // Materializes next 60 days
    final materializer = BillMaterializer(
      billRepo: billRepo,
      paymentRepo: paymentRepo,
      dueDatePolicy: dueDatePolicy,
    );
    await materializer.materializeUpTo(now.add(const Duration(days: 60)));

    // Verifies October 2026 payments: must be EMPTY (no overdue bill)
    final octPayments = await paymentRepo.ofMonth(YearMonth('2026-10'));
    expect(octPayments.valueOrNull, isEmpty);

    // Verify past payments: must be empty
    final sepPayments = await paymentRepo.ofMonth(YearMonth('2026-09'));
    expect(sepPayments.valueOrNull, isEmpty);

    // Verifies November 2026 payments (next month): must contain due date on 10/11
    final novPayments = await paymentRepo.ofMonth(YearMonth('2026-11'));
    expect(novPayments.valueOrNull, hasLength(1));
    expect(novPayments.valueOrNull!.first.dueOn, DateTime.utc(2026, 11, 10));
  });
}
