import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class ArchiveShoppingListUseCase {
  const ArchiveShoppingListUseCase(this._repository);

  final ShoppingListRepository _repository;

  Future<Result<void, Failure>> call(String listId) async {
    final result = await _repository.getById(listId);
    return result.fold((list) async {
      if (list.isArchived) return const Ok(null);
      return _repository.save(list.copyWith(isArchived: true));
    }, (f) async => Err(f));
  }
}
