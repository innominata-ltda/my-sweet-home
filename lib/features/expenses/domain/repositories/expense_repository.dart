import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

abstract interface class ExpenseRepository {
  Future<Result<Expense, Failure>> add(NewExpense e, {String? rrule});
  Future<Result<Expense, Failure>> update(
    ExpenseId id,
    NewExpense e, {
    String? rrule,
  });
  Future<Result<TrashTicket, Failure>> remove(ExpenseId id);
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  });
  Future<Result<Expense?, Failure>> byId(ExpenseId id);
  Future<String?> getRecurringRrule(String ruleId);
}
