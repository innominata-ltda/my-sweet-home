import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/store/store_repository.dart';

class ConvertPurchaseToExpenseUseCase {
  final ExpenseRepository _expenseRepository;
  final StoreRepository _storeRepository;

  ConvertPurchaseToExpenseUseCase(
    this._expenseRepository,
    this._storeRepository,
  );

  Future<Result<Expense, Failure>> call(Purchase purchase) async {
    final storeResult = await _storeRepository.findById(purchase.storeId);
    if (storeResult.isErr) {
      return Err(storeResult.failureOrNull!);
    }
    final store = storeResult.valueOrNull!;

    final newExpense = NewExpense(
      amount: purchase.totalAmount,
      occurredOn: purchase.date,
      description: store.name,
      categoryId: const CategoryId('cat_market'),
      purchaseId: purchase.id,
    );

    return _expenseRepository.add(newExpense);
  }
}
