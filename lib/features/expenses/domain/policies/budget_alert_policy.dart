import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';

/// Triggered budget alert.
final class BudgetAlert {
  /// Limiar que foi ultrapassado (80 ou 100).
  final int threshold;

  /// Category that triggered alert. If null, alert applies to global budget.
  final CategoryId? categoryId;

  const BudgetAlert({required this.threshold, this.categoryId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAlert &&
          runtimeType == other.runtimeType &&
          threshold == other.threshold &&
          categoryId == other.categoryId;

  @override
  int get hashCode => threshold.hashCode ^ categoryId.hashCode;
}

/// PURE. Decides whether to alert and which threshold, knowing what was already alerted (RN-110).
abstract interface class BudgetAlertPolicy {
  BudgetAlert? evaluate({
    required MonthSummary summary,
    required CategoryId? category,
    required Set<int> alreadyFiredThresholds, // {80, 100}
  });
}

final class DefaultBudgetAlertPolicy implements BudgetAlertPolicy {
  const DefaultBudgetAlertPolicy();

  @override
  BudgetAlert? evaluate({
    required MonthSummary summary,
    required CategoryId? category,
    required Set<int> alreadyFiredThresholds,
  }) {
    Money actual;
    Money? budget;

    if (category == null) {
      actual = summary.actual;
      budget = summary.budget;
    } else {
      final slice = summary.byCategory
          .where((s) => s.categoryId == category)
          .firstOrNull;
      if (slice == null) return null;
      actual = slice.actual;
      budget = slice.budget;
    }

    if (budget == null || budget.cents == 0) return null;

    final percentage = (actual.cents * 100) ~/ budget.cents;

    if (percentage >= 100 && !alreadyFiredThresholds.contains(100)) {
      return BudgetAlert(threshold: 100, categoryId: category);
    }

    if (percentage >= 80 &&
        !alreadyFiredThresholds.contains(80) &&
        !alreadyFiredThresholds.contains(100)) {
      return BudgetAlert(threshold: 80, categoryId: category);
    }

    return null;
  }
}
