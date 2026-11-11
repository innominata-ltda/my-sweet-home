import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

abstract interface class PayBillUseCase {
  Future<Result<BillPayment, Failure>> call(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  });
}

abstract interface class UnpayBillUseCase {
  Future<Result<BillPayment, Failure>> call(BillPaymentId id);
}

class DefaultPayBillUseCase implements PayBillUseCase {
  final BillPaymentRepository paymentRepo;
  final BillRepository billRepo;
  final ExpenseRepository expenseRepo;
  final NotificationSchedulerPort scheduler;

  const DefaultPayBillUseCase(
    this.paymentRepo,
    this.billRepo,
    this.expenseRepo,
    this.scheduler,
  );

  @override
  Future<Result<BillPayment, Failure>> call(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  }) async {
    // 1. Fetch payment
    final paymentRes = await paymentRepo.byId(id);
    if (paymentRes.isErr) return Err(paymentRes.failureOrNull!);
    final payment = paymentRes.valueOrNull;
    if (payment == null) return Err(NotFoundFailure(what: 'BillPayment $id'));

    // 2. Fetch bill
    final billRes = await billRepo.byId(payment.billId);
    if (billRes.isErr) return Err(billRes.failureOrNull!);
    final bill = billRes.valueOrNull;
    if (bill == null) {
      return Err(NotFoundFailure(what: 'Bill ${payment.billId}'));
    }

    // 3. Mark paid
    final markRes = await paymentRepo.markPaid(
      id,
      amount: amount,
      paidOn: paidOn,
    );
    if (markRes.isErr) return Err(markRes.failureOrNull!);
    final updatedPayment = markRes.valueOrNull!;

    // 4. Create expense
    final expenseRes = await expenseRepo.add(
      NewExpense(
        amount: amount,
        occurredOn: paidOn,
        description: bill.title,
        categoryId: bill.categoryId,
        billId: bill.id,
      ),
    );
    if (expenseRes.isErr) return Err(expenseRes.failureOrNull!);

    // 5. Cancel notifications
    await scheduler.cancel('${id}_advance');
    await scheduler.cancel('${id}_due');

    return Ok(updatedPayment);
  }
}

class DefaultUnpayBillUseCase implements UnpayBillUseCase {
  final BillPaymentRepository paymentRepo;
  final BillRepository billRepo;
  final ExpenseRepository expenseRepo;
  final ReminderPlanner planner;
  final NotificationSchedulerPort scheduler;
  final Clock clock;

  const DefaultUnpayBillUseCase(
    this.paymentRepo,
    this.billRepo,
    this.expenseRepo,
    this.planner,
    this.scheduler,
    this.clock,
  );

  @override
  Future<Result<BillPayment, Failure>> call(BillPaymentId id) async {
    final paymentRes = await paymentRepo.byId(id);
    if (paymentRes.isErr) return Err(paymentRes.failureOrNull!);
    final payment = paymentRes.valueOrNull;
    if (payment == null) return Err(NotFoundFailure(what: 'BillPayment $id'));

    if (payment.paidOn == null) {
      return Ok(payment); // already unpaid
    }

    // 1. Unmark paid
    final paidOn = payment.paidOn!;
    final markRes = await paymentRepo.unmarkPaid(id);
    if (markRes.isErr) return Err(markRes.failureOrNull!);
    final updatedPayment = markRes.valueOrNull!;

    // 2. Remove expense
    final month = YearMonth.of(paidOn);
    final expensesRes = await expenseRepo.ofMonth(month);
    if (expensesRes.isOk) {
      final expenses = expensesRes.valueOrNull!;
      for (final ex in expenses) {
        if (ex.billId == payment.billId &&
            ex.occurredOn == paidOn &&
            ex.amount == payment.paidAmount) {
          await expenseRepo.remove(ex.id);
          break; // remove only one matching expense
        }
      }
    }

    // 3. Reschedule notifications
    final billRes = await billRepo.byId(payment.billId);
    if (billRes.isOk) {
      final bill = billRes.valueOrNull;
      if (bill != null) {
        final now = clock.nowUtc();
        const quiet = QuietHours();
        final notifications = planner.plan(
          payment: updatedPayment,
          billTitle: bill.title,
          daysBefore: bill.noticeDays,
          now: now,
          quiet: quiet,
        );

        for (final n in notifications) {
          await scheduler.schedule(n);
        }
      }
    }

    return Ok(updatedPayment);
  }
}
