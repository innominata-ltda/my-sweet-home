import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

/// Store ranking by normalized price for a product (RN-056).
final class StoreRanking {
  const StoreRanking({
    required this.store,
    required this.averageNormalized,
    required this.observations,
    this.minObservations = 2,
  });

  /// Estabelecimento comercial.
  final Store store;

  /// Normalized average price.
  final Money averageNormalized;

  /// Number of observations in period.
  final int observations;

  /// Minimum observations required for solid conclusion.
  final int minObservations;

  /// Indicates if store has fewer observations than required minimum (RN-056).
  bool get hasLittleData => observations < minObservations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreRanking &&
          other.store == store &&
          other.averageNormalized == averageNormalized &&
          other.observations == observations &&
          other.minObservations == minObservations;

  @override
  int get hashCode =>
      Object.hash(store, averageNormalized, observations, minObservations);
}
