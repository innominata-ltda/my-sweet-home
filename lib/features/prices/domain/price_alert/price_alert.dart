import 'package:my_sweet_home/core/money/money.dart';

/// Price variation direction relative to historical average (RN-057).
enum PriceDirection {
  /// Observed price is above average.
  up,

  /// Observed price is below average.
  down,
}

/// Price variation alert (RF-031, RN-057).
final class PriceAlert {
  const PriceAlert({
    required this.productId,
    required this.observedPrice,
    required this.averagePrice,
    required this.percentageChange,
    required this.direction,
    required this.windowDays,
    required this.thresholdPercent,
  });

  /// ID do produto avaliado.
  final String productId;

  /// Observed price in current record.
  final Money observedPrice;

  /// Historical average price of window.
  final Money averagePrice;

  /// Calculated percentage variation (e.g. 30.0 for 30%).
  final double percentageChange;

  /// Direction of variation (up or down).
  final PriceDirection direction;

  /// Janela de dias usada como base (ex: 30 dias).
  final int windowDays;

  /// Configured variation threshold (e.g. 20.0 for 20%).
  final double thresholdPercent;

  /// Returns friendly alert message (e.g. "30% increase over 30-day average").
  String get message {
    final dirText = direction == PriceDirection.up ? 'Alta' : 'Baixa';
    final pctString = percentageChange.round().toString();
    return '$dirText de $pctString% sobre a média de $windowDays dias';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceAlert &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          observedPrice == other.observedPrice &&
          averagePrice == other.averagePrice &&
          (percentageChange - other.percentageChange).abs() < 0.001 &&
          direction == other.direction &&
          windowDays == other.windowDays &&
          (thresholdPercent - other.thresholdPercent).abs() < 0.001;

  @override
  int get hashCode =>
      productId.hashCode ^
      observedPrice.hashCode ^
      averagePrice.hashCode ^
      percentageChange.hashCode ^
      direction.hashCode ^
      windowDays.hashCode ^
      thresholdPercent.hashCode;
}
