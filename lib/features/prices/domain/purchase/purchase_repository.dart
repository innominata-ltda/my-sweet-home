import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';

/// Repository to manage purchases.
abstract interface class PurchaseRepository {
  /// Salva uma nova compra ou atualiza uma existente.
  Future<Result<void, Failure>> save(Purchase purchase);

  /// Finds a purchase by [id].
  Future<Result<Purchase?, Failure>> findById(String id);

  /// Returns all non-deleted purchases.
  Future<Result<List<Purchase>, Failure>> getAll();

  /// Soft deletes a purchase and its price points.
  Future<Result<void, Failure>> delete(String id);

  /// Restores a soft-deleted purchase.
  Future<Result<void, Failure>> restore(String id);
}
