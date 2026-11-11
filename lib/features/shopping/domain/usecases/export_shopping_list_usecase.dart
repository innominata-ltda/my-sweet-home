import 'dart:convert';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

class ExportShoppingListUseCase {
  const ExportShoppingListUseCase();

  Result<String, Failure> call(ShoppingList list) {
    try {
      final jsonString = jsonEncode(list.toJson());
      return Ok(jsonString);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao exportar lista', cause: e));
    }
  }
}
