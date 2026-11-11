import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

class FakeBillPaymentRepository implements BillPaymentRepository {
  final Map<BillPaymentId, BillPayment> _payments = {};

  @override
  Future<Result<List<BillPayment>, Failure>> ofMonth(YearMonth m) async {
    return Ok(
      _payments.values.where((p) {
        return YearMonth.of(p.dueOn) == m;
      }).toList(),
    );
  }

  @override
  Future<Result<BillPayment, Failure>> markPaid(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  }) async {
    final payment = _payments[id];
    if (payment == null) return Err(NotFoundFailure(what: 'BillPayment $id'));

    final updated = BillPayment(
      id: payment.id,
      billId: payment.billId,
      dueOn: payment.dueOn,
      paidOn: paidOn,
      paidAmount: amount,
    );
    _payments[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<BillPayment, Failure>> unmarkPaid(BillPaymentId id) async {
    final payment = _payments[id];
    if (payment == null) return Err(NotFoundFailure(what: 'BillPayment $id'));

    final updated = BillPayment(
      id: payment.id,
      billId: payment.billId,
      dueOn: payment.dueOn,
      paidOn: null,
      paidAmount: null,
    );
    _payments[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<List<BillPayment>, Failure>> historyOf(BillId id) async {
    return Ok(_payments.values.where((p) => p.billId == id).toList());
  }

  @override
  Future<Result<int, Failure>> upsertOccurrences(
    List<BillPayment> payments,
  ) async {
    int count = 0;
    for (final p in payments) {
      if (!_payments.containsKey(p.id)) {
        _payments[p.id] = p;
        count++;
      }
    }
    return Ok(count);
  }

  @override
  Future<Result<BillPayment?, Failure>> byId(BillPaymentId id) async {
    return Ok(_payments[id]);
  }
}
