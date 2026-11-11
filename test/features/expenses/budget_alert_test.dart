import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/policies/budget_alert_policy.dart';

void main() {
  group('DefaultBudgetAlertPolicy', () {
    const policy = DefaultBudgetAlertPolicy();
    final month = YearMonth('2026-03');
    const cat1 = CategoryId('c1');

    test('sem orcamento definido -> null', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(10000),
        budget: null,
        byCategory: [
          const CategorySlice(
            categoryId: cat1,
            actual: Money(10000),
            budget: null,
          ),
        ],
        monthsOfHistory: 3,
      );

      final resultGlobal = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {},
      );
      expect(resultGlobal, isNull);

      final resultCat = policy.evaluate(
        summary: summary,
        category: cat1,
        alreadyFiredThresholds: {},
      );
      expect(resultCat, isNull);
    });

    test('abaixo de 80% -> null', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(7900),
        budget: const Money(10000),
        byCategory: [
          const CategorySlice(
            categoryId: cat1,
            actual: Money(7900),
            budget: Money(10000),
          ),
        ],
        monthsOfHistory: 3,
      );

      final result = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {},
      );
      expect(result, isNull);
    });

    test('crosses 80% once; second entry does not re-trigger (CA-4.1)', () {
      // First entry reaching 80%
      final summary1 = MonthSummary(
        month: month,
        actual: const Money(8000),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result1 = policy.evaluate(
        summary: summary1,
        category: null,
        alreadyFiredThresholds: {},
      );
      expect(
        result1,
        equals(const BudgetAlert(threshold: 80, categoryId: null)),
      );

      // Second entry reaching 85% (already triggered 80%)
      final summary2 = MonthSummary(
        month: month,
        actual: const Money(8500),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result2 = policy.evaluate(
        summary: summary2,
        category: null,
        alreadyFiredThresholds: {80},
      );
      expect(result2, isNull);
    });

    test('crosses 100%; if 80 already triggered, triggers 100', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(10000),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {80},
      );
      expect(
        result,
        equals(const BudgetAlert(threshold: 100, categoryId: null)),
      );
    });

    test('cruza 100%; se nem 80 tinha disparado, dispara 100 (pula 80)', () {
      // Exemplo: compra grande que gasta tudo de uma vez
      final summary = MonthSummary(
        month: month,
        actual: const Money(11000),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {},
      );
      expect(
        result,
        equals(const BudgetAlert(threshold: 100, categoryId: null)),
      );
    });

    test('crosses 100%; second entry post-100 does not re-trigger', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(12000),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {80, 100},
      );
      expect(result, isNull);
    });

    test('specific category crosses 80%', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(5000), // global 50%
        budget: const Money(10000),
        byCategory: [
          const CategorySlice(
            categoryId: cat1,
            actual: Money(800),
            budget: Money(1000),
          ),
        ],
        monthsOfHistory: 3,
      );

      final resultGlobal = policy.evaluate(
        summary: summary,
        category: null,
        alreadyFiredThresholds: {},
      );
      expect(resultGlobal, isNull);

      final resultCat = policy.evaluate(
        summary: summary,
        category: cat1,
        alreadyFiredThresholds: {},
      );
      expect(
        resultCat,
        equals(const BudgetAlert(threshold: 80, categoryId: cat1)),
      );
    });

    test('category not found in summary -> null', () {
      final summary = MonthSummary(
        month: month,
        actual: const Money(10000),
        budget: const Money(10000),
        byCategory: [],
        monthsOfHistory: 3,
      );

      final result = policy.evaluate(
        summary: summary,
        category: const CategoryId('nao-existe'),
        alreadyFiredThresholds: {},
      );
      expect(result, isNull);
    });
  });
}
