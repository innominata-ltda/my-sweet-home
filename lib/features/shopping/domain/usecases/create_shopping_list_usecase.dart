import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class CreateShoppingListUseCase {
  const CreateShoppingListUseCase(
    this._repository,
    this._idGenerator,
    this._clock,
  );

  final ShoppingListRepository _repository;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<ShoppingList, Failure>> call(
    String name, {
    String? storeId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'name': 'O nome da lista não pode ser vazio.'},
        ),
      );
    }

    final list = ShoppingList(
      id: _idGenerator.newId(),
      name: trimmedName,
      createdAt: _clock.nowUtc(),
      storeId: storeId,
    );

    final result = await _repository.save(list);
    return result.fold((_) => Ok(list), Err.new);
  }
}
