import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/duplicate_shopping_list_usecase.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingList> _lists = {};

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(_lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = _lists[id];
    if (list != null) {
      return Ok(list);
    }
    return Err(NotFoundFailure(what: 'ShoppingList $id'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    _lists[list.id] = list;
    return const Ok(null);
  }
}

class FakeIdGenerator implements IdGenerator {
  int _counter = 0;
  @override
  String newId() => 'id-${++_counter}';
}

class FakeClock implements Clock {
  final DateTime _now = DateTime.utc(2026, 9, 25, 12, 0, 0);

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime nowLocal() => _now.toLocal();

  @override
  DateTime todayUtc() => DateTime.utc(_now.year, _now.month, _now.day);
}

void main() {
  late FakeShoppingListRepository repository;
  late FakeIdGenerator idGenerator;
  late FakeClock clock;
  late DuplicateShoppingListUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    idGenerator = FakeIdGenerator();
    clock = FakeClock();
    useCase = DuplicateShoppingListUseCase(repository, idGenerator, clock);
  });

  test('must duplicate list and clear bought status on items', () async {
    final list = ShoppingList(
      id: 'old-1',
      name: 'Mercado',
      createdAt: DateTime.utc(2026, 9, 20, 10, 0, 0),
      storeId: 'store-1',
      isArchived: true,
      items: [
        ShoppingItem(
          id: 'item-1',
          rawText: 'Arroz',
          parsedName: 'Arroz',
          boughtAt: DateTime.utc(2026, 9, 21, 10, 0, 0),
        ),
      ],
    );
    await repository.save(list);

    final result = await useCase('old-1');
    expect(result.isOk, isTrue);

    final duplicated = result.valueOrNull!;
    expect(duplicated.id, 'id-2');
    expect(duplicated.name, 'Mercado (Cópia)');
    expect(duplicated.createdAt, clock.nowUtc());
    expect(duplicated.storeId, 'store-1');
    expect(duplicated.isArchived, isFalse);
    expect(duplicated.items, hasLength(1));
    expect(duplicated.items.first.id, 'id-1'); // Gerado para o item
    expect(
      duplicated.items.first.isBought,
      isFalse,
    ); // Removido o status de comprado
  });

  test('must duplicate with new name if provided', () async {
    final list = ShoppingList(
      id: 'old-2',
      name: 'Mercado',
      createdAt: DateTime.utc(2026, 9, 20, 10, 0, 0),
    );
    await repository.save(list);

    final result = await useCase('old-2', newName: 'Mercado de Outubro');
    expect(result.isOk, isTrue);

    final duplicated = result.valueOrNull!;
    expect(duplicated.name, 'Mercado de Outubro');
  });

  test('should propagate error if original list does not exist', () async {
    final result = await useCase('id-404');
    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
