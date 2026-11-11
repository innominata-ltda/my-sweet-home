import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';

class AddShoppingItemUseCase {
  const AddShoppingItemUseCase(
    this._repository,
    this._idGenerator,
    this._parser,
  );

  final ShoppingListRepository _repository;
  final IdGenerator _idGenerator;
  final ShoppingItemParser _parser;

  Future<Result<ShoppingList, Failure>> call({
    required String listId,
    required String rawText,
    String? productId,
  }) async {
    final trimmedText = rawText.trim();
    if (trimmedText.isEmpty) {
      return const Err(
        ValidationFailure(fields: {'rawText': 'O texto não pode ser vazio.'}),
      );
    }

    final listResult = await _repository.getById(listId);
    if (listResult.isErr) return Err(listResult.failureOrNull!);

    final list = listResult.valueOrNull!;

    final parsed = _parser.parse(trimmedText);

    final newItem = ShoppingItem(
      id: _idGenerator.newId(),
      rawText: trimmedText,
      parsedName: parsed.name,
      parsedQuantity: parsed.quantity,
      productId: productId,
    );

    final updatedList = list.copyWith(items: [...list.items, newItem]);

    final saveResult = await _repository.save(updatedList);
    return saveResult.fold((_) => Ok(updatedList), Err.new);
  }
}
