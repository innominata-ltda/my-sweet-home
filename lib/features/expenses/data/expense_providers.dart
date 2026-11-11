import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_budget_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_category_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return DriftBudgetRepository(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return DriftCategoryRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.all();
  if (result.isOk) {
    return result.valueOrNull!;
  }
  return const [];
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return DriftExpenseRepository(
    db: ref.watch(databaseProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
    trashPolicy: ref.watch(trashPolicyProvider),
  );
});

final monthSummaryRepositoryProvider = Provider<MonthSummaryRepository>((ref) {
  return DriftMonthSummaryRepository(ref.watch(databaseProvider));
});
