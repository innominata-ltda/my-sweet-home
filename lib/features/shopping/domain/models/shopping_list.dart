import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';

class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.storeId,
    this.isArchived = false,
    this.items = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? storeId;
  final bool isArchived;
  final List<ShoppingItem> items;

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? storeId,
    bool? isArchived,
    List<ShoppingItem>? items,
    bool clearStoreId = false,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      storeId: clearStoreId ? null : (storeId ?? this.storeId),
      isArchived: isArchived ?? this.isArchived,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShoppingList) return false;

    if (other.id != id ||
        other.name != name ||
        other.createdAt != createdAt ||
        other.storeId != storeId ||
        other.isArchived != isArchived ||
        other.items.length != items.length) {
      return false;
    }

    for (int i = 0; i < items.length; i++) {
      if (other.items[i] != items[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      createdAt,
      storeId,
      isArchived,
      Object.hashAll(items),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'storeId': storeId,
      'isArchived': isArchived,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      storeId: json['storeId'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
