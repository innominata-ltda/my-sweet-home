import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/pay_bill_use_case.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';

import '../../fakes/fake_bill_payment_repository.dart';
import '../../fakes/fake_bill_repository.dart';
import '../../fakes/fake_clock.dart';
import '../../fakes/recording_scheduler.dart';
import '../../fakes/sequential_id_generator.dart';

import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';

void main() {
  group('PayBillUseCase', () {
    late FakeBillPaymentRepository paymentRepo;
    late FakeBillRepository billRepo;
    late FakeExpenseRepository expenseRepo;
    late RecordingScheduler scheduler;
    late DefaultPayBillUseCase payBillUseCase;
    late DefaultUnpayBillUseCase unpayBillUseCase;
    late FakeClock clock;
    late IdGenerator idGenerator;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 5));
      idGenerator = SequentialIdGenerator();
      paymentRepo = FakeBillPaymentRepository();
      billRepo = FakeBillRepository(idGenerator);
      expenseRepo = FakeExpenseRepository(clock);
      scheduler = RecordingScheduler();

      payBillUseCase = DefaultPayBillUseCase(
        paymentRepo,
        billRepo,
        expenseRepo,
        scheduler,
      );
      unpayBillUseCase = DefaultUnpayBillUseCase(
        paymentRepo,
        billRepo,
        expenseRepo,
        const DefaultReminderPlanner(),
        scheduler,
        clock,
      );
    });

    test(
      'CA-2.2: pago -> despesa criada, 0 pendentes e notificações canceladas',
      () async {
        // Setup
        final newBill = NewBill(
          id: 'bill_1',
          title: 'Internet',
          categoryId: CategoryId('cat_1'),
          dueDay: 5,
          recurrence: RecurrenceRule.tryParse(
            'FREQ=MONTHLY',
            dtStart: DateTime.utc(2026, 3, 5),
          )!,
          isEstimated: false,
        );
        await billRepo.upsert(newBill);

        final payment = BillPayment(
          id: 'payment_1',
          billId: 'bill_1',
          dueOn: DateTime.utc(2026, 3, 5),
        );
        await paymentRepo.upsertOccurrences([payment]);

        // Act
        final amount = Money(15000); // 150.00
        final paidOn = clock.nowUtc();
        final result = await payBillUseCase(
          payment.id,
          amount: amount,
          paidOn: paidOn,
        );

        // Assert
        expect(result.isOk, isTrue);
        expect(result.valueOrNull!.paidOn, paidOn);
        expect(result.valueOrNull!.paidAmount, amount);

        final expensesResult = await expenseRepo.ofMonth(YearMonth.of(paidOn));
        final expenses = expensesResult.valueOrNull!;
        expect(expenses.length, 1);
        expect(expenses.first.billId, 'bill_1');
        expect(expenses.first.description, 'Internet');
        expect(expenses.first.categoryId, CategoryId('cat_1'));
        expect(expenses.first.amount, amount);
        expect(expenses.first.occurredOn, paidOn);

        expect(scheduler.scheduled, isEmpty);
      },
    );

    test('CA-2.3: mesmo teste, desmarcando: despesa some', () async {
      // Setup
      final newBill = NewBill(
        id: 'bill_1',
        title: 'Internet',
        categoryId: CategoryId('cat_1'),
        dueDay: 5,
        recurrence: RecurrenceRule.tryParse(
          'FREQ=MONTHLY',
          dtStart: DateTime.utc(2026, 3, 5),
        )!,
        isEstimated: false,
      );
      await billRepo.upsert(newBill);

      final payment = BillPayment(
        id: 'payment_1',
        billId: 'bill_1',
        dueOn: DateTime.utc(2026, 3, 5),
      );
      await paymentRepo.upsertOccurrences([payment]);

      final amount = Money(15000); // 150.00
      final paidOn = clock.nowUtc();
      await payBillUseCase(payment.id, amount: amount, paidOn: paidOn);

      var expensesResult = await expenseRepo.ofMonth(YearMonth.of(paidOn));
      expect(expensesResult.valueOrNull!.length, 1);

      // Act: Unpay
      final unpayResult = await unpayBillUseCase(payment.id);

      // Assert
      expect(unpayResult.isOk, isTrue);
      expect(unpayResult.valueOrNull!.paidOn, isNull);
      expect(unpayResult.valueOrNull!.paidAmount, isNull);

      expensesResult = await expenseRepo.ofMonth(YearMonth.of(paidOn));
      expect(expensesResult.valueOrNull!.length, 0); // despesa some

      // Should have rescheduled only due notification since advanceDate is in past
      expect(
        scheduler.scheduled.map((e) => e.id),
        containsAll(['payment_1_due']),
      );
    });
  });
}
