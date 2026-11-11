import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';

part 'product_list_provider.g.dart';

@riverpod
class ProductSearchQuery extends _$ProductSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Future<List<Product>> productList(Ref ref) async {
  final query = ref.watch(productSearchQueryProvider);
  final repository = ref.watch(productRepositoryProvider);

  if (query.isEmpty) {
    // For simplicity, without query return latest products, or empty list to force search.
    // SPEC-002 does not specify whether initial list is empty, but "product screen: list" suggests
    // listing products (or index) or at least searching.
    // Vamos buscar tudo com limite
    final result = await repository.search('');
    return result.valueOrNull ?? [];
  }

  final result = await repository.search(query);
  return result.valueOrNull ?? [];
}
