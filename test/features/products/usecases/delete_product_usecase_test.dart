import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';
import 'package:my_sweet_home/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';

class MockProductRepository implements ProductRepository {
  bool deleteCalled = false;
  ProductId? deleteId;

  bool historyReturnValue = false;

  @override
  Future<Result<bool, Failure>> hasHistory(ProductId id) async {
    return Ok(historyReturnValue);
  }

  @override
  Future<Result<void, Failure>> delete(ProductId id) async {
    deleteCalled = true;
    deleteId = id;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> archive(ProductId id) =>
      throw UnimplementedError();
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
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  }) => throw UnimplementedError();
  @override
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id) =>
      throw UnimplementedError();
}

void main() {
  group('DeleteProductUseCase', () {
    test('returns ValidationFailure if product has history', () async {
      final repo = MockProductRepository()..historyReturnValue = true;
      final useCase = DeleteProductUseCase(repo);

      final result = await useCase('prod-1');

      expect(result.isErr, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        (result.failureOrNull as ValidationFailure).fields['id'],
        'has_history',
      );
      expect(repo.deleteCalled, false);
    });

    test('calls repository.delete if product has no history', () async {
      final repo = MockProductRepository()..historyReturnValue = false;
      final useCase = DeleteProductUseCase(repo);

      final result = await useCase('prod-1');

      expect(result.isOk, true);
      expect(repo.deleteCalled, true);
      expect(repo.deleteId, 'prod-1');
    });
  });
}
