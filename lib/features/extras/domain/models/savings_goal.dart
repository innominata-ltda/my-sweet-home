import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

/// Domain model for Month's Savings Goal.
class SavingsGoal {
  final YearMonth month;
  final Money target;

  const SavingsGoal({required this.month, required this.target});

  SavingsGoal copyWith({YearMonth? month, Money? target}) {
    return SavingsGoal(
      month: month ?? this.month,
      target: target ?? this.target,
    );
  }
}
