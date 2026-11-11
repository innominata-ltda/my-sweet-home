import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/savings_goal_repository.dart';

class FakeSavingsGoalRepository implements SavingsGoalRepository {
  final Map<String, SavingsGoal> _goals = {};

  @override
  Future<Result<SavingsGoal?, Failure>> getGoal(YearMonth month) async {
    return Ok(_goals[month.iso]);
  }

  @override
  Future<Result<SavingsGoal, Failure>> setGoal(
    YearMonth month,
    Money target,
  ) async {
    final goal = SavingsGoal(month: month, target: target);
    _goals[month.iso] = goal;
    return Ok(goal);
  }
}
