import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final Clock clock;
  FakeExpenseRepository(this.clock);

  final _expenses = <ExpenseId, Expense>{};
  int _nextId = 1;

  final _rules = <String, String>{};

  @override
  Future<Result<Expense, Failure>> add(NewExpense e, {String? rrule}) async {
    final id = ExpenseId('fake_exp_${_nextId++}');
    final now = clock.nowUtc();
    String? ruleId;
    if (rrule != null && rrule.isNotEmpty) {
      ruleId = 'rule_${id.value}';
      _rules[ruleId] = rrule;
    }
    final expense = Expense(
      id: id,
      amount: e.amount,
      occurredOn: e.occurredOn,
      description: e.description,
      notes: e.notes,
      categoryId: e.categoryId,
      billId: e.billId,
      purchaseId: e.purchaseId,
      recurringRuleId: ruleId,
      createdAt: now,
    );
    _expenses[id] = expense;
    return Ok(expense);
  }

  @override
  Future<Result<Expense, Failure>> update(
    ExpenseId id,
    NewExpense e, {
    String? rrule,
  }) async {
    if (!_expenses.containsKey(id)) {
      return Err(NotFoundFailure(what: 'Expense $id not found'));
    }
    final existing = _expenses[id]!;
    var ruleId = existing.recurringRuleId;
    if (rrule != null && rrule.isNotEmpty) {
      ruleId ??= 'rule_${id.value}';
      _rules[ruleId] = rrule;
    }
    final updated = Expense(
      id: id,
      amount: e.amount,
      occurredOn: e.occurredOn,
      description: e.description,
      notes: e.notes,
      categoryId: e.categoryId,
      createdAt: existing.createdAt,
      updatedAt: clock.nowUtc(),
      recurringRuleId: ruleId,
      billId: existing.billId,
      purchaseId: existing.purchaseId,
      deletedAt: existing.deletedAt,
    );
    _expenses[id] = updated;
    return Ok(updated);
  }

  @override
  Future<String?> getRecurringRrule(String ruleId) async => _rules[ruleId];

  @override
  Future<Result<TrashTicket, Failure>> remove(ExpenseId id) async {
    if (!_expenses.containsKey(id)) {
      return Err(NotFoundFailure(what: 'Expense $id not found'));
    }
    final now = clock.nowUtc();
    final ticket = TrashTicket(table: 'expenses', id: id.value, deletedAt: now);
    final existing = _expenses[id]!;
    _expenses[id] = Expense(
      id: existing.id,
      amount: existing.amount,
      occurredOn: existing.occurredOn,
      description: existing.description,
      notes: existing.notes,
      categoryId: existing.categoryId,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      recurringRuleId: existing.recurringRuleId,
      billId: existing.billId,
      purchaseId: existing.purchaseId,
      deletedAt: now,
    );
    return Ok(ticket);
  }

  @override
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  }) async {
    final bounds = m.bounds;
    final results = _expenses.values.where((e) {
      if (e.deletedAt != null) return false;
      if (e.occurredOn.isBefore(bounds.start) ||
          e.occurredOn.isAfter(bounds.end)) {
        return false;
      }
      if (category != null && e.categoryId != category) return false;
      return true;
    }).toList();
    results.sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    return Ok(results);
  }

  @override
  Future<Result<Expense?, Failure>> byId(ExpenseId id) async {
    final expense = _expenses[id];
    if (expense == null || expense.deletedAt != null) return const Ok(null);
    return Ok(expense);
  }
}
