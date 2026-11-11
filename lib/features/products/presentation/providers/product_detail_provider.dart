import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

part 'product_detail_provider.g.dart';

@riverpod
Future<List<ProductAlias>> productAliases(Ref ref, ProductId id) async {
  final repository = ref.watch(productRepositoryProvider);
  final indexResult = await repository.buildIndex();
  if (indexResult.isErr) return [];

  final index = indexResult.valueOrNull!;
  return index.aliases.where((a) => a.productId == id).toList();
}

@riverpod
Future<Product?> productDetail(Ref ref, ProductId id) async {
  final repository = ref.watch(productRepositoryProvider);
  final indexResult = await repository.buildIndex();
  if (indexResult.isErr) return null;

  final index = indexResult.valueOrNull!;
  return index.products.where((p) => p.id == id).firstOrNull;
}

@riverpod
class ProductAliasController extends _$ProductAliasController {
  @override
  FutureOr<void> build() {}

  Future<void> addAlias(ProductId productId, String alias) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.addAlias(
        productId,
        alias,
        AliasSource.user,
      );
      if (result.isOk) {
        ref.invalidate(productAliasesProvider(productId));
        ref.invalidate(productListProvider);
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
      }
    } finally {
      link.close();
    }
  }

  Future<void> setPreferredName(
    ProductId productId,
    String canonicalName,
  ) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.setCanonicalName(
        productId,
        canonicalName,
      );
      if (result.isOk) {
        ref.invalidate(productDetailProvider(productId));
        ref.invalidate(productAliasesProvider(productId));
        ref.invalidate(productListProvider);
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
      }
    } finally {
      link.close();
    }
  }

  Future<Product?> separateAlias(ProductId productId, String aliasId) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.separateAlias(aliasId);
      if (result.isOk) {
        ref.invalidate(productDetailProvider(productId));
        ref.invalidate(productAliasesProvider(productId));
        ref.invalidate(productListProvider);
        state = const AsyncValue.data(null);
        return result.valueOrNull;
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
        return null;
      }
    } finally {
      link.close();
    }
  }

  Future<void> removeAlias(ProductId productId, String aliasId) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.removeAlias(aliasId);
      if (result.isOk) {
        ref.invalidate(productAliasesProvider(productId));
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
      }
    } finally {
      link.close();
    }
  }

  Future<MergeReceipt?> mergeProduct({
    required ProductId loserId,
    required ProductId winnerId,
  }) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.merge(from: loserId, into: winnerId);
      if (result.isOk) {
        ref.invalidate(productDetailProvider(loserId));
        ref.invalidate(productDetailProvider(winnerId));
        ref.invalidate(productAliasesProvider(loserId));
        ref.invalidate(productAliasesProvider(winnerId));
        ref.invalidate(productListProvider);
        state = const AsyncValue.data(null);
        return result.valueOrNull;
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
        return null;
      }
    } finally {
      link.close();
    }
  }

  Future<void> undoMerge(
    MergeReceiptId receiptId,
    ProductId loserId,
    ProductId winnerId,
  ) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.undoMerge(receiptId);
      if (result.isOk) {
        ref.invalidate(productDetailProvider(loserId));
        ref.invalidate(productDetailProvider(winnerId));
        ref.invalidate(productAliasesProvider(loserId));
        ref.invalidate(productAliasesProvider(winnerId));
        ref.invalidate(productListProvider);
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          result.failureOrNull!.toString(),
          StackTrace.current,
        );
      }
    } finally {
      link.close();
    }
  }
}
