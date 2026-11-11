library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

abstract interface class ProductRepository {
  Future<Result<Product, Failure>> create(NewProduct p);
  Future<Result<Product, Failure>> addAlias(
    ProductId id,
    String alias,
    AliasSource source,
  );
  Future<Result<Product, Failure>> setCanonicalName(
    ProductId id,
    String canonicalName,
  );
  Future<Result<Product, Failure>> separateAlias(String aliasId);
  Future<Result<void, Failure>> removeAlias(String aliasId);
  Future<Result<AliasConflict?, Failure>> checkAliasConflict(String alias);
  Future<Result<void, Failure>> registerDenial(ProductId id, String rawText);
  Future<Result<List<Product>, Failure>> search(String query, {int limit = 50});
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  });
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id);
  Future<Result<ProductIndex, Failure>> buildIndex();
  Future<Result<bool, Failure>> hasHistory(ProductId id);
  Future<Result<void, Failure>> archive(ProductId id);
  Future<Result<void, Failure>> delete(ProductId id);
}
