library;

import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/stock_consumption_estimate.dart';
import 'package:my_sweet_home/features/extras/domain/stock_item.dart';

/// Contract of the household stock repository (RF-101, RN-251).
abstract interface class StockRepository {
  /// Registra ou atualiza a quantidade aproximada de um produto no estoque.
  Future<Result<StockItem, Failure>> upsertStockItem({
    String? id,
    required String productId,
    required Quantity quantity,
    Quantity? lowStockThreshold,
    DateTime? lastRestockedAt,
  });

  /// Busca o item de estoque por produto.
  Future<Result<StockItem?, Failure>> getStockItemByProductId(String productId);

  /// Lists all items in household stock.
  Future<Result<List<StockItem>, Failure>> getStockItems();

  /// Remove um item do estoque.
  Future<Result<void, Failure>> deleteStockItem(String id);

  /// Calculates product consumption estimate based on purchase history.
  ///
  /// Se houver menos de 3 compras, retorna `hasEnoughHistory == false` e sem
  /// valores de estimativa (RN-251, CA-2.2).
  Future<Result<StockConsumptionEstimate, Failure>> getConsumptionEstimate(
    String productId,
  );
}
