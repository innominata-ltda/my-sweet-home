import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

abstract interface class ShoppingListRepository {
  Future<Result<List<ShoppingList>, Failure>> getAll();

  Future<Result<ShoppingList, Failure>> getById(String id);

  Future<Result<void, Failure>> save(ShoppingList list);
}
