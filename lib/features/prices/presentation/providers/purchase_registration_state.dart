import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

class InitialPurchaseItemDraft {
  const InitialPurchaseItemDraft({
    this.productId,
    required this.name,
    this.quantity,
  });

  final String? productId;
  final String name;
  final Quantity? quantity;
}

class DraftPurchaseItem {
  const DraftPurchaseItem({
    required this.id,
    this.product,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  final String id;
  final Product? product;
  final Quantity? quantity;
  final Money? unitPrice;
  final Money? totalPrice;

  bool get isValid =>
      product != null &&
      quantity != null &&
      unitPrice != null &&
      totalPrice != null;

  DraftPurchaseItem copyWith({
    Product? product,
    Quantity? quantity,
    Money? unitPrice,
    Money? totalPrice,
  }) {
    return DraftPurchaseItem(
      id: id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class PurchaseRegistrationState {
  const PurchaseRegistrationState({
    this.store,
    required this.date,
    this.items = const [],
    this.totalAmount = Money.zero,
    this.discountAmount = Money.zero,
    this.isSaving = false,
    this.error,
  });

  final Store? store;
  final DateTime date;
  final List<DraftPurchaseItem> items;
  final Money totalAmount;
  final Money discountAmount;
  final bool isSaving;
  final String? error;

  Money get expectedTotal {
    final sum = items.fold(
      Money.zero,
      (acc, item) => acc + (item.totalPrice ?? Money.zero),
    );
    return sum - discountAmount;
  }

  Money get divergence {
    return Money((totalAmount.cents - expectedTotal.cents).abs());
  }

  bool get hasDivergence => expectedTotal.cents != totalAmount.cents;

  bool get isValid {
    if (store == null) return false;
    if (items.isEmpty) return false;
    if (items.any((item) => !item.isValid)) return false;
    return true;
  }

  PurchaseRegistrationState copyWith({
    Store? store,
    DateTime? date,
    List<DraftPurchaseItem>? items,
    Money? totalAmount,
    Money? discountAmount,
    bool? isSaving,
    String? error,
  }) {
    return PurchaseRegistrationState(
      store: store ?? this.store,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      isSaving: isSaving ?? this.isSaving,
      error: error, // Can be set to null explicitly if we don't pass it, but maybe better to do error: error ?? this.error (but how to clear?) Let's assume we pass error explicitly or use a trick.
    );
  }

  PurchaseRegistrationState clearError() {
    return PurchaseRegistrationState(
      store: store,
      date: date,
      items: items,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      isSaving: isSaving,
    );
  }
}
