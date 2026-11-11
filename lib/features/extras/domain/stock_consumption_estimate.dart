library;

/// Estimativa de consumo de um produto no estoque (RN-251, RN-252, CA-2.1, CA-2.2).
final class StockConsumptionEstimate {
  const StockConsumptionEstimate({
    required this.productId,
    required this.purchaseCount,
    required this.hasEnoughHistory,
    this.averageIntervalDays,
    this.estimatedDaysRemaining,
    this.isLowStock = false,
    this.isAlertIssued = false,
  });

  /// ID do produto.
  final String productId;

  /// Number of recorded purchases for the product in history.
  final int purchaseCount;

  /// Indicates if there is sufficient history (minimum 3 purchases, RN-251, CA-2.2).
  ///
  /// If `hasEnoughHistory == false` (e.g. 2 purchases), no estimate is displayed.
  final bool hasEnoughHistory;

  /// Average interval in days between purchases (null if `hasEnoughHistory == false`).
  final double? averageIntervalDays;

  /// Estimativa de dias restantes de estoque (nulo se `hasEnoughHistory == false`).
  final int? estimatedDaysRemaining;

  /// Indicates if product stock is running low (RN-252, CA-2.1).
  final bool isLowStock;

  /// Indicates if the "running low" alert was triggered in this period (RN-252, CA-2.1).
  final bool isAlertIssued;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockConsumptionEstimate &&
        other.productId == productId &&
        other.purchaseCount == purchaseCount &&
        other.hasEnoughHistory == hasEnoughHistory &&
        other.averageIntervalDays == averageIntervalDays &&
        other.estimatedDaysRemaining == estimatedDaysRemaining &&
        other.isLowStock == isLowStock &&
        other.isAlertIssued == isAlertIssued;
  }

  @override
  int get hashCode => Object.hash(
    productId,
    purchaseCount,
    hasEnoughHistory,
    averageIntervalDays,
    estimatedDaysRemaining,
    isLowStock,
    isAlertIssued,
  );
}
