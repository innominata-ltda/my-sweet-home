import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/prices/domain/price_alert/price_alert.dart';
import 'package:my_sweet_home/features/prices/domain/price_alert/price_alert_policy.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';

void main() {
  group('PriceAlertPolicy', () {
    late PriceAlertPolicy policy;

    setUp(() {
      policy = const DefaultPriceAlertPolicy();
    });

    test('CA-4.1: dispara alerta de alta quando variacao (+30%) supera o limiar de 20%', () {
      // Average of R$ 5.00 (500 cents) and new price of R$ 6.50 (650 cents) (+30%)
      const stats = PriceStats(
        averagePrice: Money(500),
        observationsCount: 5,
        windowDays: 30,
      );

      final alert = policy.evaluate(
        productId: 'prod-1',
        observed: const Money(650),
        stats: stats,
        thresholdPercent: 20.0,
      );

      expect(alert, isNotNull);
      expect(alert!.productId, 'prod-1');
      expect(alert.observedPrice, const Money(650));
      expect(alert.averagePrice, const Money(500));
      expect(alert.direction, PriceDirection.up);
      expect(alert.percentageChange, closeTo(30.0, 0.001));
      expect(alert.windowDays, 30);
      expect(alert.thresholdPercent, 20.0);
      expect(alert.message, 'Alta de 30% sobre a média de 30 dias');
    });

    test('CA-4.2: does not trigger alert when variance (+30%) is below 40% threshold', () {
      // Average of R$ 5.00 and new price of R$ 6.50 (+30%), 40% threshold
      const stats = PriceStats(
        averagePrice: Money(500),
        observationsCount: 5,
        windowDays: 30,
      );

      final alert = policy.evaluate(
        productId: 'prod-1',
        observed: const Money(650),
        stats: stats,
        thresholdPercent: 40.0,
      );

      expect(alert, isNull);
    });

    test(
      'dispara alerta de baixa quando queda (-30%) supera o limiar de 20%',
      () {
        // Average of R$ 10.00 (1000 cents) and new price of R$ 7.00 (700 cents) (-30%)
        const stats = PriceStats(
          averagePrice: Money(1000),
          observationsCount: 3,
          windowDays: 30,
        );

        final alert = policy.evaluate(
          productId: 'prod-2',
          observed: const Money(700),
          stats: stats,
          thresholdPercent: 20.0,
        );

        expect(alert, isNotNull);
        expect(alert!.productId, 'prod-2');
        expect(alert.observedPrice, const Money(700));
        expect(alert.averagePrice, const Money(1000));
        expect(alert.direction, PriceDirection.down);
        expect(alert.percentageChange, closeTo(30.0, 0.001));
        expect(alert.windowDays, 30);
        expect(alert.message, 'Baixa de 30% sobre a média de 30 dias');
      },
    );

    test(
      'returns null when there are no observations (observationsCount = 0)',
      () {
        const stats = PriceStats(
          averagePrice: Money(500),
          observationsCount: 0,
          windowDays: 30,
        );

        final alert = policy.evaluate(
          observed: const Money(650),
          stats: stats,
          thresholdPercent: 20.0,
        );

        expect(alert, isNull);
      },
    );

    test('returns null when average price is zero (averagePrice = 0)', () {
      const stats = PriceStats(
        averagePrice: Money.zero,
        observationsCount: 5,
        windowDays: 30,
      );

      final alert = policy.evaluate(
        observed: const Money(650),
        stats: stats,
        thresholdPercent: 20.0,
      );

      expect(alert, isNull);
    });

    test(
      'returns null when variance is exactly equal to threshold (20.0%)',
      () {
        // Average R$ 5.00 (500 cents), new price R$ 6.00 (600 cents) (+20.0%)
        const stats = PriceStats(
          averagePrice: Money(500),
          observationsCount: 5,
          windowDays: 30,
        );

        final alert = policy.evaluate(
          observed: const Money(600),
          stats: stats,
          thresholdPercent: 20.0,
        );

        expect(alert, isNull);
      },
    );

    test('returns null when observed price equals average price', () {
      const stats = PriceStats(
        averagePrice: Money(500),
        observationsCount: 5,
        windowDays: 30,
      );

      final alert = policy.evaluate(
        observed: const Money(500),
        stats: stats,
        thresholdPercent: 20.0,
      );

      expect(alert, isNull);
    });

    test('PriceAlert == e hashCode', () {
      const alert1 = PriceAlert(
        productId: 'p1',
        observedPrice: Money(650),
        averagePrice: Money(500),
        percentageChange: 30.0,
        direction: PriceDirection.up,
        windowDays: 30,
        thresholdPercent: 20.0,
      );

      const alert2 = PriceAlert(
        productId: 'p1',
        observedPrice: Money(650),
        averagePrice: Money(500),
        percentageChange: 30.0,
        direction: PriceDirection.up,
        windowDays: 30,
        thresholdPercent: 20.0,
      );

      expect(alert1, equals(alert1));
      expect(alert1, equals(alert2));
      expect(alert1.hashCode, equals(alert2.hashCode));
      expect(alert1, isNot(equals('alert')));
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p2',
              observedPrice: Money(650),
              averagePrice: Money(500),
              percentageChange: 30.0,
              direction: PriceDirection.up,
              windowDays: 30,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(700),
              averagePrice: Money(500),
              percentageChange: 30.0,
              direction: PriceDirection.up,
              windowDays: 30,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(650),
              averagePrice: Money(400),
              percentageChange: 30.0,
              direction: PriceDirection.up,
              windowDays: 30,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(650),
              averagePrice: Money(500),
              percentageChange: 40.0,
              direction: PriceDirection.up,
              windowDays: 30,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(650),
              averagePrice: Money(500),
              percentageChange: 30.0,
              direction: PriceDirection.down,
              windowDays: 30,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(650),
              averagePrice: Money(500),
              percentageChange: 30.0,
              direction: PriceDirection.up,
              windowDays: 60,
              thresholdPercent: 20.0,
            ),
          ),
        ),
      );
      expect(
        alert1,
        isNot(
          equals(
            const PriceAlert(
              productId: 'p1',
              observedPrice: Money(650),
              averagePrice: Money(500),
              percentageChange: 30.0,
              direction: PriceDirection.up,
              windowDays: 30,
              thresholdPercent: 30.0,
            ),
          ),
        ),
      );
    });
  });
}
