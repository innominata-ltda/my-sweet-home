import 'dart:convert';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class ImportShoppingListUseCase {
  const ImportShoppingListUseCase(this._repository);

  final ShoppingListRepository _repository;

  Future<Result<ShoppingList, Failure>> call(String jsonString) async {
    ShoppingList list;
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      list = ShoppingList.fromJson(jsonMap);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao importar lista', cause: e));
    }

    final result = await _repository.save(list);
    return result.fold((_) => Ok(list), Err.new);
  }
}
