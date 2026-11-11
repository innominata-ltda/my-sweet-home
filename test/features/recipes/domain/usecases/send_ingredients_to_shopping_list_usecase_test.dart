import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/usecases/send_ingredients_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

import '../../../shopping/domain/usecases/create_shopping_list_usecase_test.dart';

import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';

void main() {
  late FakeShoppingListRepository repository;
  late FakeIdGenerator idGenerator;
  late SendIngredientsToShoppingListUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    idGenerator = FakeIdGenerator();
    useCase = SendIngredientsToShoppingListUseCase(repository, idGenerator);
  });

  test('should add ingredients to existing shopping list and scale from 2 to 4 servings', () async {
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      createdAt: DateTime.utc(2026, 9, 25),
      items: [
        const ShoppingItem(
          id: 'item-1',
          rawText: '500 g Arroz',
          parsedName: 'Arroz',
          parsedQuantity: Quantity(500000, Unit.g),
          productId: 'prod-1',
        ),
      ],
    );
    await repository.save(list);

    final recipe = Recipe(
      id: 'rec-1',
      title: 'Arroz Doce',
      servings: 2,
      ingredients: [
        const Ingredient(
          name: 'Arroz',
          quantity: Quantity(500000, Unit.g),
          productId: 'prod-1',
        ),
        const Ingredient(name: 'Sal a gosto'),
      ],
      prepText: '',
      timeMinutes: 10,
    );

    // Scaling from 2 to 4 servings (factor = 2)
    final result = await useCase(
      listId: 'list-1',
      recipe: recipe,
      targetServings: 4,
    );

    expect(result.isOk, isTrue);
    final updatedList = result.valueOrNull!;
    expect(updatedList.items, hasLength(2));

    // CA-4.1: 500g na lista + 500g da receita * 2 (fator) = 500g + 1000g = 1500g -> 1.5kg
    final item1 = updatedList.items[0];
    expect(item1.id, 'item-1');
    expect(item1.rawText, '1.5 kg Arroz');
    expect(item1.parsedName, 'Arroz');
    expect(item1.parsedQuantity, const Quantity(1500000, Unit.g));
    expect(item1.productId, 'prod-1');

    final item2 = updatedList.items[1];
    expect(item2.rawText, 'Sal a gosto');
    expect(item2.parsedName, 'Sal a gosto');
    expect(item2.parsedQuantity, isNull);
    expect(item2.productId, isNull);
  });

  test(
    'deve retornar falha de validação se a receita não tiver ingredientes',
    () async {
      final recipe = Recipe(
        id: 'rec-1',
        title: 'Nada',
        servings: 2,
        ingredients: [],
        prepText: '',
        timeMinutes: 0,
      );
      final result = await useCase(
        listId: 'list-1',
        recipe: recipe,
        targetServings: 4,
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    },
  );

  test('should return failure if shopping list does not exist', () async {
    final recipe = Recipe(
      id: 'rec-1',
      title: 'Arroz Doce',
      servings: 2,
      ingredients: [
        const Ingredient(name: 'Arroz', quantity: Quantity(500000, Unit.g)),
      ],
      prepText: '',
      timeMinutes: 0,
    );
    final result = await useCase(
      listId: 'nao-existe',
      recipe: recipe,
      targetServings: 2,
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
