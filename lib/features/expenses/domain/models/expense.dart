import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

extension type const ExpenseId(String value) {}

class Expense {
  final ExpenseId id;
  final Money amount;
  final DateTime occurredOn;
  final String? description;
  final String? notes;
  final CategoryId? categoryId;
  final String? recurringRuleId;
  final String? billId;
  final String? purchaseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.occurredOn,
    this.description,
    this.notes,
    this.categoryId,
    this.recurringRuleId,
    this.billId,
    this.purchaseId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}

class NewExpense {
  final Money amount;
  final DateTime occurredOn;
  final String? description;
  final String? notes;
  final CategoryId? categoryId;
  final String? billId;
  final String? purchaseId;

  const NewExpense({
    required this.amount,
    required this.occurredOn,
    this.description,
    this.notes,
    this.categoryId,
    this.billId,
    this.purchaseId,
  });
}
