import 'package:my_sweet_home/core/money/money.dart';

/// Price statistics of a product in a time window (RN-055).
final class PriceStats {
  const PriceStats({
    required this.averagePrice,
    required this.observationsCount,
    required this.windowDays,
  });

  /// Normalized average price.
  final Money averagePrice;

  /// Number of observations in window.
  final int observationsCount;

  /// Tamanho da janela em dias.
  final int windowDays;
}
