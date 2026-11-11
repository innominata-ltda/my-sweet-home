import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';

abstract interface class SavingsGoalRepository {
  Future<Result<SavingsGoal?, Failure>> getGoal(YearMonth month);
  Future<Result<SavingsGoal, Failure>> setGoal(YearMonth month, Money target);
}
