import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/add_shopping_item_usecase.dart';

import 'create_shopping_list_usecase_test.dart'; // To reuse FakeShoppingListRepository and FakeIdGenerator

void main() {
  late FakeShoppingListRepository repository;
  late FakeIdGenerator idGenerator;
  late DefaultShoppingItemParser parser;
  late AddShoppingItemUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    idGenerator = FakeIdGenerator();
    parser = const DefaultShoppingItemParser();
    useCase = AddShoppingItemUseCase(repository, idGenerator, parser);
  });

  test('should add free-text item to existing list', () async {
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      createdAt: DateTime.utc(2026, 9, 25),
    );
    await repository.save(list);

    final result = await useCase(listId: 'list-1', rawText: '  2kg de arroz  ');

    expect(result.isOk, isTrue);
    final updatedList = result.valueOrNull!;
    expect(updatedList.items, hasLength(1));
    final item = updatedList.items.first;
    expect(item.id, 'id-1');
    expect(item.rawText, '2kg de arroz');
    expect(item.parsedName, 'arroz');
    expect(item.parsedQuantity, const Quantity(2000, Unit.kg));

    final saved = await repository.getById('list-1');
    expect(saved.valueOrNull!.items, hasLength(1));
  });

  test('should return validation failure if text is empty', () async {
    final result = await useCase(listId: 'list-1', rawText: '   ');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('should return failure if list does not exist', () async {
    final result = await useCase(listId: 'nao-existe', rawText: 'pão');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
