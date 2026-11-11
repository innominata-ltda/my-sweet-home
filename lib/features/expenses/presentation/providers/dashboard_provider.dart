import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';

part 'dashboard_provider.g.dart';

@riverpod
class DashboardSummary extends _$DashboardSummary {
  @override
  Future<MonthSummary?> build(YearMonth month) async {
    final repo = ref.watch(monthSummaryRepositoryProvider);
    final result = await repo.summarize(month);

    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw Exception(userMessageFor(failure)),
    };
  }
}
