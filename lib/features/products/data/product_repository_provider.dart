import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductDao(
    ref.watch(databaseProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
});
