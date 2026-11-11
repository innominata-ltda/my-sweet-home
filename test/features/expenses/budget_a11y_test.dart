import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/budget_screen.dart';

class _FakeBudgetRepo implements BudgetRepository {
  List<Budget> budgets = [];

  @override
  Future<Result<List<Budget>, Failure>> ofMonth(YearMonth ym) async {
    return Ok(budgets.where((b) => b.month == ym).toList());
  }

  @override
  Future<Result<Budget, Failure>> setLimit(
    YearMonth m,
    CategoryId? category,
    Money limit,
  ) async {
    final b = Budget(
      id: 'b_${m.iso}',
      month: m,
      category: category,
      limit: limit,
    );
    budgets.removeWhere((item) => item.month == m && item.category == category);
    budgets.add(b);
    return Ok(b);
  }
}

class _FakeCatRepo implements CategoryRepository {
  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async {
    return const Ok([]);
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
  testWidgets(
    'T-B19: Botões de voltar e navegação de mês em Orçamento possuem tooltip e acessibilidade pt-BR',
    (tester) async {
      final fakeBudgetRepo = _FakeBudgetRepo();
      final fakeCatRepo = _FakeCatRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetRepositoryProvider.overrideWithValue(fakeBudgetRepo),
            categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BudgetScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Back button
      expect(find.byTooltip('Voltar'), findsOneWidget);
      expect(find.bySemanticsLabel('Voltar'), findsOneWidget);

      // 2. Previous month
      expect(find.byTooltip('Mês anterior'), findsOneWidget);
      expect(find.bySemanticsLabel('Mês anterior'), findsOneWidget);

      // 3. Next month
      expect(find.byTooltip('Próximo mês'), findsOneWidget);
      expect(find.bySemanticsLabel('Próximo mês'), findsOneWidget);
    },
  );
}
