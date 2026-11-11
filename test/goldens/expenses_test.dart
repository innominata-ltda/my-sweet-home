import 'package:flutter/material.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/expenses_screen.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

class FakeMonthSummaryRepository implements MonthSummaryRepository {
  final MonthSummary summary;
  FakeMonthSummaryRepository(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async {
    return Ok(summary);
  }
}

class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses;
  FakeExpenseRepository(this.expenses);

  @override
  Future<Result<Expense, Failure>> add(NewExpense e, {String? rrule}) async =>
      throw UnimplementedError();
  @override
  Future<Result<Expense?, Failure>> byId(ExpenseId id) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  }) async {
    return Ok(expenses);
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(ExpenseId id) async =>
      throw UnimplementedError();
  @override
  Future<Result<Expense, Failure>> update(
    ExpenseId id,
    NewExpense e, {
    String? rrule,
  }) async => throw UnimplementedError();
  @override
  Future<String?> getRecurringRrule(String ruleId) async => null;
}

void main() {
  final testMonth = const YearMonth('2026-09');

  testWidgets('ExpensesScreen golden test (success state)', (tester) async {
    final summary = MonthSummary(
      month: testMonth,
      actual: const Money(15000),
      budget: const Money(30000),
      remaining: const Money(15000),
      byCategory: [
        CategorySlice(
          categoryId: CategoryId('c1'),
          actual: const Money(15000),
          budget: const Money(30000),
          remaining: const Money(15000),
        ),
      ],
      monthsOfHistory: 0,
    );
    final expenses = [
      Expense(
        id: ExpenseId('1'),
        categoryId: CategoryId('c1'),
        amount: const Money(15000),
        occurredOn: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMonthProvider.overrideWithValue(testMonth),
          monthSummaryRepositoryProvider.overrideWithValue(
            FakeMonthSummaryRepository(summary),
          ),
          expenseRepositoryProvider.overrideWithValue(
            FakeExpenseRepository(expenses),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExpensesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ExpensesScreen),
      matchesGoldenFile('expenses_screen_success.png'),
    );
  });

  testWidgets('ExpensesScreen golden test (empty state)', (tester) async {
    final summary = MonthSummary(
      month: testMonth,
      actual: const Money(0),
      budget: null,
      remaining: null,
      byCategory: [],
      monthsOfHistory: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMonthProvider.overrideWithValue(testMonth),
          monthSummaryRepositoryProvider.overrideWithValue(
            FakeMonthSummaryRepository(summary),
          ),
          expenseRepositoryProvider.overrideWithValue(
            FakeExpenseRepository([]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExpensesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ExpensesScreen),
      matchesGoldenFile('expenses_screen_empty.png'),
    );
  });
}
