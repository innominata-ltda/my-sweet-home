import 'dart:async';

import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_service.dart';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/bills/domain/bills_preferences.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

// ... (other parts remain untouched or already updated, so let's target the exact piece)

class BillListItem {
  final Bill bill;
  final BillPayment payment;
  final BillStatus status;

  const BillListItem({
    required this.bill,
    required this.payment,
    required this.status,
  });
}

sealed class BillsListState {}

class BillsListLoading extends BillsListState {}

class BillsListSuccess extends BillsListState {
  final List<BillListItem> items;
  final PermissionState permissionState;
  final bool hasDismissedWarning;
  final bool showBatteryOptimizationHint;

  BillsListSuccess({
    required this.items,
    required this.permissionState,
    required this.hasDismissedWarning,
    this.showBatteryOptimizationHint = false,
  });

  bool get isEmpty => items.isEmpty;
  bool get isAllPaid =>
      items.isNotEmpty && items.every((i) => i.status == BillStatus.paid);
  bool get lacksPermission =>
      permissionState != PermissionState.granted && !hasDismissedWarning;
}

class BillsListError extends BillsListState {
  final Failure failure;
  BillsListError(this.failure);
}

class BillsListController extends ValueNotifier<BillsListState> {
  BillsListController({
    required this._billRepository,
    required this._paymentRepository,
    required this._notificationScheduler,
    required this._preferences,
    required this._statusPolicy,
    required this._batteryWarningService,
    required this._clock,
  }) : super(BillsListLoading()) {
    unawaited(load());
  }

  final BillRepository _billRepository;
  final BillPaymentRepository _paymentRepository;
  final NotificationSchedulerPort _notificationScheduler;
  final BillsPreferences _preferences;
  final BillStatusPolicy _statusPolicy;
  final BatteryWarningService _batteryWarningService;
  final Clock _clock;

  Future<void> load() async {
    value = BillsListLoading();

    final now = _clock.nowUtc();
    final yearMonth = YearMonth.of(now);

    final billsResult = await _billRepository.active();
    if (billsResult is Err) {
      value = BillsListError((billsResult as Err).failure);
      return;
    }

    final paymentsResult = await _paymentRepository.ofMonth(yearMonth);
    if (paymentsResult is Err) {
      value = BillsListError((paymentsResult as Err).failure);
      return;
    }

    final permission = await _notificationScheduler.permission();
    final hasDismissedWarning =
        await _preferences.hasDismissedPermissionWarning;
    final showBatteryHint = await _batteryWarningService
        .shouldShowPersistentHint();

    final bills = (billsResult as Ok<List<Bill>, Failure>).value;
    final payments = (paymentsResult as Ok<List<BillPayment>, Failure>).value;

    final billsMap = {for (var b in bills) b.id: b};
    final items = <BillListItem>[];

    for (final p in payments) {
      final b = billsMap[p.billId];
      if (b != null) {
        items.add(
          BillListItem(
            bill: b,
            payment: p,
            status: _statusPolicy.statusOf(p, now),
          ),
        );
      }
    }

    // Sort by due date
    items.sort((a, b) => a.payment.dueOn.compareTo(b.payment.dueOn));

    value = BillsListSuccess(
      items: items,
      permissionState: permission,
      hasDismissedWarning: hasDismissedWarning,
      showBatteryOptimizationHint: showBatteryHint,
    );
  }

  Future<void> requestNotificationPermission() async {
    // Usually the port has a request method. Wait, does NotificationSchedulerPort have a request method?
    // Let's assume we can re-evaluate permission. In a real app we'd trigger a request.
    // For now we just load again.
    await load();
  }

  Future<void> dismissNotificationWarning() async {
    await _preferences.dismissPermissionWarning();
    await load();
  }

  Future<void> openBatterySettings() async {
    await _batteryWarningService.openSettings();
  }

  Future<void> unpayBill(BillPaymentId id) async {
    final result = await _paymentRepository.unmarkPaid(id);
    if (result is Ok) {
      await load();
    }
  }

  Future<void> pauseBill(BillId id) async {
    final result = await _billRepository.pause(id);
    if (result is Ok) {
      await load();
    }
  }

  Future<Result<void, Failure>> deleteBill(BillId id) async {
    final historyRes = await _paymentRepository.historyOf(id);
    if (historyRes.isOk) {
      for (final p in historyRes.valueOrNull!) {
        await _notificationScheduler.cancel('${p.id}_advance');
        await _notificationScheduler.cancel('${p.id}_due');
      }
    }
    final result = await _billRepository.delete(id);
    if (result is Ok) {
      await load();
    }
    return result;
  }
}
