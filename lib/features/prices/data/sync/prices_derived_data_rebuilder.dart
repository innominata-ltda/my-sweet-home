library;

import 'package:drift/drift.dart';

import '../../../../core/quantity/quantity.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/domain/derived_data_rebuilder.dart';
import '../../../../data/database/database.dart';

/// Recalculates derived price points from purchases and items received via sync (RN-327, CA-5.6).
final class PricesDerivedDataRebuilder implements DerivedDataRebuilder {
  final AppDatabase db;

  const PricesDerivedDataRebuilder(this.db);

  @override
  Set<String> get watchesTables => const {'purchases', 'purchase_items'};

  @override
  Future<Result<void, Failure>> rebuild(Set<String> touchedRowIds) async {
    try {
      // 1. Obter todos os purchase_items afetados direta ou indiretamente (via purchase)
      final query = db.select(db.purchaseItems).join([
        innerJoin(
          db.purchases,
          db.purchases.id.equalsExp(db.purchaseItems.purchaseId),
        ),
      ]);

      if (touchedRowIds.isNotEmpty) {
        query.where(
          db.purchaseItems.id.isIn(touchedRowIds) |
              db.purchases.id.isIn(touchedRowIds),
        );
      }

      final rows = await query.get();

      for (final row in rows) {
        final pi = row.readTable(db.purchaseItems);
        final purch = row.readTable(db.purchases);

        // If purchase was deleted (deletedAt != null) or has no product, remove price_point
        if (purch.deletedAt != null || pi.productId == null) {
          await (db.delete(
            db.pricePoints,
          )..where((tbl) => tbl.purchaseItemId.equals(pi.id))).go();
          continue;
        }

        // Calculates normalized price (RN-053)
        final unitParsed = Unit.values.firstWhere(
          (u) => u.name == pi.unit,
          orElse: () => Unit.un,
        );
        final quantity = Quantity(pi.quantityMilli, unitParsed);

        final Unit normalizedUnit = switch (quantity.unit.dimension) {
          Dimension.mass => Unit.kg,
          Dimension.volume => Unit.l,
          Dimension.count => Unit.un,
        };

        final baseValueMilli = quantity.valueMilli * quantity.unit.milliPerUnit;
        final int normalizedPriceCents;
        if (baseValueMilli == 0) {
          normalizedPriceCents = 0;
        } else {
          final normalizedUnitMilli = normalizedUnit.milliPerUnit * 1000;
          normalizedPriceCents =
              (pi.totalPriceCents * normalizedUnitMilli) ~/ baseValueMilli;
        }

        final pointId = 'pp_${purch.id}_${pi.id}';

        await db
            .into(db.pricePoints)
            .insertOnConflictUpdate(
              PricePointsCompanion.insert(
                id: pointId,
                productId: Value(pi.productId),
                storeId: Value(purch.storeId),
                purchaseItemId: Value(pi.id),
                observedAt: purch.purchasedAt,
                unitPriceCents: pi.unitPriceCents,
                normalizedPriceCents: normalizedPriceCents,
                quantityMilli: pi.quantityMilli,
                unit: normalizedUnit.name,
                source: 'purchase',
              ),
            );
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao recalcular pontos de preço derivados: $e',
          cause: e,
        ),
      );
    }
  }
}
