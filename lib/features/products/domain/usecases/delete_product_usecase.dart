import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<void, Failure>> call(ProductId id) async {
    final historyResult = await _repository.hasHistory(id);
    switch (historyResult) {
      case Ok(:final value):
        if (value) {
          return const Err(ValidationFailure(fields: {'id': 'has_history'}));
        }
        return _repository.delete(id);
      case Err(:final failure):
        return Err(failure);
    }
  }
}
