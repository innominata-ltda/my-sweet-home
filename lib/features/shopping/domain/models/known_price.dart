import 'package:my_sweet_home/core/money/money.dart';

/// Latest known price of a product, in total money for quantity
/// of item (non-normalized), with store where it was recorded.
///
/// Usado por [EstimatePolicy] para construir a estimativa da lista (RN-083).
final class KnownPrice {
  const KnownPrice({
    required this.price,
    required this.recordedAt,
    required this.storeId,
  });

  /// Price in integer cents (RN-001 — never double).
  final Money price;

  /// Record date, used to display "price of Month Day".
  final DateTime recordedAt;

  /// Store where price was recorded.
  final String storeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnownPrice &&
          other.price == price &&
          other.recordedAt == recordedAt &&
          other.storeId == storeId;

  @override
  int get hashCode => Object.hash(price, recordedAt, storeId);

  @override
  String toString() =>
      'KnownPrice(price: ${price.formatPtBr()}, storeId: $storeId, recordedAt: $recordedAt)';
}
