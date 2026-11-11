import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// In-memory fake of [HouseholdKeyStore] for tests.
class FakeHouseholdKeyStore implements HouseholdKeyStore {
  HouseholdKey? _key;
  bool failNext = false;

  FakeHouseholdKeyStore([this._key]);

  @override
  Future<Result<HouseholdKey?, Failure>> read() async {
    if (failNext) {
      failNext = false;
      return const Err(KeyStoreFailure('Erro simulado de leitura'));
    }
    return Ok(_key);
  }

  @override
  Future<Result<void, Failure>> write(HouseholdKey key) async {
    if (failNext) {
      failNext = false;
      return const Err(KeyStoreFailure('Erro simulado de escrita'));
    }
    _key = key;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> wipe() async {
    if (failNext) {
      failNext = false;
      return const Err(KeyStoreFailure('Erro simulado ao apagar'));
    }
    _key = null;
    return const Ok(null);
  }
}
