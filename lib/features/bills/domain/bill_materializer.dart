import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

final class BillMaterializer implements RecurrenceMaterializer {
  final BillRepository billRepo;
  final BillPaymentRepository paymentRepo;
  final DueDatePolicy dueDatePolicy;
  final DeterministicIdGenerator deterministicIdGen;

  const BillMaterializer({
    required this.billRepo,
    required this.paymentRepo,
    required this.dueDatePolicy,
    this.deterministicIdGen = const UuidV5DeterministicIdGenerator(),
  });

  @override
  RecurrenceKind get kind => RecurrenceKind.bill;

  @override
  Future<Result<int, Failure>> materializeUpTo(DateTime instant) async {
    final activeBillsResult = await billRepo.active();
    if (activeBillsResult is Err<List<Bill>, Failure>) {
      return Err(activeBillsResult.failure);
    }

    final bills = (activeBillsResult as Ok<List<Bill>, Failure>).value;
    final payments = <BillPayment>[];

    for (final bill in bills) {
      final historyResult = await paymentRepo.historyOf(bill.id);
      final existingPayments = historyResult is Ok<List<BillPayment>, Failure>
          ? historyResult.value
          : <BillPayment>[];

      final DateTime startDate;
      if (existingPayments.isNotEmpty) {
        final latestDue = existingPayments
            .map((p) => p.dueOn)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        startDate = DateTime.utc(latestDue.year, latestDue.month + 1);
      } else {
        startDate = DateTime.utc(instant.year, instant.month);
      }

      if (startDate.isAfter(instant)) {
        continue;
      }

      var currentMonth = YearMonth.of(startDate);
      final endMonth = YearMonth.of(instant);

      while (currentMonth.iso.compareTo(endMonth.iso) <= 0) {
        final dueOn = dueDatePolicy.dueDateFor(
          dueDay: bill.dueDay,
          month: currentMonth,
        );

        final dueIso =
            '${dueOn.year.toString().padLeft(4, '0')}-${dueOn.month.toString().padLeft(2, '0')}-${dueOn.day.toString().padLeft(2, '0')}';
        final paymentId = deterministicIdGen.forOccurrence(bill.id, dueIso);
        payments.add(BillPayment(id: paymentId, billId: bill.id, dueOn: dueOn));
        currentMonth = currentMonth.next;
      }
    }

    if (payments.isEmpty) {
      return const Ok(0);
    }

    return paymentRepo.upsertOccurrences(payments);
  }
}
