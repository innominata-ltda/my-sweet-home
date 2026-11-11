import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/dashboard_provider.dart';

part 'expense_list_provider.g.dart';

@riverpod
class ExpenseList extends _$ExpenseList {
  @override
  Future<List<Expense>> build(YearMonth month) async {
    final repo = ref.watch(expenseRepositoryProvider);
    final result = await repo.ofMonth(month);

    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw Exception(userMessageFor(failure)),
    };
  }

  Future<TrashTicket?> removeExpense(ExpenseId id) async {
    final repo = ref.read(expenseRepositoryProvider);
    final result = await repo.remove(id);
    if (result case Ok(:final value)) {
      ref.invalidateSelf();
      ref.invalidate(dashboardSummaryProvider(month));
      return value;
    }
    return null;
  }

  Future<void> undoRemoveExpense(TrashTicket ticket) async {
    final trashPolicy = ref.read(trashPolicyProvider);
    final result = await trashPolicy.restore(ticket);
    if (result case Ok()) {
      ref.invalidateSelf();
      ref.invalidate(dashboardSummaryProvider(month));
    }
  }
}
