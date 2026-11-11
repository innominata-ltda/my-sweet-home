import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';

/// Receipt item extracted by OCR before confirmation on review screen.
final class ReceiptItemDraft {
  /// Minimum OCR confidence threshold (0.6 or 60%).
  ///
  /// RN-195: Items below this threshold are unchecked (false) by default in review.
  static const double minConfidenceThreshold = 0.6;

  /// Original product description as read from receipt.
  final String rawDescription;

  /// Barcode EAN / GTIN code (optional).
  final String? ean;

  /// Extracted quantity and unit of measurement.
  final Quantity quantity;

  /// Unit value per item or per unit of measure (e.g. R$ 39.90/kg).
  final Money unitPrice;

  /// Valor total final pago pelo item.
  final Money totalPrice;

  /// Mean OCR confidence for this item (0.0 to 1.0).
  final double confidence;

  /// Link with canonical product (populated in T-10 by ProductMatcher).
  final ProductMatch? match;

  /// Whether item is selected for saving.
  ///
  /// RN-195: items with confidence < 0.6 are unchecked (false) by default.
  final bool selected;

  /// Indicates if item has low OCR confidence (< 0.6) (RN-195, CA-3.1).
  bool get isLowConfidence => confidence < minConfidenceThreshold;

  ReceiptItemDraft({
    required this.rawDescription,
    this.ean,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.confidence,
    this.match,
    bool? selected,
  }) : selected = selected ?? (confidence >= minConfidenceThreshold);

  ReceiptItemDraft copyWith({
    String? rawDescription,
    String? ean,
    Quantity? quantity,
    Money? unitPrice,
    Money? totalPrice,
    double? confidence,
    ProductMatch? match,
    bool clearMatch = false,
    bool? selected,
  }) {
    return ReceiptItemDraft(
      rawDescription: rawDescription ?? this.rawDescription,
      ean: ean ?? this.ean,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      confidence: confidence ?? this.confidence,
      match: clearMatch ? null : (match ?? this.match),
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() => {
    'rawDescription': rawDescription,
    if (ean != null) 'ean': ean,
    'quantity': quantity.toJson(),
    'unitPrice': unitPrice.cents,
    'totalPrice': totalPrice.cents,
    'confidence': confidence,
    'selected': selected,
  };

  factory ReceiptItemDraft.fromJson(Map<String, dynamic> json) {
    final conf = (json['confidence'] as num?)?.toDouble() ?? 1.0;
    return ReceiptItemDraft(
      rawDescription: json['rawDescription'] as String? ?? '',
      ean: json['ean'] as String?,
      quantity: Quantity.fromJson(json['quantity'] as Map<String, dynamic>),
      unitPrice: Money(json['unitPrice'] as int? ?? 0),
      totalPrice: Money(json['totalPrice'] as int? ?? 0),
      confidence: conf,
      selected: json['selected'] as bool? ?? (conf >= minConfidenceThreshold),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemDraft &&
          runtimeType == other.runtimeType &&
          rawDescription == other.rawDescription &&
          ean == other.ean &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          totalPrice == other.totalPrice &&
          confidence == other.confidence &&
          match == other.match &&
          selected == other.selected;

  @override
  int get hashCode => Object.hash(
    rawDescription,
    ean,
    quantity,
    unitPrice,
    totalPrice,
    confidence,
    match,
    selected,
  );

  @override
  String toString() =>
      'ReceiptItemDraft("$rawDescription", ean: $ean, qty: $quantity, '
      'unitPrice: ${unitPrice.cents}, totalPrice: ${totalPrice.cents}, '
      'conf: ${confidence.toStringAsFixed(2)}, selected: $selected)';
}
