import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';

/// Origin of price point.
enum PricePointSource { purchase, manual }

/// Represents a point in price history (RN-052, RN-053).
final class PricePoint {
  const PricePoint({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.date,
    required this.normalizedPrice,
    required this.unit,
    required this.source,
  });

  /// Unique point identifier.
  final String id;

  /// Produto associado.
  final String productId;

  /// Estabelecimento.
  final String storeId;

  /// Data de registro.
  final DateTime date;

  /// Normalized price per [unit].
  final Money normalizedPrice;

  /// Reference unit (e.g. Unit.kg, Unit.l, Unit.un).
  final Unit unit;

  /// Information source (purchase or manual).
  final PricePointSource source;

  /// Gera um [PricePoint] a partir de um [PurchaseItem] e os dados da [Purchase].
  ///
  /// Calculates normalized price (RN-053) converting to standard display
  /// units (kg, l, un).
  factory PricePoint.fromPurchaseItem({
    required String id,
    required String storeId,
    required DateTime date,
    required PurchaseItem item,
  }) {
    final quantity = item.quantity;

    // Defines normalization unit based on dimension.
    final Unit normalizedUnit = switch (quantity.unit.dimension) {
      Dimension.mass => Unit.kg,
      Dimension.volume => Unit.l,
      Dimension.count => Unit.un,
    };

    final baseValueMilli = quantity.valueMilli * quantity.unit.milliPerUnit;
    Money calcNormalizedPrice;
    if (baseValueMilli == 0) {
      calcNormalizedPrice = Money.zero;
    } else {
      final normalizedUnitMilli = normalizedUnit.milliPerUnit * 1000;
      calcNormalizedPrice = Money(
        (item.totalPrice.cents * normalizedUnitMilli) ~/ baseValueMilli,
      );
    }

    return PricePoint(
      id: id,
      productId: item.productId,
      storeId: storeId,
      date: date,
      normalizedPrice: calcNormalizedPrice,
      unit: normalizedUnit,
      source: PricePointSource.purchase,
    );
  }

  /// Gera um [PricePoint] avulso a partir de um registro manual (RN-063).
  factory PricePoint.manual({
    required String id,
    required String productId,
    required String storeId,
    required DateTime date,
    required Money price,
    required Quantity quantity,
  }) {
    final normalizedUnit = switch (quantity.unit.dimension) {
      Dimension.mass => Unit.kg,
      Dimension.volume => Unit.l,
      Dimension.count => Unit.un,
    };

    final baseValueMilli = quantity.valueMilli * quantity.unit.milliPerUnit;
    Money calcNormalizedPrice;
    if (baseValueMilli == 0) {
      calcNormalizedPrice = Money.zero;
    } else {
      final normalizedUnitMilli = normalizedUnit.milliPerUnit * 1000;
      calcNormalizedPrice = Money(
        (price.cents * normalizedUnitMilli) ~/ baseValueMilli,
      );
    }

    return PricePoint(
      id: id,
      productId: productId,
      storeId: storeId,
      date: date,
      normalizedPrice: calcNormalizedPrice,
      unit: normalizedUnit,
      source: PricePointSource.manual,
    );
  }
}
