import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class ConvertChecklistToShoppingListUseCase {
  const ConvertChecklistToShoppingListUseCase({
    required this._shoppingListRepository,
    required this._idGenerator,
    required this._clock,
  });

  final ShoppingListRepository _shoppingListRepository;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<ShoppingList, Failure>> call({
    required List<ChecklistItem> items,
    String? listName,
    String? targetListId,
  }) async {
    final unmarkedItems = items.where((i) => !i.isMarked).toList();
    if (unmarkedItems.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {
            'items': 'Não há itens pendentes no checklist para enviar à lista de compras.',
          },
        ),
      );
    }

    if (targetListId != null && targetListId.isNotEmpty) {
      final existingResult = await _shoppingListRepository.getById(
        targetListId,
      );
      if (existingResult.isErr) {
        return Err(existingResult.failureOrNull!);
      }
      final existingList = existingResult.valueOrNull!;
      final currentItems = List<ShoppingItem>.from(existingList.items);

      for (final item in unmarkedItems) {
        final exists = currentItems.any(
          (ci) =>
              ci.parsedName.trim().toLowerCase() ==
              item.title.trim().toLowerCase(),
        );
        if (!exists) {
          currentItems.add(
            ShoppingItem(
              id: _idGenerator.newId(),
              rawText: item.title,
              parsedName: item.title,
            ),
          );
        }
      }

      final updatedList = existingList.copyWith(items: currentItems);
      final saveResult = await _shoppingListRepository.save(updatedList);
      return saveResult.fold((_) => Ok(updatedList), Err.new);
    } else {
      final name = (listName != null && listName.trim().isNotEmpty)
          ? listName.trim()
          : 'Lista da Casa (Checklist)';

      final shoppingItems = unmarkedItems.map((item) {
        return ShoppingItem(
          id: _idGenerator.newId(),
          rawText: item.title,
          parsedName: item.title,
        );
      }).toList();

      final newList = ShoppingList(
        id: _idGenerator.newId(),
        name: name,
        createdAt: _clock.nowUtc(),
        items: shoppingItems,
      );

      final saveResult = await _shoppingListRepository.save(newList);
      return saveResult.fold((_) => Ok(newList), Err.new);
    }
  }
}
