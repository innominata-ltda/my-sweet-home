import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/import_shopping_list_usecase.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  ShoppingList? savedList;
  bool shouldFail = false;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return const Ok([]);
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    if (savedList?.id == id) {
      return Ok(savedList!);
    }
    return const Err(NotFoundFailure(what: 'ShoppingList'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Failed to save'));
    }
    savedList = list;
    return const Ok(null);
  }
}

void main() {
  group('ImportShoppingListUseCase', () {
    late FakeShoppingListRepository repository;
    late ImportShoppingListUseCase usecase;

    setUp(() {
      repository = FakeShoppingListRepository();
      usecase = ImportShoppingListUseCase(repository);
    });

    test('imports a valid JSON string successfully and saves it', () async {
      final date = DateTime(2026, 9, 25, 12, 0).toUtc();
      final list = ShoppingList(
        id: 'list_1',
        name: 'Compras da Semana',
        createdAt: date,
        storeId: 'store_1',
        isArchived: true,
        items: [],
      );

      final jsonString = jsonEncode(list.toJson());

      final result = await usecase.call(jsonString);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, equals(list));
      expect(repository.savedList, equals(list));
    });

    test('returns StorageFailure when JSON is invalid', () async {
      final result = await usecase.call('invalid json');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('returns Failure from repository when save fails', () async {
      repository.shouldFail = true;

      final date = DateTime(2026, 9, 25, 12, 0).toUtc();
      final list = ShoppingList(id: 'list_1', name: 'Compras', createdAt: date);

      final jsonString = jsonEncode(list.toJson());

      final result = await usecase.call(jsonString);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
      expect((result.failureOrNull as StorageFailure).detail, 'Failed to save');
    });
  });
}
