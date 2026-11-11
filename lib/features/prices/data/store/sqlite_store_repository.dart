import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;

import '../../domain/store/cnpj.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_repository.dart';

/// SQLite implementation for [StoreRepository].
class SqliteStoreRepository implements StoreRepository {
  SqliteStoreRepository(this._db);
  final db.AppDatabase _db;

  @override
  Future<Result<void, Failure>> save(Store store) async {
    try {
      await _db
          .into(_db.stores)
          .insertOnConflictUpdate(
            db.StoresCompanion(
              id: Value(store.id),
              name: Value(store.name),
              cnpj: Value(store.cnpj?.value),
              address: Value(store.address),
              latitude: Value(store.latitude),
              longitude: Value(store.longitude),
              createdAt: Value(store.createdAt.toUtc().toIso8601String()),
              updatedAt: Value(store.updatedAt.toUtc().toIso8601String()),
            ),
          );
      return const Ok(null);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: stores.cnpj')) {
        return const Err(StorageFailure(detail: 'CNPJ já cadastrado'));
      }
      return Err(StorageFailure(detail: 'Erro ao salvar loja', cause: e));
    }
  }

  @override
  Future<Result<Store, Failure>> findById(String id) async {
    try {
      final row = await (_db.select(
        _db.stores,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) {
        return const Err(NotFoundFailure(what: 'Store'));
      }
      return Ok(_mapRow(row));
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao buscar loja', cause: e));
    }
  }

  @override
  Future<Result<Store, Failure>> findByCnpj(String cnpjValue) async {
    try {
      final row = await (_db.select(
        _db.stores,
      )..where((t) => t.cnpj.equals(cnpjValue))).getSingleOrNull();
      if (row == null) {
        return const Err(NotFoundFailure(what: 'Store by CNPJ'));
      }
      return Ok(_mapRow(row));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar loja por CNPJ', cause: e),
      );
    }
  }

  @override
  Future<Result<List<Store>, Failure>> listAll() async {
    try {
      final rows = await (_db.select(
        _db.stores,
      )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
      return Ok(rows.map(_mapRow).toList());
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao listar lojas', cause: e));
    }
  }

  Store _mapRow(db.Store row) {
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
      createdAt: row.createdAt != null
          ? DateTime.parse(row.createdAt!).toUtc()
          : DateTime.utc(1970),
      updatedAt: row.updatedAt != null
          ? DateTime.parse(row.updatedAt!).toUtc()
          : DateTime.utc(1970),
    );
  }
}
