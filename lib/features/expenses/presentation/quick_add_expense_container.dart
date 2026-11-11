import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_screen.dart';

class QuickAddExpenseContainer extends ConsumerWidget {
  final Expense? initialExpense;
  final DateTime? initialDate;
  final bool initialRecurring;

  const QuickAddExpenseContainer({
    super.key,
    this.initialExpense,
    this.initialDate,
    this.initialRecurring = false,
  });

  static final List<Category> defaultCategories = [
    const Category(
      id: CategoryId('cat_food'),
      name: 'Alimentação',
      kind: CategoryKind.expense,
      iconKey: 'shopping_cart',
      isSystem: true,
    ),
    const Category(
      id: CategoryId('cat_housing'),
      name: 'Moradia',
      kind: CategoryKind.expense,
      iconKey: 'home',
      isSystem: true,
    ),
    const Category(
      id: CategoryId('cat_transport'),
      name: 'Transporte',
      kind: CategoryKind.expense,
      iconKey: 'directions_car',
      isSystem: true,
    ),
    const Category(
      id: CategoryId('cat_entertainment'),
      name: 'Lazer',
      kind: CategoryKind.expense,
      iconKey: 'sports_esports',
      isSystem: true,
    ),
    const Category(
      id: CategoryId('cat_other'),
      name: 'Outros',
      kind: CategoryKind.expense,
      iconKey: 'category',
      isSystem: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    return QuickAddExpenseScreen(
      repository: ref.watch(expenseRepositoryProvider),
      clock: ref.watch(clockProvider),
      categories: categories.isNotEmpty ? categories : defaultCategories,
      initialExpense: initialExpense,
      initialDate: initialDate,
      initialRecurring: initialRecurring,
    );
  }
}
