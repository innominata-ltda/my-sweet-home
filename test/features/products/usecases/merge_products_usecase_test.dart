import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';
import 'package:my_sweet_home/features/products/domain/usecases/merge_products_usecase.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';

class MockProductRepository implements ProductRepository {
  bool mergeCalled = false;
  ProductId? fromId;
  ProductId? intoId;

  @override
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  }) async {
    mergeCalled = true;
    fromId = from;
    intoId = into;
    return Ok(
      MergeReceipt(
        id: 'receipt-1',
        mergedProductId: into,
        archivedProductId: from,
      ),
    );
  }

  @override
  Future<Result<Product, Failure>> addAlias(
    ProductId id,
    String alias,
    AliasSource source,
  ) => throw UnimplementedError();
  @override
  Future<Result<Product, Failure>> setCanonicalName(
    ProductId id,
    String canonicalName,
  ) => throw UnimplementedError();
  @override
  Future<Result<Product, Failure>> separateAlias(String aliasId) =>
      throw UnimplementedError();
  @override
  Future<Result<ProductIndex, Failure>> buildIndex() =>
      throw UnimplementedError();
  @override
  Future<Result<AliasConflict?, Failure>> checkAliasConflict(String alias) =>
      throw UnimplementedError();
  @override
  Future<Result<Product, Failure>> create(NewProduct p) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> registerDenial(ProductId id, String rawText) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> removeAlias(String aliasId) =>
      throw UnimplementedError();
  @override
  Future<Result<List<Product>, Failure>> search(
    String query, {
    int limit = 50,
  }) => throw UnimplementedError();
  @override
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id) =>
      throw UnimplementedError();
  @override
  Future<Result<bool, Failure>> hasHistory(ProductId id) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> archive(ProductId id) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> delete(ProductId id) =>
      throw UnimplementedError();
}

void main() {
  group('MergeProductsUseCase', () {
    test('calls repository.merge with correct IDs, which handles alias inheritance and archiving logic', () async {
      final repo = MockProductRepository();
      final useCase = MergeProductsUseCase(repo);

      final winner = Product(
        id: 'winner-id',
        canonicalName: 'Winner Product',
        categoryId: 'cat-1',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final loser = Product(
        id: 'loser-id',
        canonicalName: 'Loser Product',
        categoryId: 'cat-1',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await useCase(winner: winner, loser: loser);

      expect(result.isOk, true);
      expect(repo.mergeCalled, true);
      expect(repo.fromId, 'loser-id');
      expect(repo.intoId, 'winner-id');

      final receipt = result.valueOrNull!;
      expect(receipt.mergedProductId, 'winner-id');
      expect(receipt.archivedProductId, 'loser-id');
    });
  });
}
