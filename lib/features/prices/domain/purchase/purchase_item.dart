import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';

/// Item de compra (RN-051).
final class PurchaseItem {
  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.rawDescription = '',
  });

  /// Unique item identifier.
  final String id;

  /// Produto associado.
  final String productId;

  /// Original item description on receipt/purchase.
  final String rawDescription;

  /// Quantidade (inclui unidade).
  final Quantity quantity;

  /// Price per 1 reported unit (e.g. price per 1 kg, price per 1 package).
  final Money unitPrice;

  /// Total item price reported on receipt.
  final Money totalPrice;

  /// Validates whether total matches quantity * unit price, with
  /// tolerance of 1 cent (RN-051).
  bool get hasValidTotal {
    // valueMilli is in thousandths of reported unit. Therefore, we divide by 1000.
    final expected = unitPrice.timesRatio(quantity.valueMilli, 1000);
    final diff = (expected.cents - totalPrice.cents).abs();
    return diff <= 1;
  }
}
