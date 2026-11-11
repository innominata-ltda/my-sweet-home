import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

class DueBillItem {
  final Bill bill;
  final BillPayment payment;
  final BillStatus status;
  final String dueLabel;

  const DueBillItem({
    required this.bill,
    required this.payment,
    required this.status,
    required this.dueLabel,
  });

  Money? get amount => payment.paidAmount ?? bill.amount;
}

sealed class DueBillsWidgetState {}

class DueBillsWidgetLoading extends DueBillsWidgetState {}

class DueBillsWidgetSuccess extends DueBillsWidgetState {
  final List<DueBillItem> items;
  final bool hideValues;

  DueBillsWidgetSuccess({required this.items, this.hideValues = false});

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
}

class DueBillsWidgetError extends DueBillsWidgetState {
  final Failure failure;

  DueBillsWidgetError(this.failure);
}

/// Controller para o widget de contas a vencer (RF-102, RN-253, CA-3.1, CA-3.2).
class DueBillsWidgetController extends ValueNotifier<DueBillsWidgetState> {
  DueBillsWidgetController({
    required this._billRepository,
    required this._paymentRepository,
    BillStatusPolicy? statusPolicy,
    Clock? clock,
    this._hideValues = false,
  }) : _statusPolicy = statusPolicy ?? DefaultBillStatusPolicy(),
       _clock = clock ?? const SystemClock(),
       super(DueBillsWidgetLoading()) {
    unawaited(load());
  }

  final BillRepository _billRepository;
  final BillPaymentRepository _paymentRepository;
  final BillStatusPolicy _statusPolicy;
  final Clock _clock;
  bool _hideValues;
  bool _disposed = false;

  bool get hideValues => _hideValues;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(DueBillsWidgetState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  void setHideValues(bool value) {
    if (_hideValues != value) {
      _hideValues = value;
      if (this.value is DueBillsWidgetSuccess) {
        final current = this.value as DueBillsWidgetSuccess;
        this.value = DueBillsWidgetSuccess(
          items: current.items,
          hideValues: _hideValues,
        );
      }
    }
  }

  Future<void> load() async {
    value = DueBillsWidgetLoading();

    final now = _clock.nowUtc();
    final yearMonth = YearMonth.of(now);

    final billsResult = await _billRepository.active();
    if (billsResult is Err) {
      value = DueBillsWidgetError((billsResult as Err).failure);
      return;
    }

    final currentPaymentsResult = await _paymentRepository.ofMonth(yearMonth);
    if (currentPaymentsResult is Err) {
      value = DueBillsWidgetError((currentPaymentsResult as Err).failure);
      return;
    }

    final prevPaymentsResult = await _paymentRepository.ofMonth(
      yearMonth.previous,
    );
    if (prevPaymentsResult is Err) {
      value = DueBillsWidgetError((prevPaymentsResult as Err).failure);
      return;
    }

    final bills = (billsResult as Ok<List<Bill>, Failure>).value;
    final currentPayments =
        (currentPaymentsResult as Ok<List<BillPayment>, Failure>).value;
    final prevPayments =
        (prevPaymentsResult as Ok<List<BillPayment>, Failure>).value;

    final billsMap = {for (var b in bills) b.id: b};
    final dueItems = <DueBillItem>[];

    final today = DateTime.utc(now.year, now.month, now.day);
    final seenPaymentIds = <String>{};

    for (final p in [...prevPayments, ...currentPayments]) {
      if (!seenPaymentIds.add(p.id)) continue;

      final b = billsMap[p.billId];
      if (b != null) {
        final status = _statusPolicy.statusOf(p, now);
        if (status != BillStatus.paid && status != BillStatus.skipped) {
          final dueUtc = DateTime.utc(p.dueOn.year, p.dueOn.month, p.dueOn.day);
          final diffDays = dueUtc.difference(today).inDays;

          String dueLabel;
          if (diffDays < 0) {
            dueLabel = 'Atrasada';
          } else if (diffDays == 0) {
            dueLabel = 'Vence hoje';
          } else if (diffDays == 1) {
            dueLabel = 'Vence amanhã';
          } else if (diffDays <= 7) {
            dueLabel = 'Vence em $diffDays dias';
          } else {
            dueLabel =
                'Vence dia ${p.dueOn.day.toString().padLeft(2, '0')}/${p.dueOn.month.toString().padLeft(2, '0')}';
          }

          dueItems.add(
            DueBillItem(
              bill: b,
              payment: p,
              status: status,
              dueLabel: dueLabel,
            ),
          );
        }
      }
    }

    dueItems.sort((a, b) => a.payment.dueOn.compareTo(b.payment.dueOn));

    value = DueBillsWidgetSuccess(items: dueItems, hideValues: _hideValues);
  }
}
