import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';

abstract interface class PauseBillUseCase {
  Future<Result<void, Failure>> call(BillId id);
}

class DefaultPauseBillUseCase implements PauseBillUseCase {
  final BillRepository billRepo;
  final BillPaymentRepository paymentRepo;
  final NotificationSchedulerPort scheduler;
  final Clock clock;

  const DefaultPauseBillUseCase(
    this.billRepo,
    this.paymentRepo,
    this.scheduler,
    this.clock,
  );

  @override
  Future<Result<void, Failure>> call(BillId id) async {
    final pauseRes = await billRepo.pause(id);
    if (pauseRes.isErr) return pauseRes;

    final historyRes = await paymentRepo.historyOf(id);
    if (historyRes.isOk) {
      final payments = historyRes.valueOrNull!;

      for (final p in payments) {
        // Cancel notifications of pending occurrences (idempotent cancellation)
        // The rule specifies "cancel future notifications".
        // Cancel all unpaid occurrences.
        if (p.paidOn == null) {
          await scheduler.cancel('${p.id}_advance');
          await scheduler.cancel('${p.id}_due');
        }
      }
    }

    return const Ok(null);
  }
}
