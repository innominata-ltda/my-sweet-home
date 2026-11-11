library;

import 'package:my_sweet_home/core/quantity/quantity.dart';

/// Household stock item with approximate quantity per product (RF-101).
final class StockItem {
  const StockItem({
    required this.id,
    required this.productId,
    required this.quantity,
    this.lowStockThreshold,
    this.lastRestockedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final Quantity quantity;
  final Quantity? lowStockThreshold;
  final DateTime? lastRestockedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockItem copyWith({
    String? id,
    String? productId,
    Quantity? quantity,
    Quantity? lowStockThreshold,
    DateTime? lastRestockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItem &&
        other.id == id &&
        other.productId == productId &&
        other.quantity == quantity &&
        other.lowStockThreshold == lowStockThreshold &&
        other.lastRestockedAt == lastRestockedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, quantity, lowStockThreshold, lastRestockedAt);
}
