import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/write_off_shopping_list_usecase.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingList> _store = {};

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(_store.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = _store[id];
    if (list == null) return Err(NotFoundFailure(what: 'List $id'));
    return Ok(list);
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    _store[list.id] = list;
    return const Ok(null);
  }

  void seed(ShoppingList list) {
    _store[list.id] = list;
  }
}

void main() {
  group('WriteOffShoppingListUseCase', () {
    late FakeShoppingListRepository repository;
    late WriteOffShoppingListUseCase useCase;

    setUp(() {
      repository = FakeShoppingListRepository();
      useCase = WriteOffShoppingListUseCase(repository);
    });

    final defaultDate = DateTime(2026, 9, 25, 10, 0);

    final purchase = Purchase(
      id: 'pur-1',
      storeId: 'store-1',
      date: defaultDate,
      items: [
        PurchaseItem(
          id: 'pi-1',
          productId: 'prod-A',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(1000),
          totalPrice: const Money(1000),
        ),
        PurchaseItem(
          id: 'pi-2',
          productId: 'prod-B',
          quantity: const Quantity(2000, Unit.un),
          unitPrice: const Money(500),
          totalPrice: const Money(1000),
        ),
      ],
      totalAmount: const Money(2000),
      discountAmount: const Money(0),
    );

    test(
      'deve baixar apenas os itens cujos produtos estejam na compra',
      () async {
        final list = ShoppingList(
          id: 'list-1',
          name: 'Mercado',
          createdAt: DateTime(2026, 9, 24),
          items: [
            const ShoppingItem(
              id: 'item-1',
              rawText: 'Arroz',
              parsedName: 'Arroz',
              productId: 'prod-A',
            ),
            const ShoppingItem(
              id: 'item-2',
              rawText: 'Feijão',
              parsedName: 'Feijão',
              productId: 'prod-C', // Not in purchase
            ),
            const ShoppingItem(
              id: 'item-3',
              rawText: 'Macarrão',
              parsedName: 'Macarrão',
              productId: 'prod-B',
            ),
          ],
        );

        repository.seed(list);

        final result = await useCase(listId: 'list-1', purchase: purchase);

        expect(result.isOk, isTrue);

        final updatedList = result.valueOrNull!;
        expect(updatedList.items[0].isBought, isTrue);
        expect(updatedList.items[0].boughtAt, defaultDate);

        expect(updatedList.items[1].isBought, isFalse);

        expect(updatedList.items[2].isBought, isTrue);
        expect(updatedList.items[2].boughtAt, defaultDate);

        // Verify that it was saved
        final savedResult = await repository.getById('list-1');
        expect(savedResult.valueOrNull, updatedList);
      },
    );

    test('should not modify list if no product matches', () async {
      final list = ShoppingList(
        id: 'list-2',
        name: 'Mercado',
        createdAt: DateTime(2026, 9, 24),
        items: [
          const ShoppingItem(
            id: 'item-1',
            rawText: 'Feijão',
            parsedName: 'Feijão',
            productId: 'prod-C',
          ),
        ],
      );

      repository.seed(list);

      final result = await useCase(listId: 'list-2', purchase: purchase);

      expect(result.isOk, isTrue);

      final updatedList = result.valueOrNull!;
      expect(updatedList.items[0].isBought, isFalse);

      // Verify it was not saved unnecessarily (if optimization exists, though not strictly required)
      expect(updatedList, list);
    });

    test('should not modify items that were already written off', () async {
      final oldDate = DateTime(2026, 9, 20);
      final list = ShoppingList(
        id: 'list-3',
        name: 'Mercado',
        createdAt: DateTime(2026, 9, 24),
        items: [
          ShoppingItem(
            id: 'item-1',
            rawText: 'Arroz',
            parsedName: 'Arroz',
            productId: 'prod-A',
            boughtAt: oldDate, // Already bought
          ),
        ],
      );

      repository.seed(list);

      final result = await useCase(listId: 'list-3', purchase: purchase);

      expect(result.isOk, isTrue);

      final updatedList = result.valueOrNull!;
      expect(updatedList.items[0].isBought, isTrue);
      expect(updatedList.items[0].boughtAt, oldDate); // Data antiga mantida
    });

    test('returns Err if list is not found', () async {
      final result = await useCase(
        listId: 'list-not-found',
        purchase: purchase,
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
