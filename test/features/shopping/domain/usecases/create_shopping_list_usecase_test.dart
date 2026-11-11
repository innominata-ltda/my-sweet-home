import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/create_shopping_list_usecase.dart';

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
  late CreateShoppingListUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    idGenerator = FakeIdGenerator();
    clock = FakeClock();
    useCase = CreateShoppingListUseCase(repository, idGenerator, clock);
  });

  test(
    'deve criar uma nova lista de compras e salvar no repositório',
    () async {
      final result = await useCase('Mercado', storeId: 'store-1');

      expect(result.isOk, isTrue);
      final list = result.valueOrNull!;
      expect(list.id, 'id-1');
      expect(list.name, 'Mercado');
      expect(list.storeId, 'store-1');
      expect(list.createdAt, clock.nowUtc());
      expect(list.items, isEmpty);

      final saved = await repository.getById('id-1');
      expect(saved.isOk, isTrue);
      expect(saved.valueOrNull, list);
    },
  );

  test('should return validation failure if name is empty', () async {
    final result = await useCase('   ');

    expect(result.isErr, isTrue);
    final failure = result.failureOrNull!;
    expect(failure, isA<ValidationFailure>());
  });
}
