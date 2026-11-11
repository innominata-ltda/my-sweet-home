import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class SendIngredientsToShoppingListUseCase {
  const SendIngredientsToShoppingListUseCase(
    this._repository,
    this._idGenerator,
  );

  final ShoppingListRepository _repository;
  final IdGenerator _idGenerator;

  Future<Result<ShoppingList, Failure>> call({
    required String listId,
    required Recipe recipe,
    required int targetServings,
  }) async {
    if (recipe.ingredients.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'ingredients': 'A receita não tem ingredientes.'},
        ),
      );
    }
    if (targetServings <= 0) {
      return const Err(
        ValidationFailure(
          fields: {'targetServings': 'Porções devem ser maiores que zero.'},
        ),
      );
    }
    if (recipe.servings <= 0) {
      return const Err(
        ValidationFailure(
          fields: {'recipe': 'Receita deve ter porções maiores que zero.'},
        ),
      );
    }

    final listResult = await _repository.getById(listId);
    if (listResult.isErr) return Err(listResult.failureOrNull!);

    final list = listResult.valueOrNull!;
    final updatedItems = List<ShoppingItem>.from(list.items);
    final double scale = targetServings / recipe.servings;

    for (final ingredient in recipe.ingredients) {
      Quantity? scaledQuantity;
      if (ingredient.quantity != null) {
        scaledQuantity = Quantity(
          (ingredient.quantity!.valueMilli * scale).round(),
          ingredient.quantity!.unit,
        );
      }

      final existingIndex = updatedItems.indexWhere((item) {
        if (ingredient.productId != null &&
            item.productId == ingredient.productId) {
          return true;
        }
        if (ingredient.productId == null &&
            item.productId == null &&
            item.parsedName.toLowerCase() == ingredient.name.toLowerCase()) {
          return true;
        }
        return false;
      });

      if (existingIndex >= 0) {
        final existingItem = updatedItems[existingIndex];

        Quantity? newQuantity;
        if (existingItem.parsedQuantity != null && scaledQuantity != null) {
          try {
            newQuantity = existingItem.parsedQuantity! + scaledQuantity;
          } catch (_) {
            newQuantity = existingItem.parsedQuantity;
          }
        } else if (existingItem.parsedQuantity == null &&
            scaledQuantity != null) {
          newQuantity = scaledQuantity;
        } else {
          newQuantity = existingItem.parsedQuantity;
        }

        final newRawText = _buildRawText(
          Ingredient(
            name: ingredient.name,
            quantity: newQuantity,
            productId: ingredient.productId,
          ),
        );

        updatedItems[existingIndex] = ShoppingItem(
          id: existingItem.id,
          rawText: newRawText,
          parsedName: existingItem.parsedName,
          parsedQuantity: newQuantity,
          productId: existingItem.productId,
          boughtAt: existingItem.boughtAt,
        );
      } else {
        updatedItems.add(
          ShoppingItem(
            id: _idGenerator.newId(),
            rawText: _buildRawText(
              Ingredient(
                name: ingredient.name,
                quantity: scaledQuantity,
                productId: ingredient.productId,
              ),
            ),
            parsedName: ingredient.name,
            parsedQuantity: scaledQuantity,
            productId: ingredient.productId,
          ),
        );
      }
    }

    final updatedList = list.copyWith(items: updatedItems);

    final saveResult = await _repository.save(updatedList);
    return saveResult.fold((_) => Ok(updatedList), Err.new);
  }

  String _buildRawText(Ingredient ingredient) {
    if (ingredient.quantity != null) {
      var q = ingredient.quantity!;
      if (q.unit == Unit.g && q.valueMilli >= 1000000) {
        q = q.convertTo(Unit.kg);
      } else if (q.unit == Unit.ml && q.valueMilli >= 1000000) {
        q = q.convertTo(Unit.l);
      }

      final val = q.displayValue;
      final valStr = val == val.toInt()
          ? val.toInt().toString()
          : val.toString();
      return '$valStr ${q.unit.name} ${ingredient.name}';
    }
    return ingredient.name;
  }
}
