import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';

sealed class Forecast {
  const Forecast();
}

final class NoBasis extends Forecast {
  final int monthsOfHistory;

  const NoBasis({required this.monthsOfHistory});
}

final class Projected extends Forecast {
  final Money total;
  final int monthsOfHistory;
  final Money fromRecurring;
  final Money fromAverage;

  const Projected({
    required this.total,
    required this.monthsOfHistory,
    required this.fromRecurring,
    required this.fromAverage,
  });
}

abstract interface class ForecastPolicy {
  Forecast project({
    required MonthSummary summary,
    required Money pendingRecurring,
    required Map<CategoryId, Money> historicAverage,
  });
}

class DefaultForecastPolicy implements ForecastPolicy {
  const DefaultForecastPolicy();

  @override
  Forecast project({
    required MonthSummary summary,
    required Money pendingRecurring,
    required Map<CategoryId, Money> historicAverage,
  }) {
    if (summary.monthsOfHistory < 2) {
      return NoBasis(monthsOfHistory: summary.monthsOfHistory);
    }

    Money fromAverage = Money.zero;

    // Calculates remaining to reach historical average for each category.
    // Categories not in historicAverage do not contribute to fromAverage.
    for (final entry in historicAverage.entries) {
      final categoryId = entry.key;
      final average = entry.value;

      // Finds actual spending of this category in summary
      final slice = summary.byCategory
          .where((s) => s.categoryId == categoryId)
          .firstOrNull;
      final actualForCategory = slice?.actual ?? Money.zero;

      if (actualForCategory < average) {
        fromAverage += (average - actualForCategory);
      }
    }

    final total = summary.actual + pendingRecurring + fromAverage;

    return Projected(
      total: total,
      monthsOfHistory: summary.monthsOfHistory,
      fromRecurring: pendingRecurring,
      fromAverage: fromAverage,
    );
  }
}
