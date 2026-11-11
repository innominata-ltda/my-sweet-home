library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Falha ao acessar ou persistir a chave da casa.
final class KeyStoreFailure extends Failure {
  final String message;
  final Object? cause;

  const KeyStoreFailure(this.message, [this.cause]);

  @override
  String toString() => 'KeyStoreFailure: $message';
}

/// Port for secure storage of household 256-bit symmetric key (RN-302, RN-309).
abstract interface class HouseholdKeyStore {
  /// Reads currently stored household key, or null if no active household.
  Future<Result<HouseholdKey?, Failure>> read();

  /// Persists 256-bit symmetric key in device secure storage.
  Future<Result<void, Failure>> write(HouseholdKey key);

  /// Remove a chave da casa do armazenamento seguro.
  Future<Result<void, Failure>> wipe();
}
