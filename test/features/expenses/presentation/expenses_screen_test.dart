import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/expenses_screen.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  final MonthSummary summary;
  _FakeMonthSummaryRepo(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async {
    return Ok(summary);
  }
}

class _FakeExpenseRepo implements ExpenseRepository {
  final List<Expense> expenses;
  _FakeExpenseRepo(this.expenses);

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
  }) async => Ok(expenses);

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

class _FakeCategoryRepo implements CategoryRepository {
  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async {
    return const Ok([
      Category(
        id: CategoryId('cat-1'),
        name: 'Mercado',
        kind: CategoryKind.expense,
        iconKey: 'cart',
        colorHex: '#00FF00',
        isSystem: true,
      ),
      Category(
        id: CategoryId('cat-2'),
        name: 'Lazer',
        kind: CategoryKind.expense,
        iconKey: 'entertainment',
        colorHex: '#0000FF',
        isSystem: true,
      ),
    ]);
  }

  @override
  Future<Result<Category, Failure>> upsert(Category c) async => Ok(c);

  @override
  Future<Result<void, Failure>> deactivate(CategoryId id) async =>
      const Ok(null);

  @override
  Future<Result<int, Failure>> ensureDefaults() async => const Ok(0);
}

void main() {
  const testMonth = YearMonth('2026-10');

  testWidgets('ExpensesScreen unifies scroll in a single CustomScrollView', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final summary = MonthSummary(
      month: testMonth,
      actual: const Money(25000),
      budget: const Money(50000),
      remaining: const Money(25000),
      byCategory: const [
        CategorySlice(
          categoryId: CategoryId('cat-1'),
          actual: Money(15000),
          budget: Money(30000),
          remaining: Money(15000),
        ),
        CategorySlice(
          categoryId: CategoryId('cat-2'),
          actual: Money(10000),
          budget: Money(20000),
          remaining: Money(10000),
        ),
      ],
      monthsOfHistory: 3,
    );

    final expenses = [
      Expense(
        id: const ExpenseId('e1'),
        categoryId: const CategoryId('cat-1'),
        amount: const Money(15000),
        occurredOn: DateTime(2026, 10, 10),
        createdAt: DateTime(2026, 10, 10),
        description: 'Supermercado',
      ),
      Expense(
        id: const ExpenseId('e2'),
        categoryId: const CategoryId('cat-2'),
        amount: const Money(10000),
        occurredOn: DateTime(2026, 10, 12),
        createdAt: DateTime(2026, 10, 12),
        description: 'Cinema',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMonthProvider.overrideWithValue(testMonth),
          monthSummaryRepositoryProvider.overrideWithValue(
            _FakeMonthSummaryRepo(summary),
          ),
          expenseRepositoryProvider.overrideWithValue(
            _FakeExpenseRepo(expenses),
          ),
          categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExpensesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify unified scroll view
    expect(find.byType(CustomScrollView), findsOneWidget);

    // Expand categories and verify no overflow occurs
    final expansionTile = find.byType(ExpansionTile);
    expect(expansionTile, findsOneWidget);
    await tester.tap(expansionTile);
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsWidgets);
    expect(find.text('Cinema — R\$ 100,00'), findsOneWidget);

    // No exception / overflow logged
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Permite definir orcamento mesmo sem nenhuma despesa cadastrada',
    (tester) async {
      final emptySummary = MonthSummary(
        month: testMonth,
        actual: Money.zero,
        budget: null,
        remaining: null,
        byCategory: const [],
        monthsOfHistory: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentMonthProvider.overrideWithValue(testMonth),
            monthSummaryRepositoryProvider.overrideWithValue(
              _FakeMonthSummaryRepo(emptySummary),
            ),
            expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepo([])),
            categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify budget button is in AppBar
      expect(find.byTooltip('Orçamento do mês'), findsOneWidget);

      // Verifica que no empty state ha a opcao de definir orcamento alem de lancar despesa
      expect(find.text('definir orçamento'), findsOneWidget);
      expect(find.text('lançar despesa'), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard displays budget correctly even with 0 expenses when already defined',
    (tester) async {
      const definedBudget = Money(200000); // R$ 2.000,00
      final summaryWithBudgetOnly = MonthSummary(
        month: testMonth,
        actual: Money.zero,
        budget: definedBudget,
        remaining: definedBudget,
        byCategory: const [],
        monthsOfHistory: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentMonthProvider.overrideWithValue(testMonth),
            monthSummaryRepositoryProvider.overrideWithValue(
              _FakeMonthSummaryRepo(summaryWithBudgetOnly),
            ),
            expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepo([])),
            categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ExpensesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Deve exibir o card de orcamento normalmente
      expect(find.text('Orçamento: R\$ 2.000,00'), findsOneWidget);
      expect(find.text('Realizado: R\$ 0,00'), findsOneWidget);
      expect(find.text('Restante: R\$ 2.000,00'), findsOneWidget);
      expect(find.byTooltip('Editar Orçamento'), findsOneWidget);
    },
  );
}
