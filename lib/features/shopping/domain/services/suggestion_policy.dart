/// Suggestion policy based on user's own purchase recurrence
/// (RF-054, RN-085, CA-7.1).
///
/// **PURE** — no I/O, no catalog, no network dependency.
/// Injectable with [FakeClock] in tests.
library;

// ---------------------------------------------------------------------------
// Suggestion-specific domain models
// ---------------------------------------------------------------------------

/// Product purchase frequency observed in user history.
///
/// Each instance represents a product and all dates when it was
/// comprado (uma compra = um item de uma [Purchase]).
final class PurchaseFrequency {
  const PurchaseFrequency({
    required this.productId,
    required this.purchaseDates,
  });

  /// Identificador do produto (= [PurchaseItem.productId]).
  final String productId;

  /// Dates of purchases where product appeared, in chronological order (UTC).
  /// MUST have at least 3 entries for product to be eligible (RN-085).
  final List<DateTime> purchaseDates;
}

/// Item suggestion to add to list.
final class Suggestion {
  const Suggestion({
    required this.productId,
    required this.averageIntervalDays,
    required this.daysSinceLastPurchase,
  });

  /// Produto sugerido.
  final String productId;

  /// Average interval between consecutive purchases, in days.
  final double averageIntervalDays;

  /// Days elapsed since last purchase.
  final int daysSinceLastPurchase;

  /// Indicates if product is "time" to be purchased
  /// (time since last purchase >= average interval).
  bool get isDue => daysSinceLastPurchase >= averageIntervalDays;
}

// ---------------------------------------------------------------------------
// Contract (domain port)
// ---------------------------------------------------------------------------

/// Calculates purchase suggestions from user historical recurrence.
///
/// Implementation MUST be pure: no I/O, no global state,
/// deterministic result given same set of inputs.
abstract interface class SuggestionPolicy {
  /// Returns up to [limit] suggestions ordered by descending urgency
  /// (maior `daysSinceLastPurchase / averageIntervalDays` primeiro).
  ///
  /// Regras (RN-085):
  /// - Only considers products with `purchaseDates.length >= 3`.
  /// - Nunca inclui produto cujo ID esteja em [alreadyInList].
  List<Suggestion> suggest({
    required List<PurchaseFrequency> history,
    required Set<String> alreadyInList,
    required DateTime now,
    int limit = 5,
  });
}

// ---------------------------------------------------------------------------
// Default implementation (pure, testable, without DateTime.now())
// ---------------------------------------------------------------------------

/// Default implementation of [SuggestionPolicy].
///
/// Algoritmo:
/// 1. Filtra produtos com menos de 3 compras.
/// 2. Filters out products already present in list.
/// 3. For each eligible product, calculates average interval between purchases
///    consecutivas (em dias), usando apenas as datas fornecidas.
/// 4. Ordena por `daysSinceLastPurchase / averageIntervalDays` decrescente
///    (quanto mais "atrasado", mais urgente).
/// 5. Retorna os primeiros [limit] resultados.
final class DefaultSuggestionPolicy implements SuggestionPolicy {
  const DefaultSuggestionPolicy();

  @override
  List<Suggestion> suggest({
    required List<PurchaseFrequency> history,
    required Set<String> alreadyInList,
    required DateTime now,
    int limit = 5,
  }) {
    final candidates = <Suggestion>[];

    for (final freq in history) {
      // RN-085: minimum of 3 purchases
      if (freq.purchaseDates.length < 3) continue;

      // RN-085: do not suggest product already in list
      if (alreadyInList.contains(freq.productId)) continue;

      final sorted = List<DateTime>.from(freq.purchaseDates)
        ..sort((a, b) => a.compareTo(b));

      final avgInterval = _averageIntervalDays(sorted);
      if (avgInterval <= 0) continue;

      final lastPurchase = sorted.last;
      final daysSinceLast = now.difference(lastPurchase).inDays;

      candidates.add(
        Suggestion(
          productId: freq.productId,
          averageIntervalDays: avgInterval,
          daysSinceLastPurchase: daysSinceLast,
        ),
      );
    }

    // Sort by urgency: higher daysSinceLast / avgInterval means more urgent
    candidates.sort((a, b) {
      final urgencyA = a.daysSinceLastPurchase / a.averageIntervalDays;
      final urgencyB = b.daysSinceLastPurchase / b.averageIntervalDays;
      return urgencyB.compareTo(urgencyA); // decrescente
    });

    return candidates.take(limit).toList();
  }

  /// Calculates average interval in days between consecutive purchases.
  double _averageIntervalDays(List<DateTime> sortedDates) {
    if (sortedDates.length < 2) return 0;

    double totalDays = 0;
    for (int i = 1; i < sortedDates.length; i++) {
      totalDays += sortedDates[i].difference(sortedDates[i - 1]).inDays;
    }

    return totalDays / (sortedDates.length - 1);
  }
}
