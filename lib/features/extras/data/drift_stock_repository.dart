library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/extras/domain/stock_consumption_estimate.dart';
import 'package:my_sweet_home/features/extras/domain/stock_item.dart';
import 'package:my_sweet_home/features/extras/domain/stock_repository.dart';

class DriftStockRepository implements StockRepository {
  DriftStockRepository(this._db, this._idGen, this._clock);

  final db.AppDatabase _db;
  final IdGenerator _idGen;
  final Clock _clock;
  static final Map<String, DateTime> _lastAlertedDateByProductId = {};

  @visibleForTesting
  static void clearAlertHistory() => _lastAlertedDateByProductId.clear();

  @override
  Future<Result<StockItem, Failure>> upsertStockItem({
    String? id,
    required String productId,
    required Quantity quantity,
    Quantity? lowStockThreshold,
    DateTime? lastRestockedAt,
  }) async {
    try {
      return await _db.transaction(() async {
        final now = _clock.nowUtc().toIso8601String();

        // Check if item already exists for this productId if ID was not provided
        final existing = await (_db.select(
          _db.stockItems,
        )..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();

        final itemId = id ?? existing?.id ?? _idGen.newId();
        final restockedStr =
            lastRestockedAt?.toIso8601String() ??
            existing?.lastRestockedAt ??
            now;
        final createdStr = existing?.createdAt ?? now;

        await _db
            .into(_db.stockItems)
            .insertOnConflictUpdate(
              db.StockItemsCompanion(
                id: Value(itemId),
                productId: Value(productId),
                quantityMilli: Value(quantity.valueMilli),
                unit: Value(quantity.unit.name),
                lowStockThresholdMilli: Value(lowStockThreshold?.valueMilli),
                lastRestockedAt: Value(restockedStr),
                createdAt: Value(createdStr),
                updatedAt: Value(now),
              ),
            );

        final updatedItem = StockItem(
          id: itemId,
          productId: productId,
          quantity: quantity,
          lowStockThreshold: lowStockThreshold,
          lastRestockedAt: DateTime.parse(restockedStr),
          createdAt: DateTime.parse(createdStr),
          updatedAt: DateTime.parse(now),
        );

        return Ok(updatedItem);
      });
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao salvar item no estoque doméstico',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<StockItem?, Failure>> getStockItemByProductId(
    String productId,
  ) async {
    try {
      final row = await (_db.select(
        _db.stockItems,
      )..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();

      if (row == null) return const Ok(null);

      return Ok(_mapRowToStockItem(row));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar item do estoque', cause: e),
      );
    }
  }

  @override
  Future<Result<List<StockItem>, Failure>> getStockItems() async {
    try {
      final rows = await _db.select(_db.stockItems).get();
      final items = rows.map(_mapRowToStockItem).toList();
      return Ok(items);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao listar estoque doméstico', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteStockItem(String id) async {
    try {
      await (_db.delete(
        _db.stockItems,
      )..where((tbl) => tbl.id.equals(id) | tbl.productId.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao remover item do estoque', cause: e),
      );
    }
  }

  @override
  Future<Result<StockConsumptionEstimate, Failure>> getConsumptionEstimate(
    String productId,
  ) async {
    try {
      // Buscar datas de compras do produto ordenadas por data
      final query =
          _db.select(_db.purchaseItems).join([
              innerJoin(
                _db.purchases,
                _db.purchases.id.equalsExp(_db.purchaseItems.purchaseId),
              ),
            ])
            ..where(_db.purchaseItems.productId.equals(productId))
            ..where(_db.purchases.deletedAt.isNull())
            ..orderBy([OrderingTerm.asc(_db.purchases.purchasedAt)]);

      final rows = await query.get();

      // Group by purchaseId to avoid duplicates from multiple items in same purchase
      final Map<String, DateTime> purchaseDateById = {};
      for (final r in rows) {
        final purchase = r.readTable(_db.purchases);
        purchaseDateById[purchase.id] = DateTime.parse(purchase.purchasedAt);
      }

      final dates = purchaseDateById.values.toList()..sort();
      final purchaseCount = dates.length;

      // RN-251 / CA-2.2: If fewer than 3 purchases, DO NOT estimate!
      if (purchaseCount < 3) {
        return Ok(
          StockConsumptionEstimate(
            productId: productId,
            purchaseCount: purchaseCount,
            hasEnoughHistory: false,
          ),
        );
      }

      // Calculate average interval between consecutive purchases
      double totalDays = 0;
      for (int i = 1; i < dates.length; i++) {
        totalDays += dates[i].difference(dates[i - 1]).inHours / 24.0;
      }
      final averageIntervalDays = totalDays / (dates.length - 1);

      // Estimate remaining days based on last purchase or restocking
      final stockItemResult = await getStockItemByProductId(productId);
      final stockItem = stockItemResult.valueOrNull;

      final referenceDate = stockItem?.lastRestockedAt ?? dates.last;
      final daysSinceRef =
          _clock.nowUtc().difference(referenceDate).inHours / 24.0;

      final calcRemainingDays = (averageIntervalDays - daysSinceRef).round();
      final displayRemainingDays = calcRemainingDays < 0
          ? 0
          : calcRemainingDays;

      // RN-252 / CA-2.1: "Running low" alert considering estimate and average interval
      final isLowStock =
          calcRemainingDays <= (averageIntervalDays * 0.2).ceil() ||
          (calcRemainingDays <= 3 && calcRemainingDays < averageIntervalDays);

      bool isAlertIssued = false;
      if (isLowStock) {
        final lastAlert = _lastAlertedDateByProductId[productId];
        if (lastAlert == null || lastAlert.isBefore(referenceDate)) {
          isAlertIssued = true;
          _lastAlertedDateByProductId[productId] = _clock.nowUtc();
        }
      }

      return Ok(
        StockConsumptionEstimate(
          productId: productId,
          purchaseCount: purchaseCount,
          hasEnoughHistory: true,
          averageIntervalDays: averageIntervalDays,
          estimatedDaysRemaining: displayRemainingDays,
          isLowStock: isLowStock,
          isAlertIssued: isAlertIssued,
        ),
      );
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao calcular estimativa de consumo do estoque',
          cause: e,
        ),
      );
    }
  }

  StockItem _mapRowToStockItem(db.StockItem row) {
    final unitEnum = Unit.values.firstWhere(
      (u) => u.name == row.unit,
      orElse: () => Unit.un,
    );

    return StockItem(
      id: row.id,
      productId: row.productId,
      quantity: Quantity(row.quantityMilli, unitEnum),
      lowStockThreshold: row.lowStockThresholdMilli != null
          ? Quantity(row.lowStockThresholdMilli!, unitEnum)
          : null,
      lastRestockedAt: row.lastRestockedAt != null
          ? DateTime.parse(row.lastRestockedAt!)
          : null,
      createdAt: row.createdAt != null ? DateTime.parse(row.createdAt!) : null,
      updatedAt: row.updatedAt != null ? DateTime.parse(row.updatedAt!) : null,
    );
  }
}
