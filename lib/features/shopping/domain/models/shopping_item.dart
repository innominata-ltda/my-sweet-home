import 'package:my_sweet_home/core/quantity/quantity.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.rawText,
    required this.parsedName,
    this.parsedQuantity,
    this.productId,
    this.boughtAt,
  });

  final String id;
  final String rawText;
  final String parsedName;
  final Quantity? parsedQuantity;
  final String? productId;
  final DateTime? boughtAt;

  bool get isBought => boughtAt != null;

  ShoppingItem copyWith({
    String? id,
    String? rawText,
    String? parsedName,
    Quantity? parsedQuantity,
    String? productId,
    DateTime? boughtAt,
    bool clearBoughtAt = false,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      parsedName: parsedName ?? this.parsedName,
      parsedQuantity: parsedQuantity ?? this.parsedQuantity,
      productId: productId ?? this.productId,
      boughtAt: clearBoughtAt ? null : (boughtAt ?? this.boughtAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShoppingItem &&
        other.id == id &&
        other.rawText == rawText &&
        other.parsedName == parsedName &&
        other.parsedQuantity == parsedQuantity &&
        other.productId == productId &&
        other.boughtAt == boughtAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      rawText,
      parsedName,
      parsedQuantity,
      productId,
      boughtAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawText': rawText,
      'parsedName': parsedName,
      'parsedQuantity': parsedQuantity?.toJson(),
      'productId': productId,
      'boughtAt': boughtAt?.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      rawText: json['rawText'] as String,
      parsedName: json['parsedName'] as String,
      parsedQuantity: json['parsedQuantity'] != null
          ? Quantity.fromJson(json['parsedQuantity'] as Map<String, dynamic>)
          : null,
      productId: json['productId'] as String?,
      boughtAt: json['boughtAt'] != null
          ? DateTime.parse(json['boughtAt'] as String)
          : null,
    );
  }
}
