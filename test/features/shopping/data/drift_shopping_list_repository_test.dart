import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide ShoppingList, ShoppingItem;
import 'package:my_sweet_home/features/shopping/data/drift_shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';

import '../../../fakes/fake_clock.dart';

void main() {
  late AppDatabase database;
  late DefaultShoppingItemParser parser;
  late FakeClock clock;
  late DriftShoppingListRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    parser = const DefaultShoppingItemParser();
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    repository = DriftShoppingListRepository(database, parser, clock);
  });

  tearDown(() async {
    await database.close();
  });

  test('must save and retrieve an empty list', () async {
    final list = ShoppingList(
      id: 'list-1',
      name: 'Minha Lista',
      createdAt: DateTime.utc(2026, 10, 1),
    );

    final saveResult = await repository.save(list);
    expect(saveResult.isOk, isTrue);

    final getResult = await repository.getById('list-1');
    expect(getResult.isOk, isTrue);
    expect(getResult.valueOrNull, list);
  });

  test('must return error for non-existent list', () async {
    final getResult = await repository.getById('nao-existe');
    expect(getResult.isErr, isTrue);
  });

  test('must save and retrieve list with items', () async {
    final list = ShoppingList(
      id: 'list-2',
      name: 'Supermercado',
      createdAt: DateTime.utc(2026, 10, 2),
      items: [
        ShoppingItem(
          id: 'item-1',
          rawText: '2kg de arroz',
          parsedName: 'arroz',
          parsedQuantity: const Quantity(2000, Unit.kg),
        ),
        ShoppingItem(
          id: 'item-2',
          rawText: 'feijão',
          parsedName: 'feijão',
          boughtAt: DateTime.utc(2026, 10, 2, 10),
        ),
      ],
    );

    await repository.save(list);

    final getResult = await repository.getById('list-2');
    expect(getResult.isOk, isTrue);
    final loaded = getResult.valueOrNull!;
    expect(loaded.items, hasLength(2));

    // Detailed checks of item 1
    final item1 = loaded.items[0];
    expect(item1.id, 'item-1');
    expect(item1.rawText, '2kg de arroz');
    expect(item1.parsedName, 'arroz');
    expect(item1.parsedQuantity, const Quantity(2000, Unit.kg));
    expect(item1.isBought, isFalse);

    // Detailed checks of item 2
    final item2 = loaded.items[1];
    expect(item2.id, 'item-2');
    expect(item2.rawText, 'feijão');
    expect(item2.parsedName, 'feijão');
    expect(item2.parsedQuantity, isNull);
    expect(item2.isBought, isTrue);
    expect(item2.boughtAt, DateTime.utc(2026, 10, 2, 10));

    // Testa igualdade profunda
    expect(loaded, list);
  });

  test('deve atualizar lista removendo e adicionando itens', () async {
    var list = ShoppingList(
      id: 'list-3',
      name: 'Atualizar Lista',
      createdAt: DateTime.utc(2026, 10, 3),
      items: [
        ShoppingItem(id: 'item-1', rawText: 'A', parsedName: 'A'),
        ShoppingItem(id: 'item-2', rawText: 'B', parsedName: 'B'),
      ],
    );

    await repository.save(list);

    list = list.copyWith(
      items: [
        ShoppingItem(id: 'item-2', rawText: 'B', parsedName: 'B'),
        ShoppingItem(id: 'item-3', rawText: 'C', parsedName: 'C'),
      ],
    );

    await repository.save(list);

    final loaded = (await repository.getById('list-3')).valueOrNull!;
    expect(loaded.items, hasLength(2));
    expect(loaded.items.map((e) => e.id).toList(), ['item-2', 'item-3']);
  });

  test('deve listar todas as listas ordenadas por createdAt desc', () async {
    final list1 = ShoppingList(
      id: 'list-1',
      name: 'Lista Antiga',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final list2 = ShoppingList(
      id: 'list-2',
      name: 'Lista Nova',
      createdAt: DateTime.utc(2026, 1, 2),
    );

    await repository.save(list1);
    await repository.save(list2);

    final allResult = await repository.getAll();
    expect(allResult.isOk, isTrue);

    final all = allResult.valueOrNull!;
    expect(all, hasLength(2));
    expect(all[0].id, 'list-2'); // A mais nova primeiro
    expect(all[1].id, 'list-1');
  });

  test('datas devem ser salvas como UTC ISO8601', () async {
    final list = ShoppingList(
      id: 'list-utc',
      name: 'UTC Test',
      createdAt: DateTime(2026, 10, 1, 12, 0, 0), // Local time
      items: [
        ShoppingItem(
          id: 'item-utc',
          rawText: 'Item',
          parsedName: 'Item',
          boughtAt: DateTime(2026, 10, 1, 14, 0, 0), // Local time
        ),
      ],
    );

    await repository.save(list);

    final listRow = await (database.select(
      database.shoppingLists,
    )..where((t) => t.id.equals('list-utc'))).getSingle();
    final itemRow = await (database.select(
      database.shoppingItems,
    )..where((t) => t.listId.equals('list-utc'))).getSingle();

    expect(
      listRow.createdAt!.endsWith('Z'),
      isTrue,
      reason: 'createdAt deve terminar em Z (UTC)',
    );
    expect(
      itemRow.checkedAt!.endsWith('Z'),
      isTrue,
      reason: 'checkedAt deve terminar em Z (UTC)',
    );

    final loaded = (await repository.getById('list-utc')).valueOrNull!;
    expect(
      loaded.createdAt.isUtc,
      isTrue,
      reason: 'Loaded createdAt deve ser UTC',
    );
    expect(
      loaded.items.first.boughtAt!.isUtc,
      isTrue,
      reason: 'Loaded boughtAt deve ser UTC',
    );
  });
}
