import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/store_draft.dart';

export 'package:my_sweet_home/features/ocr/domain/models/store_draft.dart';

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Complete receipt draft extracted by OCR.
final class ReceiptDraft {
  final StoreDraft store;
  final DateTime? purchasedAt;
  final String? accessKey;
  final List<ReceiptItemDraft> items;
  final Money? subtotal;
  final Money? discount;
  final Money? total;
  final String? paymentMethod;
  final double confidence;

  ReceiptDraft({
    required this.store,
    this.purchasedAt,
    this.accessKey,
    required this.items,
    this.subtotal,
    this.discount,
    this.total,
    this.paymentMethod,
    required this.confidence,
  });

  ReceiptDraft copyWith({
    StoreDraft? store,
    DateTime? purchasedAt,
    String? accessKey,
    List<ReceiptItemDraft>? items,
    Money? subtotal,
    Money? discount,
    Money? total,
    String? paymentMethod,
    double? confidence,
    bool clearPurchasedAt = false,
    bool clearAccessKey = false,
    bool clearSubtotal = false,
    bool clearDiscount = false,
    bool clearTotal = false,
    bool clearPaymentMethod = false,
  }) {
    return ReceiptDraft(
      store: store ?? this.store,
      purchasedAt: clearPurchasedAt ? null : (purchasedAt ?? this.purchasedAt),
      accessKey: clearAccessKey ? null : (accessKey ?? this.accessKey),
      items: items ?? this.items,
      subtotal: clearSubtotal ? null : (subtotal ?? this.subtotal),
      discount: clearDiscount ? null : (discount ?? this.discount),
      total: clearTotal ? null : (total ?? this.total),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      confidence: confidence ?? this.confidence,
    );
  }

  /// List of items with low OCR confidence (< 0.6) (RN-195).
  List<ReceiptItemDraft> get lowConfidenceItems =>
      items.where((item) => item.isLowConfidence).toList();

  /// Indicates if there are any low-confidence items in receipt (RN-195).
  bool get hasLowConfidenceItems => items.any((item) => item.isLowConfidence);

  /// Count of low-confidence items (RN-195).
  int get lowConfidenceItemsCount =>
      items.where((item) => item.isLowConfidence).length;

  /// Soma dos valores totais dos itens selecionados.
  Money get itemsSum => items
      .where((item) => item.selected)
      .fold(Money.zero, (acc, item) => acc + item.totalPrice);

  /// Discrepancy between item sum (minus discount) and total paid (RN-196).
  ///
  /// `itemsSum - discount - total`. Retorna `null` se [total] for `null`.
  Money? get divergence {
    if (total == null) return null;
    final effDiscount = discount ?? Money.zero;
    return itemsSum - effDiscount - total!;
  }

  /// Absolute discrepancy value (RN-196, CA-4.1). Returns `null` if [total] is `null`.
  Money? get absoluteDivergence {
    final div = divergence;
    if (div == null) return null;
    return Money(div.cents.abs());
  }

  /// Indicates whether any non-zero discrepancy exists between item sum and total.
  bool get hasDivergence => divergence != null && divergence!.cents != 0;

  /// Verifies whether discrepancy exceeds tolerated threshold per selected item (RN-196).
  ///
  /// By default, tolerates up to [maxCentsPerItem] cent(s) per selected item (default: 1 cent/item).
  /// If discrepancy exceeds accumulated tolerance, returns `true`.
  bool isDivergent({int maxCentsPerItem = 1}) {
    final absDiv = absoluteDivergence;
    if (absDiv == null) return false;
    final selectedCount = items.where((item) => item.selected).length;
    final tolerance = selectedCount * maxCentsPerItem;
    return absDiv.cents > tolerance;
  }

  Map<String, dynamic> toJson() => {
    'store': store.toJson(),
    if (purchasedAt != null) 'purchasedAt': purchasedAt!.toIso8601String(),
    if (accessKey != null) 'accessKey': accessKey,
    'items': items.map((e) => e.toJson()).toList(),
    if (subtotal != null) 'subtotal': subtotal!.cents,
    if (discount != null) 'discount': discount!.cents,
    if (total != null) 'total': total!.cents,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    'confidence': confidence,
  };

  factory ReceiptDraft.fromJson(Map<String, dynamic> json) {
    return ReceiptDraft(
      store: StoreDraft.fromJson(json['store'] as Map<String, dynamic>),
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.tryParse(json['purchasedAt'] as String)
          : null,
      accessKey: json['accessKey'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ReceiptItemDraft.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtotal: json['subtotal'] != null
          ? Money(json['subtotal'] as int)
          : null,
      discount: json['discount'] != null
          ? Money(json['discount'] as int)
          : null,
      total: json['total'] != null ? Money(json['total'] as int) : null,
      paymentMethod: json['paymentMethod'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptDraft &&
          runtimeType == other.runtimeType &&
          store == other.store &&
          purchasedAt == other.purchasedAt &&
          accessKey == other.accessKey &&
          _listEquals(items, other.items) &&
          subtotal == other.subtotal &&
          discount == other.discount &&
          total == other.total &&
          paymentMethod == other.paymentMethod &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(
    store,
    purchasedAt,
    accessKey,
    Object.hashAll(items),
    subtotal,
    discount,
    total,
    paymentMethod,
    confidence,
  );

  @override
  String toString() =>
      'ReceiptDraft(store: ${store.name}, items: ${items.length}, total: ${total?.cents})';
}
