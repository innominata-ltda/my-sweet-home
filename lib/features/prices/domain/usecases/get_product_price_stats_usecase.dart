import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';

class GetProductPriceStatsUseCase {
  const GetProductPriceStatsUseCase({
    required this.repository,
    required this.clock,
  });

  final PricePointRepository repository;
  final Clock clock;

  /// Returns price statistics (mean, observations) for product in last [windowDays] (default 30).
  Future<Result<PriceStats, Failure>> getStats(
    String productId, {
    int windowDays = 30,
  }) {
    final since = clock.nowUtc().subtract(Duration(days: windowDays));
    return repository.getStatsByProduct(
      productId,
      since: since,
      windowDays: windowDays,
    );
  }

  /// Retorna o ranking de estabelecimentos por menor preco medio normalizado (RN-056).
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    int windowDays = 30,
    int minObservations = 2,
  }) {
    final since = clock.nowUtc().subtract(Duration(days: windowDays));
    return repository.getCheapestStores(
      productId,
      since: since,
      windowDays: windowDays,
      minObservations: minObservations,
    );
  }

  /// Retorna o historico detalhado, opcionalmente filtrando por loja.
  Future<Result<List<PricePoint>, Failure>> getHistory(
    String productId, {
    int windowDays = 30,
    String? storeId,
  }) {
    final since = clock.nowUtc().subtract(Duration(days: windowDays));
    return repository.getByProduct(productId, since: since, storeId: storeId);
  }
}
