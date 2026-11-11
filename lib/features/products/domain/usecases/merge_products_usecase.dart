import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

class MergeProductsUseCase {
  const MergeProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<MergeReceipt, Failure>> call({
    required Product winner,
    required Product loser,
  }) async {
    return _repository.merge(from: loser.id, into: winner.id);
  }
}
