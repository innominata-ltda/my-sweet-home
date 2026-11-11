import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';

class FakeBudgetRepository implements BudgetRepository {
  final Map<String, Budget> _data = {};
  int _nextId = 1;

  @override
  Future<Result<List<Budget>, Failure>> ofMonth(YearMonth m) async {
    final budgets = _data.values.where((b) => b.month.iso == m.iso).toList();
    return Ok(budgets);
  }

  @override
  Future<Result<Budget, Failure>> setLimit(
    YearMonth m,
    CategoryId? category,
    Money limit,
  ) async {
    final existing = _data.values.where((b) {
      return b.month.iso == m.iso && b.category?.value == category?.value;
    }).firstOrNull;

    if (existing != null) {
      final updated = Budget(
        id: existing.id,
        month: m,
        category: category,
        limit: limit,
      );
      _data[existing.id] = updated;
      return Ok(updated);
    } else {
      final id = 'fake_bg_${_nextId++}';
      final newBudget = Budget(
        id: id,
        month: m,
        category: category,
        limit: limit,
      );
      _data[id] = newBudget;
      return Ok(newBudget);
    }
  }

  void seed(Budget budget) {
    _data[budget.id] = budget;
  }
}
