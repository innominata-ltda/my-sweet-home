import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database_key_store.dart';

/// Secure adapter for the database key via [FlutterSecureStorage] (ADR-0012, RN-414).
final class SecureDatabaseKeyStore implements DatabaseKeyStorePort {
  SecureDatabaseKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
          ),
      _random = random ?? Random.secure();

  static const String keyName = 'msh_db_key_v1';

  final FlutterSecureStorage _storage;
  final Random _random;

  @override
  Future<Result<Uint8List?, Failure>> read() async {
    try {
      final hex = await _storage.read(key: keyName);
      if (hex == null || hex.isEmpty) {
        return const Ok(null);
      }
      if (hex.length != 64) {
        return const Err(StorageFailure(detail: 'Invalid database key size'));
      }
      final bytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        final byteHex = hex.substring(i * 2, i * 2 + 2);
        final val = int.tryParse(byteHex, radix: 16);
        if (val == null) {
          return const Err(
            StorageFailure(detail: 'Invalid hexadecimal format'),
          );
        }
        bytes[i] = val;
      }
      return Ok(bytes);
    } catch (e) {
      return Err(StorageFailure(detail: 'Failed to read key', cause: e));
    }
  }

  @override
  Future<Result<Uint8List, Failure>> create() async {
    try {
      final bytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        bytes[i] = _random.nextInt(256);
      }
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: keyName, value: hex);
      return Ok(bytes);
    } catch (e) {
      return Err(StorageFailure(detail: 'Failed to save key', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> wipe() async {
    try {
      await _storage.delete(key: keyName);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Failed to wipe key', cause: e));
    }
  }
}
