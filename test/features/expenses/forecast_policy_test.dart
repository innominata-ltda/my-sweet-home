import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/policies/forecast_policy.dart';

void main() {
  late DefaultForecastPolicy policy;

  setUp(() {
    policy = const DefaultForecastPolicy();
  });

  MonthSummary makeSummary({
    required int monthsOfHistory,
    required Money actual,
    List<CategorySlice> byCategory = const [],
  }) {
    return MonthSummary(
      month: const YearMonth('2026-09'),
      actual: actual,
      byCategory: byCategory,
      monthsOfHistory: monthsOfHistory,
    );
  }

  test('CA-3.2: With fewer than 2 months of history, returns NoBasis', () {
    final summary = makeSummary(monthsOfHistory: 1, actual: const Money(1000));
    final result = policy.project(
      summary: summary,
      pendingRecurring: Money.zero,
      historicAverage: {},
    );

    expect(result, isA<NoBasis>());
    expect((result as NoBasis).monthsOfHistory, 1);
  });

  test('With 2 or more months of history, returns Projected', () {
    final summary = makeSummary(monthsOfHistory: 2, actual: const Money(1000));
    final result = policy.project(
      summary: summary,
      pendingRecurring: Money.zero,
      historicAverage: {},
    );

    expect(result, isA<Projected>());
    expect((result as Projected).monthsOfHistory, 2);
  });

  test('Forecast with only pendingRecurring', () {
    final summary = makeSummary(monthsOfHistory: 3, actual: const Money(5000));
    final result = policy.project(
      summary: summary,
      pendingRecurring: const Money(2000),
      historicAverage: {},
    );

    expect(result, isA<Projected>());
    final projected = result as Projected;
    expect(projected.fromRecurring, const Money(2000));
    expect(projected.fromAverage, Money.zero);
    expect(projected.total, const Money(7000)); // 5000 + 2000
  });

  test('Forecast with historicAverage where actual is less than average', () {
    final catId = const CategoryId('c1');
    final summary = makeSummary(
      monthsOfHistory: 2,
      actual: const Money(1000),
      byCategory: [CategorySlice(categoryId: catId, actual: const Money(1000))],
    );

    final result = policy.project(
      summary: summary,
      pendingRecurring: const Money(500),
      historicAverage: {
        catId: const Money(3000), // Average 3000, current 1000. Remaining 2000.
      },
    );

    expect(result, isA<Projected>());
    final projected = result as Projected;
    expect(projected.fromAverage, const Money(2000));
    expect(projected.fromRecurring, const Money(500));
    expect(
      projected.total,
      const Money(3500),
    ); // 1000 (actual) + 500 (recurring) + 2000 (average)
  });

  test(
    'Forecast with historicAverage where actual is greater than average',
    () {
      final catId = const CategoryId('c1');
      final summary = makeSummary(
        monthsOfHistory: 2,
        actual: const Money(4000),
        byCategory: [
          CategorySlice(categoryId: catId, actual: const Money(4000)),
        ],
      );

      final result = policy.project(
        summary: summary,
        pendingRecurring: Money.zero,
        historicAverage: {
          catId: const Money(
            3000,
          ), // Average 3000, current 4000. Adds nothing to fromAverage.
        },
      );

      expect(result, isA<Projected>());
      final projected = result as Projected;
      expect(projected.fromAverage, Money.zero);
      expect(projected.total, const Money(4000)); // Apenas o atual
    },
  );

  test('Forecast with multiple categories in historicAverage', () {
    final c1 = const CategoryId('c1');
    final c2 = const CategoryId('c2');

    final summary = makeSummary(
      monthsOfHistory: 2,
      actual: const Money(1500),
      byCategory: [
        CategorySlice(categoryId: c1, actual: const Money(1000)),
        CategorySlice(categoryId: c2, actual: const Money(500)),
      ],
    );

    final result = policy.project(
      summary: summary,
      pendingRecurring: const Money(200),
      historicAverage: {
        c1: const Money(800), // Already past (1000 > 800) -> 0
        c2: const Money(2000), // Falta 1500 (2000 - 500)
      },
    );

    expect(result, isA<Projected>());
    final projected = result as Projected;
    expect(projected.fromAverage, const Money(1500));
    expect(
      projected.total,
      const Money(3200),
    ); // 1500 (actual) + 200 (recurring) + 1500 (average)
  });
}
