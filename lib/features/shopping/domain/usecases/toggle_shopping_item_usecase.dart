import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class ToggleShoppingItemUseCase {
  const ToggleShoppingItemUseCase(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<Result<ShoppingList, Failure>> call({
    required String listId,
    required String itemId,
    required bool isBought,
  }) async {
    final listResult = await _repository.getById(listId);
    if (listResult.isErr) return Err(listResult.failureOrNull!);

    final list = listResult.valueOrNull!;

    final itemIndex = list.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return const Err(
        ValidationFailure(fields: {'itemId': 'Item não encontrado na lista.'}),
      );
    }

    final currentItem = list.items[itemIndex];

    if (currentItem.isBought == isBought) {
      return Ok(list);
    }

    final updatedItem = currentItem.copyWith(
      boughtAt: isBought ? _clock.nowUtc() : null,
      clearBoughtAt: !isBought,
    );

    final newItems = List.of(list.items);
    newItems[itemIndex] = updatedItem;

    final updatedList = list.copyWith(items: newItems);

    final saveResult = await _repository.save(updatedList);
    return saveResult.fold((_) => Ok(updatedList), Err.new);
  }
}
