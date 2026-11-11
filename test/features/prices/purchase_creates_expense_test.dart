import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/domain/store/store_repository.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/convert_purchase_to_expense_use_case.dart';

class FakeStoreRepository implements StoreRepository {
  final _stores = <String, Store>{};

  @override
  Future<Result<void, Failure>> save(Store store) async {
    _stores[store.id] = store;
    return const Ok(null);
  }

  @override
  Future<Result<Store, Failure>> findById(String id) async {
    final store = _stores[id];
    if (store == null) {
      return Err(NotFoundFailure(what: 'Store $id'));
    }
    return Ok(store);
  }

  @override
  Future<Result<Store, Failure>> findByCnpj(String cnpjValue) async {
    return const Err(NotFoundFailure(what: 'Not implemented'));
  }

  @override
  Future<Result<List<Store>, Failure>> listAll() async {
    return Ok(_stores.values.toList());
  }
}

void main() {
  group('ConvertPurchaseToExpenseUseCase', () {
    late FakeStoreRepository storeRepo;
    late FakeExpenseRepository expenseRepo;
    late ConvertPurchaseToExpenseUseCase useCase;
    late Clock clock;

    setUp(() {
      clock = SystemClock();
      storeRepo = FakeStoreRepository();
      expenseRepo = FakeExpenseRepository(clock);
      useCase = ConvertPurchaseToExpenseUseCase(expenseRepo, storeRepo);
    });

    test('must create expense from purchase with correct data', () async {
      // Arrange
      final store = Store(
        id: 'store-1',
        name: 'Mercado do Zé',
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      );
      await storeRepo.save(store);

      final purchaseDate = clock.nowUtc();
      final purchase = Purchase(
        id: 'purchase-1',
        storeId: 'store-1',
        date: purchaseDate,
        items: [], // Does not matter for this test
        totalAmount: const Money(8740),
        discountAmount: Money.zero,
      );

      // Act
      final result = await useCase(purchase);

      // Assert
      expect(result.isOk, isTrue);
      final expense = result.valueOrNull!;

      expect(expense.amount.cents, 8740);
      expect(expense.description, 'Mercado do Zé');
      expect(expense.categoryId, const CategoryId('cat_market'));
      expect(expense.occurredOn, purchaseDate);
      expect(expense.purchaseId, 'purchase-1');
    });

    test(
      'deve retornar erro se o estabelecimento não for encontrado',
      () async {
        // Arrange
        final purchase = Purchase(
          id: 'purchase-1',
          storeId: 'store-not-found',
          date: clock.nowUtc(),
          items: [],
          totalAmount: const Money(8740),
          discountAmount: Money.zero,
        );

        // Act
        final result = await useCase(purchase);

        // Assert
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });
}
