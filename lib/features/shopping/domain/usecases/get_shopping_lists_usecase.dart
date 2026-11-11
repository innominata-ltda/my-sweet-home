import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class GetShoppingListsUseCase {
  const GetShoppingListsUseCase(this._repository);

  final ShoppingListRepository _repository;

  Future<Result<List<ShoppingList>, Failure>> call() {
    return _repository.getAll();
  }
}
