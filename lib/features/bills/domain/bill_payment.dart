import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';

typedef BillPaymentId = String;

/// Generated occurrence per period (RN-132).
class BillPayment {
  final BillPaymentId id;
  final BillId billId;
  final DateTime dueOn;
  final DateTime? paidOn;
  final Money? paidAmount;

  const BillPayment({
    required this.id,
    required this.billId,
    required this.dueOn,
    this.paidOn,
    this.paidAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillPayment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          billId == other.billId &&
          dueOn == other.dueOn &&
          paidOn == other.paidOn &&
          paidAmount == other.paidAmount;

  @override
  int get hashCode =>
      id.hashCode ^
      billId.hashCode ^
      dueOn.hashCode ^
      paidOn.hashCode ^
      paidAmount.hashCode;
}
