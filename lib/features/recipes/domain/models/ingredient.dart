import 'package:my_sweet_home/core/quantity/quantity.dart';

/// Ingrediente base de uma receita.
final class Ingredient {
  const Ingredient({required this.name, this.quantity, this.productId});

  /// Human-readable ingredient name (e.g. "eggs", "salt to taste", "rice").
  final String name;

  /// Quantidade exata, se houver.
  /// If null, considered an ingredient without exact measurement (e.g. "salt to taste").
  final Quantity? quantity;

  /// ID do produto vinculado, se houver.
  final String? productId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Ingredient) return false;
    return name == other.name &&
        quantity == other.quantity &&
        productId == other.productId;
  }

  @override
  int get hashCode => Object.hash(name, quantity, productId);
}
