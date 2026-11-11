import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';

enum BillStatus { pending, paid, late, skipped }

abstract interface class BillStatusPolicy {
  BillStatus statusOf(BillPayment p, DateTime now);
}

class DefaultBillStatusPolicy implements BillStatusPolicy {
  @override
  BillStatus statusOf(BillPayment p, DateTime now) {
    if (p.paidOn != null) {
      return BillStatus.paid;
    }

    final dueDate = DateTime.utc(p.dueOn.year, p.dueOn.month, p.dueOn.day);
    final today = DateTime.utc(now.year, now.month, now.day);

    if (today.isAfter(dueDate)) {
      return BillStatus.late;
    }

    return BillStatus.pending;
  }
}
