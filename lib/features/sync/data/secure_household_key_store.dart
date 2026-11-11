import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// [HouseholdKeyStore] implementation using [FlutterSecureStorage].
final class SecureHouseholdKeyStore implements HouseholdKeyStore {
  static const String keyName = 'household_sync_aes_key';
  HouseholdKey? _cachedKey;

  bool get hasCachedKey => _cachedKey != null;

  final FlutterSecureStorage storage;

  SecureHouseholdKeyStore({this.storage = const FlutterSecureStorage()});

  @override
  Future<Result<HouseholdKey?, Failure>> read() async {
    try {
      final encoded = await storage.read(key: keyName);
      if (encoded == null || encoded.isEmpty) {
        return const Ok(null);
      }
      final key = HouseholdKey.fromBase64(encoded);
      _cachedKey = key;
      return Ok(key);
    } catch (e) {
      return Err(KeyStoreFailure('Falha ao ler chave da casa', e));
    }
  }

  @override
  Future<Result<void, Failure>> write(HouseholdKey key) async {
    _cachedKey = key;
    try {
      await storage.write(key: keyName, value: key.toBase64());
      return const Ok(null);
    } catch (e) {
      return Err(KeyStoreFailure('Falha ao salvar chave da casa', e));
    }
  }

  @override
  Future<Result<void, Failure>> wipe() async {
    _cachedKey = null;
    try {
      await storage.delete(key: keyName);
      return const Ok(null);
    } catch (e) {
      return Err(KeyStoreFailure('Falha ao apagar chave da casa', e));
    }
  }
}
