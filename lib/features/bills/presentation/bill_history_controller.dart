import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';

sealed class BillHistoryState {}

class BillHistoryLoading extends BillHistoryState {}

class BillHistorySuccess extends BillHistoryState {
  final Bill bill;
  final List<BillPayment> payments;

  BillHistorySuccess({required this.bill, required this.payments});

  bool get isEmpty => payments.isEmpty;
}

class BillHistoryError extends BillHistoryState {
  final Failure failure;
  BillHistoryError(this.failure);
}

class BillHistoryController extends ValueNotifier<BillHistoryState> {
  BillHistoryController({
    required this.billId,
    required this._billRepository,
    required this._paymentRepository,
  }) : super(BillHistoryLoading()) {
    unawaited(load());
  }

  final BillId billId;
  final BillRepository _billRepository;
  final BillPaymentRepository _paymentRepository;

  Future<void> load() async {
    value = BillHistoryLoading();

    final billResult = await _billRepository.byId(billId);
    if (billResult is Err) {
      value = BillHistoryError((billResult as Err).failure);
      return;
    }

    final bill = (billResult as Ok<Bill?, Failure>).value;
    if (bill == null) {
      value = BillHistoryError(const NotFoundFailure(what: 'Bill not found'));
      return;
    }

    final historyResult = await _paymentRepository.historyOf(billId);
    if (historyResult is Err) {
      value = BillHistoryError((historyResult as Err).failure);
      return;
    }

    final payments = (historyResult as Ok<List<BillPayment>, Failure>).value;

    // Sort descending by dueOn so newest is first
    payments.sort((a, b) => b.dueOn.compareTo(a.dueOn));

    value = BillHistorySuccess(bill: bill, payments: payments);
  }
}
