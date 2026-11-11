/// Representation of quantities with explicit units.
///
/// All quantities in the application MUST use [Quantity] (RN-003).
/// Conversion between units of **different dimensions** is forbidden at
/// compile-time (via [Dimension]) and at runtime (throws ArgumentError).
library;

import 'package:my_sweet_home/core/money/money.dart';

// ---------------------------------------------------------------------------
// Dimensions and units
// ---------------------------------------------------------------------------

/// Supported physical dimensions.
enum Dimension {
  /// Countable items (units, packs, etc.)
  count,

  /// Mass (grams, kilograms)
  mass,

  /// Volume (milliliters, liters)
  volume,
}

/// Measurement units with conversion factors to the dimension's base unit.
///
/// Base unit for each dimension:
///   - [count] → [Unit.un] (1)
///   - [mass]  → [Unit.g]  (1 g)
///   - [volume] → [Unit.ml] (1 ml)
enum Unit {
  /// Unit / item / piece (dimensionless)
  un(Dimension.count, 1),

  /// Pack (counts as 1 unit for price comparison)
  pack(Dimension.count, 1),

  /// Gram — base unit of mass
  g(Dimension.mass, 1),

  /// Kilogram = 1000 g
  kg(Dimension.mass, 1000),

  /// Milliliter — base unit of volume
  ml(Dimension.volume, 1),

  /// Liter = 1000 ml
  l(Dimension.volume, 1000);

  const Unit(this.dimension, this.milliPerUnit);

  /// Dimension of this unit.
  final Dimension dimension;

  /// Number of thousandths of the base unit in **one** unit of this.
  ///
  /// E.g.: `Unit.kg.milliPerUnit = 1000` → 1 kg = 1000 g-base.
  final int milliPerUnit;
}

// ---------------------------------------------------------------------------
// Quantity
// ---------------------------------------------------------------------------

/// Quantity with value in thousandths of the given unit and explicit unit.
///
/// Stored internally as `valueMilli` (thousandths of the SUPPLIED unit),
/// not the base unit — preserving user input precision.
///
/// Example: `Quantity(1500, Unit.g)` = 1.5 kg = 1500 g.
final class Quantity {
  const Quantity(this.valueMilli, this.unit);

  /// Value in thousandths of the supplied [unit].
  ///
  /// E.g.: for `Quantity(1500, Unit.g)`, `valueMilli = 1500` → 1.5 g
  /// (i.e. real value in g is `valueMilli / 1000 = 1.5`).
  final int valueMilli;

  /// Measurement unit for this quantity.
  final Unit unit;

  // -------------------------------------------------------------------------
  // Unit conversion
  // -------------------------------------------------------------------------

  /// Converts to [target] unit.
  ///
  /// Throws [ArgumentError] if [target] has a different dimension than [unit]
  /// (RN-003 — conversion across dimensions is forbidden).
  Quantity convertTo(Unit target) {
    if (unit.dimension != target.dimension) {
      throw ArgumentError(
        'Cannot convert ${unit.name} (${unit.dimension.name}) '
        'to ${target.name} (${target.dimension.name}): incompatible dimensions.',
      );
    }
    if (unit == target) return this;

    // Value in thousandths of the BASE unit
    final baseValueMilli = valueMilli * unit.milliPerUnit;

    // Value in thousandths of [target] unit
    final targetValueMilli = baseValueMilli ~/ target.milliPerUnit;

    return Quantity(targetValueMilli, target);
  }

  /// Real value (without thousandths) as [double] — for display only.
  double get displayValue => valueMilli / 1000.0;

  // -------------------------------------------------------------------------
  // Unit price (used by price_points — RF-032)
  // -------------------------------------------------------------------------

  /// Computes the price per **base unit** of the dimension given total paid [total].
  ///
  /// Example: `Quantity(2000, Unit.g).unitPriceFor(Money(1000))` → price/g.
  ///
  /// Returns `Money.zero` if the quantity is zero.
  Money unitPriceFor(Money total) {
    if (valueMilli == 0) return Money.zero;

    // Total in cents × 1000 ÷ value in base thousandths = cents/base-unit
    final baseValueMilli = valueMilli * unit.milliPerUnit;
    return Money((total.cents * 1000 ~/ baseValueMilli));
  }

  // -------------------------------------------------------------------------
  // Equality and comparison
  // -------------------------------------------------------------------------

  /// Semantic equality: converts both to the base unit before comparing.
  ///
  /// `Quantity(1000, Unit.g) == Quantity(1, Unit.kg)` → `true`.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Quantity) return false;
    if (unit.dimension != other.unit.dimension) return false;
    // Compares in thousandths of the base unit
    return valueMilli * unit.milliPerUnit ==
        other.valueMilli * other.unit.milliPerUnit;
  }

  /// Addition of quantities with the same dimension
  Quantity operator +(Quantity other) {
    if (unit.dimension != other.unit.dimension) {
      throw ArgumentError('Cannot add quantities with different dimensions.');
    }
    final convertedOther = other.convertTo(unit);
    return Quantity(valueMilli + convertedOther.valueMilli, unit);
  }

  /// Subtraction of quantities with the same dimension
  Quantity operator -(Quantity other) {
    if (unit.dimension != other.unit.dimension) {
      throw ArgumentError(
        'Cannot subtract quantities with different dimensions.',
      );
    }
    final convertedOther = other.convertTo(unit);
    return Quantity(valueMilli - convertedOther.valueMilli, unit);
  }

  @override
  int get hashCode =>
      Object.hash(unit.dimension, valueMilli * unit.milliPerUnit);

  @override
  String toString() => 'Quantity($valueMilli, ${unit.name})';

  Map<String, dynamic> toJson() {
    return {'valueMilli': valueMilli, 'unit': unit.name};
  }

  factory Quantity.fromJson(Map<String, dynamic> json) {
    return Quantity(
      json['valueMilli'] as int,
      Unit.values.firstWhere((e) => e.name == json['unit']),
    );
  }
}
