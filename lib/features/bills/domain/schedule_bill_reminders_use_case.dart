import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';

class ScheduleBillRemindersUseCase {
  final BillRepository billRepo;
  final BillPaymentRepository paymentRepo;
  final ReminderPlanner planner;
  final NotificationSchedulerPort scheduler;
  final Clock clock;

  const ScheduleBillRemindersUseCase({
    required this.billRepo,
    required this.paymentRepo,
    required this.planner,
    required this.scheduler,
    required this.clock,
  });

  Future<Result<void, Failure>> call() async {
    final billsResult = await billRepo.active();
    if (billsResult is Err<List<Bill>, Failure>) {
      return Err(billsResult.failure);
    }
    final bills = (billsResult as Ok<List<Bill>, Failure>).value;

    final now = clock.nowLocal();
    const quiet = QuietHours();

    for (final bill in bills) {
      final historyResult = await paymentRepo.historyOf(bill.id);
      if (historyResult is Err<List<BillPayment>, Failure>) {
        return Err(historyResult.failure);
      }
      final payments = (historyResult as Ok<List<BillPayment>, Failure>).value;

      for (final payment in payments) {
        if (payment.paidOn != null) {
          continue; // RN-134
        }

        final notifications = planner.plan(
          payment: payment,
          billTitle: bill.title,
          daysBefore: bill.noticeDays,
          now: now,
          quiet: quiet,
        );

        for (final n in notifications) {
          final res = await scheduler.schedule(n);
          if (res is Err) {
            return res;
          }
        }
      }
    }

    return const Ok(null);
  }
}
