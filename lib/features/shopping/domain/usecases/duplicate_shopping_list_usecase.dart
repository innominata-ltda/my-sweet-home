import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class DuplicateShoppingListUseCase {
  const DuplicateShoppingListUseCase(
    this._repository,
    this._idGenerator,
    this._clock,
  );

  final ShoppingListRepository _repository;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<ShoppingList, Failure>> call(
    String listId, {
    String? newName,
  }) async {
    final result = await _repository.getById(listId);

    return result.fold((list) async {
      final finalName = (newName != null && newName.trim().isNotEmpty)
          ? newName.trim()
          : '${list.name} (Cópia)';

      final newItems = list.items
          .map(
            (item) =>
                item.copyWith(id: _idGenerator.newId(), clearBoughtAt: true),
          )
          .toList();

      final newList = ShoppingList(
        id: _idGenerator.newId(),
        name: finalName,
        createdAt: _clock.nowUtc(),
        storeId: list.storeId,
        items: newItems,
      );

      final saveResult = await _repository.save(newList);
      return saveResult.fold((_) => Ok(newList), Err.new);
    }, Err.new);
  }
}
