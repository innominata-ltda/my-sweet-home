import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database_key_store.dart';

/// Fake de [DatabaseKeyStorePort] para testes (004-testing §3).
final class FakeDatabaseKeyStore implements DatabaseKeyStorePort {
  FakeDatabaseKeyStore({Uint8List? initialKey}) : _key = initialKey;

  Uint8List? _key;
  bool simulateReadFailure = false;
  bool simulateCreateFailure = false;
  bool simulateWipeFailure = false;

  Uint8List? get currentKey => _key;

  @override
  Future<Result<Uint8List?, Failure>> read() async {
    if (simulateReadFailure) {
      return const Err(
        StorageFailure(detail: 'Falha simulada ao ler chave do banco'),
      );
    }
    return Ok(_key);
  }

  @override
  Future<Result<Uint8List, Failure>> create() async {
    if (simulateCreateFailure) {
      return const Err(
        StorageFailure(detail: 'Falha simulada ao criar chave do banco'),
      );
    }
    final generated = Uint8List.fromList(
      List<int>.generate(32, (i) => (i * 13 + 37) % 256),
    );
    _key = generated;
    return Ok(generated);
  }

  @override
  Future<Result<void, Failure>> wipe() async {
    if (simulateWipeFailure) {
      return const Err(
        StorageFailure(detail: 'Falha simulada ao apagar chave do banco'),
      );
    }
    _key = null;
    return const Ok(null);
  }
}
