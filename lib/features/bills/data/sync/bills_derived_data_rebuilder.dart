library;

import 'package:drift/drift.dart';

import '../../../../core/money/money.dart';
import '../../../../core/notifications/notification_scheduler_port.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/domain/derived_data_rebuilder.dart';
import '../../../../core/time/clock.dart';
import '../../../../data/database/database.dart';
import '../../domain/bill_payment.dart' as domain;
import '../../domain/reminder_planner.dart';

/// Reschedules or cancels bill notifications after batch application (RN-327, CA-5.4).
final class BillsDerivedDataRebuilder implements DerivedDataRebuilder {
  final AppDatabase db;
  final NotificationSchedulerPort scheduler;
  final ReminderPlanner planner;
  final Clock clock;

  const BillsDerivedDataRebuilder({
    required this.db,
    required this.scheduler,
    this.planner = const DefaultReminderPlanner(),
    this.clock = const SystemClock(),
  });

  @override
  Set<String> get watchesTables => const {'bills', 'bill_payments'};

  @override
  Future<Result<void, Failure>> rebuild(Set<String> touchedRowIds) async {
    try {
      final now = clock.nowLocal();
      const quiet = QuietHours();

      final query = db.select(db.billPayments).join([
        innerJoin(db.bills, db.bills.id.equalsExp(db.billPayments.billId)),
      ]);

      if (touchedRowIds.isNotEmpty) {
        query.where(
          db.billPayments.id.isIn(touchedRowIds) |
              db.bills.id.isIn(touchedRowIds),
        );
      }

      final rows = await query.get();

      for (final row in rows) {
        final payment = row.readTable(db.billPayments);
        final bill = row.readTable(db.bills);

        // If paid, bill was deactivated or has no billId
        if (payment.status == 'paid' ||
            payment.paidOn != null ||
            payment.billId == null ||
            !bill.isActive) {
          await scheduler.cancel('${payment.id}_advance');
          await scheduler.cancel('${payment.id}_due');
          continue;
        }

        // Se continua pendente e ativo, reagenda lembretes
        final domainPayment = domain.BillPayment(
          id: payment.id,
          billId: payment.billId!,
          dueOn: DateTime.parse(payment.dueOn),
          paidAmount: payment.amountCents != null
              ? Money(payment.amountCents!)
              : null,
          paidOn: payment.paidOn != null
              ? DateTime.parse(payment.paidOn!)
              : null,
        );

        final notifications = planner.plan(
          payment: domainPayment,
          billTitle: bill.title,
          daysBefore: bill.reminderDaysBefore,
          now: now,
          quiet: quiet,
        );

        for (final n in notifications) {
          await scheduler.schedule(n);
        }
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao reagendar notificações de contas: $e',
          cause: e,
        ),
      );
    }
  }
}
