import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/prices/domain/price_alert/price_alert.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';

/// PURE — no I/O, decides whether observed price triggers variation alert (RN-057).
abstract interface class PriceAlertPolicy {
  PriceAlert? evaluate({
    required Money observed,
    required PriceStats stats,
    double thresholdPercent = 20.0,
    String productId,
  });
}

final class DefaultPriceAlertPolicy implements PriceAlertPolicy {
  const DefaultPriceAlertPolicy();

  @override
  PriceAlert? evaluate({
    required Money observed,
    required PriceStats stats,
    double thresholdPercent = 20.0,
    String productId = '',
  }) {
    if (stats.observationsCount == 0 || stats.averagePrice.cents <= 0) {
      return null;
    }

    final diffCents = observed.cents - stats.averagePrice.cents;
    final percentage = (diffCents.abs() / stats.averagePrice.cents) * 100.0;

    if (percentage > thresholdPercent) {
      return PriceAlert(
        productId: productId,
        observedPrice: observed,
        averagePrice: stats.averagePrice,
        percentageChange: percentage,
        direction: diffCents > 0 ? PriceDirection.up : PriceDirection.down,
        windowDays: stats.windowDays,
        thresholdPercent: thresholdPercent,
      );
    }

    return null;
  }
}
