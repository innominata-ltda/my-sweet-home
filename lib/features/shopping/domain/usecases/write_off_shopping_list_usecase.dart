import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class WriteOffShoppingListUseCase {
  const WriteOffShoppingListUseCase(this._repository);

  final ShoppingListRepository _repository;

  Future<Result<ShoppingList, Failure>> call({
    required String listId,
    required Purchase purchase,
  }) async {
    final listResult = await _repository.getById(listId);
    if (listResult.isErr) return Err(listResult.failureOrNull!);

    final list = listResult.valueOrNull!;

    // Obtains IDs of products present in purchase
    final purchaseProductIds = purchase.items.map((i) => i.productId).toSet();

    bool changed = false;
    final newItems = list.items.map((item) {
      if (!item.isBought &&
          item.productId != null &&
          purchaseProductIds.contains(item.productId)) {
        changed = true;
        return item.copyWith(boughtAt: purchase.date);
      }
      return item;
    }).toList();

    if (!changed) {
      return Ok(list);
    }

    final updatedList = list.copyWith(items: newItems);

    final saveResult = await _repository.save(updatedList);
    return saveResult.fold((_) => Ok(updatedList), Err.new);
  }
}
