import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/toggle_shopping_item_usecase.dart';

import 'create_shopping_list_usecase_test.dart';

void main() {
  late FakeShoppingListRepository repository;
  late FakeClock clock;
  late ToggleShoppingItemUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    clock = FakeClock();
    useCase = ToggleShoppingItemUseCase(repository, clock);
  });

  test('CA-1.1: Must mark item as bought with current date', () async {
    final item = ShoppingItem(
      id: 'item-1',
      rawText: 'Arroz',
      parsedName: 'Arroz',
    );
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      createdAt: clock.nowUtc(),
      items: [item],
    );
    await repository.save(list);

    final result = await useCase(
      listId: 'list-1',
      itemId: 'item-1',
      isBought: true,
    );

    expect(result.isOk, isTrue);
    final updatedList = result.valueOrNull!;
    expect(updatedList.items.first.isBought, isTrue);
    expect(updatedList.items.first.boughtAt, clock.nowUtc());
  });

  test('CA-1.2: Must unmark item resetting boughtAt to null', () async {
    final item = ShoppingItem(
      id: 'item-1',
      rawText: 'Arroz',
      parsedName: 'Arroz',
      boughtAt: clock.nowUtc(),
    );
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      createdAt: clock.nowUtc(),
      items: [item],
    );
    await repository.save(list);

    final result = await useCase(
      listId: 'list-1',
      itemId: 'item-1',
      isBought: false,
    );

    expect(result.isOk, isTrue);
    final updatedList = result.valueOrNull!;
    expect(updatedList.items.first.isBought, isFalse);
    expect(updatedList.items.first.boughtAt, isNull);
  });

  test('Should return ValidationFailure if item does not exist', () async {
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      createdAt: clock.nowUtc(),
      items: [],
    );
    await repository.save(list);

    final result = await useCase(
      listId: 'list-1',
      itemId: 'item-missing',
      isBought: true,
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });
}
