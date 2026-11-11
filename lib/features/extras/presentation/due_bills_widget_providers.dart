import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_controller.dart';

final dueBillsWidgetControllerProvider =
    Provider.family<DueBillsWidgetController, DueBillsWidgetParams>((
      ref,
      params,
    ) {
      final controller = DueBillsWidgetController(
        billRepository: params.billRepository,
        paymentRepository: params.paymentRepository,
        statusPolicy: params.statusPolicy,
        clock: params.clock ?? ref.watch(clockProvider),
        hideValues: params.hideValues,
      );

      try {
        final db = ref.watch(databaseProvider);
        final sub1 = db
            .select(db.bills)
            .watch()
            .listen((_) => controller.load());
        final sub2 = db
            .select(db.billPayments)
            .watch()
            .listen((_) => controller.load());
        ref.onDispose(() {
          sub1.cancel();
          sub2.cancel();
        });
      } catch (_) {}

      ref.onDispose(controller.dispose);
      return controller;
    });

class DueBillsWidgetParams {
  final BillRepository billRepository;
  final BillPaymentRepository paymentRepository;
  final BillStatusPolicy? statusPolicy;
  final Clock? clock;
  final bool hideValues;

  const DueBillsWidgetParams({
    required this.billRepository,
    required this.paymentRepository,
    this.statusPolicy,
    this.clock,
    this.hideValues = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DueBillsWidgetParams &&
          runtimeType == other.runtimeType &&
          billRepository == other.billRepository &&
          paymentRepository == other.paymentRepository &&
          statusPolicy == other.statusPolicy &&
          clock == other.clock &&
          hideValues == other.hideValues;

  @override
  int get hashCode =>
      billRepository.hashCode ^
      paymentRepository.hashCode ^
      statusPolicy.hashCode ^
      clock.hashCode ^
      hideValues.hashCode;
}
