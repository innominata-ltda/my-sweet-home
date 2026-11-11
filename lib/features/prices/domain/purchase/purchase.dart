import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';

/// Representation of a purchase (RN-050).
final class Purchase {
  const Purchase({
    required this.id,
    required this.storeId,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
  });

  /// Unique purchase identifier.
  final String id;

  /// Estabelecimento onde a compra foi feita.
  final String storeId;

  /// Data da compra.
  final DateTime date;

  /// Itens da compra. DEVE ter ao menos um item (RN-050).
  final List<PurchaseItem> items;

  /// Valor total pago/declarado na compra.
  final Money totalAmount;

  /// Desconto total aplicado na compra inteira.
  final Money discountAmount;

  /// Returns expected value of sum of items minus discounts.
  Money get expectedTotal {
    final sum = items.fold(Money.zero, (acc, item) => acc + item.totalPrice);
    return sum - discountAmount;
  }

  /// Difference between reported and calculated total.
  Money get divergence {
    return Money((totalAmount.cents - expectedTotal.cents).abs());
  }

  /// Checks whether totals diverge.
  bool get hasDivergence => expectedTotal.cents != totalAmount.cents;

  /// Validates whether purchase meets basic business rules (RN-050).
  bool get isValid => items.isNotEmpty;
}
