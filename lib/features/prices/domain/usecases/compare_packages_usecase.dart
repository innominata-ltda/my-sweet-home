import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';

/// Define a entrada para comparar embalagens.
final class PackageInput {
  const PackageInput({
    required this.id,
    required this.price,
    required this.quantity,
  });

  /// Identifier to distinguish entries (can be "A", "B", etc.)
  final String id;

  /// Package price
  final Money price;

  /// Quantidade da embalagem
  final Quantity quantity;
}

/// Define o resultado de uma embalagem comparada.
final class ComparedPackage {
  const ComparedPackage({
    required this.id,
    required this.price,
    required this.quantity,
    required this.normalizedPrice,
    required this.normalizedUnit,
    required this.isCheapest,
  });

  final String id;
  final Money price;
  final Quantity quantity;

  /// Calculated price in normalized base unit (kg, L, un).
  final Money normalizedPrice;

  /// Base unit for normalization (kg, L, un).
  final Unit normalizedUnit;

  /// Whether this package is the cheapest (ties possible).
  final bool isCheapest;
}

/// Use case that compares packages by calculating price per base unit.
///
/// Reflects RN-053 (comparison by R$/kg, R$/L, etc.) and
/// RN-054 (different dimensions yield error).
final class ComparePackagesUseCase {
  const ComparePackagesUseCase();

  Result<List<ComparedPackage>, Failure> call(List<PackageInput> packages) {
    if (packages.isEmpty) {
      return const Ok<List<ComparedPackage>, Failure>([]);
    }

    // Verifies whether all have same dimension (RN-054)
    final referenceDimension = packages.first.quantity.unit.dimension;
    for (final package in packages) {
      if (package.quantity.unit.dimension != referenceDimension) {
        return const Err<List<ComparedPackage>, Failure>(
          ValidationFailure(
            fields: {
              'dimension': 'Dimensões diferentes não podem ser comparadas',
            },
          ),
        );
      }
    }

    // Defines normalization unit (kg for mass, L for volume, un for count)
    final Unit normalizedUnit = switch (referenceDimension) {
      Dimension.mass => Unit.kg,
      Dimension.volume => Unit.l,
      Dimension.count => Unit.un,
    };

    // Calculates normalized prices (R$/kg, R$/L, etc.) - RN-053
    final normalizedPrices = packages.map((p) {
      final baseValueMilli =
          p.quantity.valueMilli * p.quantity.unit.milliPerUnit;
      if (baseValueMilli == 0) return Money.zero;

      final normalizedUnitMilli = normalizedUnit.milliPerUnit * 1000;
      return Money((p.price.cents * normalizedUnitMilli) ~/ baseValueMilli);
    }).toList();

    // Finds lowest normalized price (ignoring zeroes from packages without quantity)
    Money? minNormalizedPrice;
    for (final np in normalizedPrices) {
      if (np.cents > 0) {
        if (minNormalizedPrice == null || np.cents < minNormalizedPrice.cents) {
          minNormalizedPrice = np;
        }
      }
    }

    final comparedPackages = <ComparedPackage>[];
    for (var i = 0; i < packages.length; i++) {
      final p = packages[i];
      final np = normalizedPrices[i];
      comparedPackages.add(
        ComparedPackage(
          id: p.id,
          price: p.price,
          quantity: p.quantity,
          normalizedPrice: np,
          normalizedUnit: normalizedUnit,
          isCheapest:
              minNormalizedPrice != null &&
              np.cents == minNormalizedPrice.cents,
        ),
      );
    }

    return Ok<List<ComparedPackage>, Failure>(comparedPackages);
  }
}
