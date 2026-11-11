import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/get_product_price_stats_usecase.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';

final getProductPriceStatsUseCaseProvider =
    Provider<GetProductPriceStatsUseCase>((ref) {
      return GetProductPriceStatsUseCase(
        repository: ref.watch(pricePointRepositoryProvider),
        clock: ref.watch(clockProvider),
      );
    });

final priceStatsProvider = FutureProvider.family<PriceStats, String>((
  ref,
  productId,
) async {
  final useCase = ref.watch(getProductPriceStatsUseCaseProvider);
  final result = await useCase.getStats(productId);
  return result.fold((stats) => stats, (failure) => throw failure);
});

final priceHistoryProvider =
    FutureProvider.family<
      List<PricePoint>,
      ({String productId, String? storeId})
    >((ref, args) async {
      final useCase = ref.watch(getProductPriceStatsUseCaseProvider);
      final result = await useCase.getHistory(
        args.productId,
        storeId: args.storeId,
      );
      return result.fold((history) => history, (failure) => throw failure);
    });

final cheapestStoresProvider =
    FutureProvider.family<List<StoreRanking>, String>((ref, productId) async {
      final useCase = ref.watch(getProductPriceStatsUseCaseProvider);
      final result = await useCase.getCheapestStores(productId);
      return result.fold((rankings) => rankings, (failure) => throw failure);
    });
