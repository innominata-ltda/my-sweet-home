// test/features/shopping/domain/services/suggestion_policy_test.dart
//
// Testes de unidade para [SuggestionPolicy] (CA-7.1, RN-085, RF-054).
// Uses FakeClock indirectly via explicit [now] parameter — without DateTime.now().

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/shopping/domain/services/suggestion_policy.dart';

void main() {
  late DefaultSuggestionPolicy policy;

  // Time anchor: "today" for all tests
  final now = DateTime.utc(2026, 9, 29);

  setUp(() {
    policy = const DefaultSuggestionPolicy();
  });

  // ---------------------------------------------------------------------------
  // CA-7.1 — caso feliz principal
  // ---------------------------------------------------------------------------

  group('CA-7.1 — produto comprado 4 vezes em 4 meses', () {
    // Produto A: comprado em jan, fev, mar, abr (4 meses consecutivos)
    // now = 29/set → ~150 dias desde abr → muito acima do intervalo de 30 dias → deve sugerir
    final prodA = PurchaseFrequency(
      productId: 'prod-A',
      purchaseDates: [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 2, 1),
        DateTime.utc(2026, 3, 1),
        DateTime.utc(2026, 4, 1),
      ],
    );

    test('product absent from list is suggested', () {
      final result = policy.suggest(
        history: [prodA],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.productId, 'prod-A');
    });

    test('product already on list is NOT suggested (RN-085)', () {
      final result = policy.suggest(
        history: [prodA],
        alreadyInList: {'prod-A'},
        now: now,
      );

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // RN-085 - minimum 3 purchases
  // ---------------------------------------------------------------------------

  group('RN-085 — minimum of 3 purchases', () {
    test('product with only 2 purchases is NOT suggested', () {
      final freq = PurchaseFrequency(
        productId: 'prod-X',
        purchaseDates: [DateTime.utc(2026, 7, 1), DateTime.utc(2026, 8, 1)],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, isEmpty);
    });

    test('product with exactly 3 purchases IS suggested', () {
      final freq = PurchaseFrequency(
        productId: 'prod-Y',
        purchaseDates: [
          DateTime.utc(2026, 6, 1),
          DateTime.utc(2026, 7, 1),
          DateTime.utc(2026, 8, 1),
        ],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.productId, 'prod-Y');
    });

    test('product with 1 purchase is NOT suggested', () {
      final freq = PurchaseFrequency(
        productId: 'prod-Z',
        purchaseDates: [DateTime.utc(2026, 8, 1)],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Default limit of 5 suggestions
  // ---------------------------------------------------------------------------

  test('default limit returns at most 5 suggestions', () {
    final history = List.generate(10, (i) {
      return PurchaseFrequency(
        productId: 'prod-$i',
        purchaseDates: [
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 2, 1),
          DateTime.utc(2026, 3, 1),
        ],
      );
    });

    final result = policy.suggest(
      history: history,
      alreadyInList: {},
      now: now,
    );

    expect(result.length, lessThanOrEqualTo(5));
  });

  test('custom limit is respected', () {
    final history = List.generate(8, (i) {
      return PurchaseFrequency(
        productId: 'prod-$i',
        purchaseDates: [
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 2, 1),
          DateTime.utc(2026, 3, 1),
        ],
      );
    });

    final result = policy.suggest(
      history: history,
      alreadyInList: {},
      now: now,
      limit: 3,
    );

    expect(result.length, lessThanOrEqualTo(3));
  });

  // ---------------------------------------------------------------------------
  // Ordering by urgency
  // ---------------------------------------------------------------------------

  group('Urgency sorting (most overdue first)', () {
    test('produto mais atrasado aparece primeiro', () {
      // Product B: bought monthly, last purchase 90 days ago (~3x 30d interval)
      final prodB = PurchaseFrequency(
        productId: 'prod-B',
        purchaseDates: [
          DateTime.utc(2026, 4, 1),
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 6, 1),
          // last: 1/Jun, ago = 90 days ago relative to 29/Sep
          DateTime.utc(2026, 6, 30),
        ],
      );

      // Product C: bought bimonthly, last purchase 30 days ago (~0.5x 60d interval)
      final prodC = PurchaseFrequency(
        productId: 'prod-C',
        purchaseDates: [
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 3, 1),
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 8, 29),
        ],
      );

      final result = policy.suggest(
        history: [prodC, prodB], // intencionalmente na ordem "errada"
        alreadyInList: {},
        now: now,
      );

      expect(result.length, 2);
      // B mais atrasado (daysSince/avg = ~91/30 ≈ 3.0) vs C (~31/61 ≈ 0.5)
      expect(result.first.productId, 'prod-B');
      expect(result.last.productId, 'prod-C');
    });
  });

  // ---------------------------------------------------------------------------
  // Average interval calculation
  // ---------------------------------------------------------------------------

  group('Average interval calculation', () {
    test('average interval calculated correctly for 4 monthly purchases', () {
      final freq = PurchaseFrequency(
        productId: 'prod-M',
        purchaseDates: [
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 2, 1), // +31 dias
          DateTime.utc(2026, 3, 1), // +28 dias
          DateTime.utc(2026, 4, 1), // +31 dias
        ],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      // Average of (31 + 28 + 31) / 3 = 30.0 days
      expect(result.first.averageIntervalDays, closeTo(30.0, 0.5));
    });

    test('isDue verdadeiro quando daysSinceLast >= averageInterval', () {
      // Product bought monthly, last purchase 40 days ago
      final lastPurchase = now.subtract(const Duration(days: 40));
      final freq = PurchaseFrequency(
        productId: 'prod-due',
        purchaseDates: [
          lastPurchase.subtract(const Duration(days: 90)),
          lastPurchase.subtract(const Duration(days: 60)),
          lastPurchase.subtract(const Duration(days: 30)),
          lastPurchase,
        ],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.isDue, isTrue);
      expect(result.first.daysSinceLastPurchase, 40);
    });

    test('isDue falso quando daysSinceLast < averageInterval', () {
      // Product bought monthly, last purchase 10 days ago
      final lastPurchase = now.subtract(const Duration(days: 10));
      final freq = PurchaseFrequency(
        productId: 'prod-not-due',
        purchaseDates: [
          lastPurchase.subtract(const Duration(days: 90)),
          lastPurchase.subtract(const Duration(days: 60)),
          lastPurchase.subtract(const Duration(days: 30)),
          lastPurchase,
        ],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.first.isDue, isFalse);
      expect(result.first.daysSinceLastPurchase, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // Empty list / empty history cases
  // ---------------------------------------------------------------------------

  group('Casos degenerados', () {
    test('empty history returns empty list', () {
      final result = policy.suggest(history: [], alreadyInList: {}, now: now);

      expect(result, isEmpty);
    });

    test('all products already on list returns empty list', () {
      final history = [
        PurchaseFrequency(
          productId: 'prod-1',
          purchaseDates: [
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
            DateTime.utc(2026, 8, 1),
          ],
        ),
        PurchaseFrequency(
          productId: 'prod-2',
          purchaseDates: [
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
            DateTime.utc(2026, 8, 1),
          ],
        ),
      ];

      final result = policy.suggest(
        history: history,
        alreadyInList: {'prod-1', 'prod-2'},
        now: now,
      );

      expect(result, isEmpty);
    });

    test('out-of-order dates are normalized correctly', () {
      // Dates in random order — should sort internally
      final freq = PurchaseFrequency(
        productId: 'prod-unordered',
        purchaseDates: [
          DateTime.utc(2026, 3, 1),
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 2, 1),
        ],
      );

      final result = policy.suggest(
        history: [freq],
        alreadyInList: {},
        now: now,
      );

      expect(result, hasLength(1));
      // daysSinceLast deve ser contado a partir de 1/mar (a data mais recente)
      final daysSinceMarch = now.difference(DateTime.utc(2026, 3, 1)).inDays;
      expect(result.first.daysSinceLastPurchase, daysSinceMarch);
    });

    test('limit zero retorna lista vazia', () {
      final history = [
        PurchaseFrequency(
          productId: 'prod-1',
          purchaseDates: [
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
            DateTime.utc(2026, 8, 1),
          ],
        ),
      ];

      final result = policy.suggest(
        history: history,
        alreadyInList: {},
        now: now,
        limit: 0,
      );

      expect(result, isEmpty);
    });
  });
}
