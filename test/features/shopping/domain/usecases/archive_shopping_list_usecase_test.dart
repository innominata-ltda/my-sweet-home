import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/archive_shopping_list_usecase.dart';

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

void main() {
  late FakeShoppingListRepository repository;
  late ArchiveShoppingListUseCase useCase;

  setUp(() {
    repository = FakeShoppingListRepository();
    useCase = ArchiveShoppingListUseCase(repository);
  });

  test('deve arquivar a lista de compras', () async {
    final list = ShoppingList(
      id: 'id-1',
      name: 'Mercado',
      createdAt: DateTime.utc(2026, 9, 25, 12, 0, 0),
    );
    await repository.save(list);

    final result = await useCase('id-1');
    expect(result.isOk, isTrue);

    final saved = await repository.getById('id-1');
    expect(saved.valueOrNull!.isArchived, isTrue);
  });

  test('should return success even if already archived', () async {
    final list = ShoppingList(
      id: 'id-2',
      name: 'Farmácia',
      createdAt: DateTime.utc(2026, 9, 25, 12, 0, 0),
      isArchived: true,
    );
    await repository.save(list);

    final result = await useCase('id-2');
    expect(result.isOk, isTrue);

    final saved = await repository.getById('id-2');
    expect(saved.valueOrNull!.isArchived, isTrue);
  });

  test('should propagate error if list does not exist', () async {
    final result = await useCase('id-404');
    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
