import 'package:my_sweet_home/core/result/result.dart';

import 'store.dart';

/// Porta para salvar e buscar estabelecimentos.
abstract interface class StoreRepository {
  /// Saves a store (creation or update).
  ///
  /// Returns [StorageFailure] if CNPJ already exists.
  Future<Result<void, Failure>> save(Store store);

  /// Busca um estabelecimento pelo ID.
  Future<Result<Store, Failure>> findById(String id);

  /// Busca um estabelecimento pelo CNPJ.
  Future<Result<Store, Failure>> findByCnpj(String cnpjValue);

  /// Lista todos os estabelecimentos, ordenados por nome.
  Future<Result<List<Store>, Failure>> listAll();
}
