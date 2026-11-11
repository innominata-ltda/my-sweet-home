import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/prices/domain/store/cnpj.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

class SqlitePricePointRepository implements PricePointRepository {
  SqlitePricePointRepository(this._db);
  final db.AppDatabase _db;

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async {
    try {
      await _db.transaction(() async {
        if (purchaseId != null) {
          // Remove old points for this purchase
          await (_db.delete(_db.pricePoints)..where(
                (t) => t.purchaseItemId.isInQuery(
                  _db.selectOnly(_db.purchaseItems)
                    ..addColumns([_db.purchaseItems.id])
                    ..where(_db.purchaseItems.purchaseId.equals(purchaseId)),
                ),
              ))
              .go();
        }

        for (final p in points) {
          await _db
              .into(_db.pricePoints)
              .insertOnConflictUpdate(
                db.PricePointsCompanion(
                  id: Value(p.id),
                  productId: Value(p.productId),
                  storeId: Value(p.storeId),
                  observedAt: Value(p.date.toUtc().toIso8601String()),
                  unitPriceCents: const Value(0),
                  normalizedPriceCents: Value(p.normalizedPrice.cents),
                  quantityMilli: const Value(0),
                  unit: Value(p.unit.name),
                  source: Value(p.source.name),
                ),
              );
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao salvar price points', cause: e),
      );
    }
  }

  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async {
    try {
      final query = _db.select(_db.pricePoints)
        ..where((t) => t.productId.equals(productId))
        ..where((t) => t.deletedAt.isNull())
        ..where(
          (t) => t.observedAt.isBiggerOrEqualValue(
            since.toUtc().toIso8601String(),
          ),
        )
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.observedAt, mode: OrderingMode.desc),
        ]);

      if (storeId != null) {
        query.where((t) => t.storeId.equals(storeId));
      }

      final rows = await query.get();
      final points = rows.map((r) {
        return PricePoint(
          id: r.id,
          productId: r.productId!,
          storeId: r.storeId!,
          date: DateTime.parse(r.observedAt).toUtc(),
          normalizedPrice: Money(r.normalizedPriceCents),
          unit: Unit.values.firstWhere((e) => e.name == r.unit),
          source: PricePointSource.values.firstWhere((e) => e.name == r.source),
        );
      }).toList();

      return Ok(points);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar histórico de preços', cause: e),
      );
    }
  }

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async {
    try {
      final avgCol = _db.pricePoints.normalizedPriceCents.avg();
      final countCol = _db.pricePoints.id.count();

      final query = _db.selectOnly(_db.pricePoints)
        ..addColumns([avgCol, countCol])
        ..where(_db.pricePoints.productId.equals(productId))
        ..where(_db.pricePoints.deletedAt.isNull())
        ..where(
          _db.pricePoints.observedAt.isBiggerOrEqualValue(
            since.toUtc().toIso8601String(),
          ),
        );

      final row = await query.getSingle();
      final count = row.read(countCol) ?? 0;

      if (count == 0) {
        return Ok(
          PriceStats(
            averagePrice: Money.zero,
            observationsCount: 0,
            windowDays: windowDays,
          ),
        );
      }

      final avgCents = (row.read(avgCol) ?? 0.0).round();

      return Ok(
        PriceStats(
          averagePrice: Money(avgCents),
          observationsCount: count,
          windowDays: windowDays,
        ),
      );
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao calcular estatísticas de preços',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async {
    try {
      final avgCol = _db.pricePoints.normalizedPriceCents.avg();
      final countCol = _db.pricePoints.id.count();

      final query = _db.selectOnly(_db.pricePoints)
        ..addColumns([_db.pricePoints.storeId, avgCol, countCol])
        ..where(_db.pricePoints.productId.equals(productId))
        ..where(_db.pricePoints.deletedAt.isNull())
        ..where(
          _db.pricePoints.observedAt.isBiggerOrEqualValue(
            since.toUtc().toIso8601String(),
          ),
        )
        ..groupBy([_db.pricePoints.storeId]);

      final rows = await query.get();
      if (rows.isEmpty) {
        return const Ok([]);
      }

      final storeIds = rows
          .map((r) => r.read(_db.pricePoints.storeId))
          .whereType<String>()
          .toList();

      final storeRows = await (_db.select(
        _db.stores,
      )..where((t) => t.id.isIn(storeIds))).get();

      final storeMap = {for (final s in storeRows) s.id: _mapStoreRow(s)};

      final rankings = <StoreRanking>[];
      for (final r in rows) {
        final storeId = r.read(_db.pricePoints.storeId);
        final store = storeMap[storeId];
        if (store == null) continue;

        final avgCentsDouble = r.read(avgCol);
        final obsCount = r.read(countCol) ?? 0;
        final avgCents = (avgCentsDouble ?? 0.0).round();

        rankings.add(
          StoreRanking(
            store: store,
            averageNormalized: Money(avgCents),
            observations: obsCount,
            minObservations: minObservations,
          ),
        );
      }

      // Sorting (RN-056 / CA-3.2):
      // Conclusive (observations >= minObservations) first, sorted by lowest price.
      // Stores with few observations come next (also sorted by price).
      rankings.sort((a, b) {
        if (a.hasLittleData != b.hasLittleData) {
          return a.hasLittleData ? 1 : -1;
        }
        final priceComp = a.averageNormalized.cents.compareTo(
          b.averageNormalized.cents,
        );
        if (priceComp != 0) return priceComp;
        return a.store.name.compareTo(b.store.name);
      });

      return Ok(rankings);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar ranking de lojas', cause: e),
      );
    }
  }

  Store _mapStoreRow(db.Store row) {
    Cnpj? cnpjObj;
    if (row.cnpj != null) {
      final res = Cnpj.create(row.cnpj!);
      if (res.isOk) {
        cnpjObj = res.valueOrNull;
      }
    }
    return Store(
      id: row.id,
      name: row.name,
      cnpj: cnpjObj,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      createdAt: DateTime.parse(row.createdAt!).toUtc(),
      updatedAt: DateTime.parse(row.updatedAt!).toUtc(),
    );
  }
}
