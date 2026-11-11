import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_controller.dart';

final monthBalanceWidgetControllerProvider =
    Provider.family<MonthBalanceWidgetController, MonthBalanceWidgetParams>((
      ref,
      params,
    ) {
      final controller = MonthBalanceWidgetController(
        monthSummaryRepository: params.monthSummaryRepository,
        clock: params.clock ?? ref.watch(clockProvider),
        hideValues: params.hideValues,
      );

      try {
        final db = ref.watch(databaseProvider);
        final sub1 = db
            .select(db.expenses)
            .watch()
            .listen((_) => controller.load());
        final sub2 = db
            .select(db.budgets)
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

class MonthBalanceWidgetParams {
  final MonthSummaryRepository monthSummaryRepository;
  final Clock? clock;
  final bool hideValues;

  const MonthBalanceWidgetParams({
    required this.monthSummaryRepository,
    this.clock,
    this.hideValues = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthBalanceWidgetParams &&
          runtimeType == other.runtimeType &&
          monthSummaryRepository == other.monthSummaryRepository &&
          clock == other.clock &&
          hideValues == other.hideValues;

  @override
  int get hashCode =>
      monthSummaryRepository.hashCode ^ clock.hashCode ^ hideValues.hashCode;
}
