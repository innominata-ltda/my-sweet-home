import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';

import 'package:my_sweet_home/core/time/clock.dart';

/// SQLite implementation for [PurchaseRepository].
class SqlitePurchaseRepository implements PurchaseRepository {
  SqlitePurchaseRepository(this._db, this._clock);
  final db.AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<void, Failure>> save(Purchase purchase) async {
    try {
      await _db.transaction(() async {
        // Salva a compra
        await _db
            .into(_db.purchases)
            .insertOnConflictUpdate(
              db.PurchasesCompanion(
                id: Value(purchase.id),
                storeId: Value(purchase.storeId),
                purchasedAt: Value(purchase.date.toUtc().toIso8601String()),
                totalCents: Value(purchase.totalAmount.cents),
                discountCents: Value(purchase.discountAmount.cents),
                source: const Value('manual'),
              ),
            );

        // Remove old items and old price points (in case of update)
        await (_db.delete(_db.pricePoints)..where(
              (t) => t.purchaseItemId.isInQuery(
                _db.selectOnly(_db.purchaseItems)
                  ..addColumns([_db.purchaseItems.id])
                  ..where(_db.purchaseItems.purchaseId.equals(purchase.id)),
              ),
            ))
            .go();
        await (_db.delete(
          _db.purchaseItems,
        )..where((t) => t.purchaseId.equals(purchase.id))).go();

        // Insert items and price points
        var position = 0;
        for (final item in purchase.items) {
          await _db
              .into(_db.purchaseItems)
              .insert(
                db.PurchaseItemsCompanion.insert(
                  id: item.id,
                  purchaseId: purchase.id,
                  productId: Value(
                    item.productId.isNotEmpty ? item.productId : null,
                  ),
                  rawDescription: item.rawDescription,
                  quantityMilli: item.quantity.valueMilli,
                  unit: item.quantity.unit.name,
                  unitPriceCents: item.unitPrice.cents,
                  totalPriceCents: item.totalPrice.cents,
                  position: position++,
                ),
              );

          if (item.productId.isNotEmpty) {
            final pricePointId = '${purchase.id}_pp_${item.id}';
            final pp = PricePoint.fromPurchaseItem(
              id: pricePointId,
              storeId: purchase.storeId,
              date: purchase.date,
              item: item,
            );

            await _db
                .into(_db.pricePoints)
                .insertOnConflictUpdate(
                  db.PricePointsCompanion.insert(
                    id: pp.id,
                    productId: Value(pp.productId),
                    storeId: Value(pp.storeId),
                    observedAt: pp.date.toIso8601String(),
                    unitPriceCents: item.unitPrice.cents,
                    normalizedPriceCents: pp.normalizedPrice.cents,
                    quantityMilli: item.quantity.valueMilli,
                    unit: pp.unit.name,
                    purchaseItemId: Value(item.id),
                    source: pp.source.name,
                  ),
                );
          }
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao salvar compra', cause: e));
    }
  }

  @override
  Future<Result<Purchase?, Failure>> findById(String id) async {
    try {
      final purchaseRow = await (_db.select(
        _db.purchases,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (purchaseRow == null) {
        return const Ok(null);
      }

      final itemRows =
          await (_db.select(_db.purchaseItems)
                ..where((t) => t.purchaseId.equals(id))
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();

      final items = itemRows.map((row) {
        final unit = Unit.values.firstWhere((e) => e.name == row.unit);
        return PurchaseItem(
          id: row.id,
          productId: row.productId ?? '',
          rawDescription: row.rawDescription,
          quantity: Quantity(row.quantityMilli, unit),
          unitPrice: Money(row.unitPriceCents),
          totalPrice: Money(row.totalPriceCents),
        );
      }).toList();

      final purchase = Purchase(
        id: purchaseRow.id,
        storeId: purchaseRow.storeId!, // Ignorando nullable db
        date: DateTime.parse(purchaseRow.purchasedAt).toUtc(),
        items: items,
        totalAmount: Money(purchaseRow.totalCents),
        discountAmount: Money(purchaseRow.discountCents),
      );

      return Ok(purchase);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao buscar compra', cause: e));
    }
  }

  @override
  Future<Result<List<Purchase>, Failure>> getAll() async {
    try {
      final purchaseRows =
          await (_db.select(_db.purchases)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.purchasedAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();

      final purchases = <Purchase>[];
      for (final purchaseRow in purchaseRows) {
        final itemRows =
            await (_db.select(_db.purchaseItems)
                  ..where((t) => t.purchaseId.equals(purchaseRow.id))
                  ..orderBy([(t) => OrderingTerm(expression: t.position)]))
                .get();

        final items = itemRows.map((row) {
          final unit = Unit.values.firstWhere(
            (e) => e.name == row.unit,
            orElse: () => Unit.un,
          );
          return PurchaseItem(
            id: row.id,
            productId: row.productId ?? '',
            rawDescription: row.rawDescription,
            quantity: Quantity(row.quantityMilli, unit),
            unitPrice: Money(row.unitPriceCents),
            totalPrice: Money(row.totalPriceCents),
          );
        }).toList();

        purchases.add(
          Purchase(
            id: purchaseRow.id,
            storeId: purchaseRow.storeId ?? '',
            date: DateTime.parse(purchaseRow.purchasedAt).toUtc(),
            items: items,
            totalAmount: Money(purchaseRow.totalCents),
            discountAmount: Money(purchaseRow.discountCents),
          ),
        );
      }

      return Ok(purchases);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao buscar compras', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    try {
      await _db.transaction(() async {
        final now = _clock.nowUtc().toIso8601String();

        // 1. Soft delete the purchase
        await (_db.update(_db.purchases)..where((t) => t.id.equals(id))).write(
          db.PurchasesCompanion(deletedAt: Value(now)),
        );

        // 2. Soft delete the related price points
        await (_db.update(_db.pricePoints)..where(
              (t) => t.purchaseItemId.isInQuery(
                _db.selectOnly(_db.purchaseItems)
                  ..addColumns([_db.purchaseItems.id])
                  ..where(_db.purchaseItems.purchaseId.equals(id)),
              ),
            ))
            .write(db.PricePointsCompanion(deletedAt: Value(now)));
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao excluir compra', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> restore(String id) async {
    try {
      await _db.transaction(() async {
        // 1. Restore the purchase
        await (_db.update(_db.purchases)..where((t) => t.id.equals(id))).write(
          const db.PurchasesCompanion(deletedAt: Value(null)),
        );

        // 2. Restore the related price points
        await (_db.update(_db.pricePoints)..where(
              (t) => t.purchaseItemId.isInQuery(
                _db.selectOnly(_db.purchaseItems)
                  ..addColumns([_db.purchaseItems.id])
                  ..where(_db.purchaseItems.purchaseId.equals(id)),
              ),
            ))
            .write(const db.PricePointsCompanion(deletedAt: Value(null)));
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao restaurar compra', cause: e));
    }
  }
}
