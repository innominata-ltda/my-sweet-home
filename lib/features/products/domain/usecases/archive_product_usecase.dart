import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

class ArchiveProductUseCase {
  const ArchiveProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<void, Failure>> call(ProductId id) async {
    return _repository.archive(id);
  }
}
