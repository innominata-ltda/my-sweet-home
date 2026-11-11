import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';

typedef ProductId = String;

/// Known normalized price of a product, extracted from price history.
///
/// [normalizedPrice] is price per [normalizedUnit] (e.g. R$/kg, R$/l, R$/un).
/// [date] is date of latest observed record.
final class KnownPrice {
  const KnownPrice({
    required this.normalizedPrice,
    required this.normalizedUnit,
    required this.date,
  });

  final Money normalizedPrice;

  /// Normalization unit — same convention as [PricePoint.unit].
  final Unit normalizedUnit;

  final DateTime date;
}

// ---------------------------------------------------------------------------
// RecipeCost — resultado selado (RN-175)
// ---------------------------------------------------------------------------

sealed class RecipeCost {
  const RecipeCost();
}

/// Could not estimate: over 30% of ingredients lack price (RN-175).
final class CostUnknown extends RecipeCost {
  const CostUnknown({required this.missing, required this.total});

  /// Ingredients without known price.
  final int missing;

  /// Total scalable ingredients evaluated.
  final int total;
}

/// Estimated cost with possible gaps (RN-175).
final class CostEstimated extends RecipeCost {
  const CostEstimated({
    required this.total,
    required this.missing,
    required this.oldestPriceUsed,
  });

  /// Sum of costs of ingredients with price.
  final Money total;

  /// Scalable ingredients without known price.
  final int missing;

  /// Date of oldest price used in calculation.
  final DateTime oldestPriceUsed;
}

// ---------------------------------------------------------------------------
// RecipeCostPolicy — interface pura
// ---------------------------------------------------------------------------

/// Estimates cost of a recipe based on known prices (PURE, RN-175).
///
/// Only uses [ScaledIngredient]s having [productId] and [exact] (have quantity
/// and product link). Ingredients without quantity ("salt to taste") are
/// ignorados no denominador de cobertura.
abstract interface class RecipeCostPolicy {
  RecipeCost estimate({
    required List<ScaledIngredient> ingredients,
    required Map<ProductId, KnownPrice> lastPrices,
  });
}

// ---------------------------------------------------------------------------
// StandardRecipeCostPolicy — default implementation
// ---------------------------------------------------------------------------

/// Default implementation of [RecipeCostPolicy].
///
/// Regra do 30%: se `missing / scalableWithProduct > 0.30`, retorna
/// [CostUnknown]. Otherwise, [CostEstimated] with total of available
/// prices and [missing] indicating how many lacked a price.
///
/// Cost calculation per ingredient:
/// ```
/// cost = normalizedPrice * (valueMilli * unit.milliPerUnit)
///                        / (normalizedUnit.milliPerUnit * 1 000 000)
/// ```
/// This converts ingredient quantity into normalized unit
/// (kg, l or un) and multiplies by normalized price.
final class StandardRecipeCostPolicy implements RecipeCostPolicy {
  const StandardRecipeCostPolicy();

  static const double _unknownThreshold = 0.30;

  @override
  RecipeCost estimate({
    required List<ScaledIngredient> ingredients,
    required Map<ProductId, KnownPrice> lastPrices,
  }) {
    // Only ingredients that have quantity AND product link participate.
    final candidates = ingredients
        .where((i) => i.isScalable && i.source.productId != null)
        .toList();

    final total = candidates.length;

    if (total == 0) {
      // Sem nenhum ingrediente vinculado — desconhecido total.
      return const CostUnknown(missing: 0, total: 0);
    }

    int missing = 0;
    Money sum = Money.zero;
    DateTime? oldest;

    for (final scaled in candidates) {
      final productId = scaled.source.productId!;
      final knownPrice = lastPrices[productId];

      if (knownPrice == null || scaled.exact == null) {
        missing++;
        continue;
      }

      final qty = scaled.exact!;
      if (qty.unit.dimension != knownPrice.normalizedUnit.dimension) {
        // Incompatible dimensions — do not sum, count as missing.
        missing++;
        continue;
      }

      // Cost = normalized_price * (qty in normalized unit)
      // qty in normalized unit = (valueMilli * unit.milliPerUnit) / (normalizedUnit.milliPerUnit * 1000)
      // Factor 1000 is because milliPerUnit is in thousandths of base unit,
      // but valueMilli is already in thousandths of declared unit.
      //
      // Ex.: 500g = valueMilli=500000, unit.milliPerUnit=1, normalizedUnit(kg).milliPerUnit=1000
      // numerator  = 500000 * 1      = 500000
      // denominator= 1000  * 1000    = 1000000   ->  ratio = 0.5 kg
      // cost = R$8.00/kg * 0.5 = R$4.00
      final numerator = qty.valueMilli * qty.unit.milliPerUnit;
      final denominator = knownPrice.normalizedUnit.milliPerUnit * 1000;

      if (denominator == 0) {
        missing++;
        continue;
      }

      sum = sum + knownPrice.normalizedPrice.timesRatio(numerator, denominator);

      if (oldest == null || knownPrice.date.isBefore(oldest)) {
        oldest = knownPrice.date;
      }
    }

    final missingRatio = total > 0 ? missing / total : 0.0;

    if (missingRatio > _unknownThreshold) {
      return CostUnknown(missing: missing, total: total);
    }

    return CostEstimated(
      total: sum,
      missing: missing,
      oldestPriceUsed: oldest ?? DateTime.utc(1970),
    );
  }
}
