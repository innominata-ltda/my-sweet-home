import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/adapters/secure_database_key_store.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/database/database_conversion.dart';
import 'package:my_sweet_home/data/database/database_key_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite3;

sealed class VaultOpening {}

final class VaultReady extends VaultOpening {
  VaultReady(this.db);
  final AppDatabase db;
}

final class VaultConversionFailed extends VaultOpening {
  VaultConversionFailed(this.plaintextDb);
  final AppDatabase plaintextDb;
} // RN-416

final class VaultKeyUnavailable extends VaultOpening {} // RN-417

abstract interface class DatabaseVaultPort {
  Future<VaultOpening> open();

  /// Closes and deletes db/-wal/-shm/-journal/.enc-tmp and the key (RN-418).
  Future<Result<void, Failure>> destroy();
}

typedef AppDatabaseFactory = AppDatabase Function(File file, Uint8List key);

/// Default database vault implementation (RN-414..418).
final class DefaultDatabaseVault implements DatabaseVaultPort {
  DefaultDatabaseVault({
    this.keyStore,
    this.dbFileProvider,
    this.appDatabaseFactory,
    this.conversion,
    this.inBackground = true,
  });

  final DatabaseKeyStorePort? keyStore;
  final Future<File> Function()? dbFileProvider;
  final AppDatabaseFactory? appDatabaseFactory;
  final DatabaseConversion? conversion;
  final bool inBackground;

  File? _resolvedFile;
  AppDatabase? _activeDb;

  Future<File> _resolveFile() async {
    final cached = _resolvedFile;
    if (cached != null) return cached;
    final provider = dbFileProvider;
    if (provider != null) {
      final file = await provider();
      _resolvedFile = file;
      return file;
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'my_sweet_home.db'));
    _resolvedFile = file;
    return file;
  }

  bool _isEncrypted(File file) {
    if (!file.existsSync() || file.lengthSync() == 0) return false;
    sqlite3.Database? rawDb;
    try {
      rawDb = sqlite3.sqlite3.open(file.path);
      rawDb.select('SELECT count(*) FROM sqlite_master;');
      return false; // Reads plaintext
    } catch (_) {
      return true; // Fails without key -> encrypted (or not a db)
    } finally {
      rawDb?.close();
    }
  }

  bool _canOpenWithKey(File file, Uint8List key) {
    sqlite3.Database? rawDb;
    try {
      rawDb = sqlite3.sqlite3.open(file.path);
      final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
      rawDb.select('SELECT count(*) FROM sqlite_master;');
      return true;
    } catch (_) {
      return false;
    } finally {
      rawDb?.close();
    }
  }

  AppDatabase _createDb(File file, Uint8List key) {
    final customFactory = appDatabaseFactory;
    if (customFactory != null) {
      return customFactory(file, key);
    }
    final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return AppDatabase(
      _buildEncryptedLazyDb(file, hexKey, inBackground: inBackground),
    );
  }

  AppDatabase _createPlaintextDb(File file) {
    return AppDatabase(_buildPlaintextLazyDb(file, inBackground: inBackground));
  }

  @override
  Future<VaultOpening> open() async {
    final effectiveKeyStore = keyStore ?? SecureDatabaseKeyStore();
    final file = await _resolveFile();

    final fileExists = file.existsSync() && file.lengthSync() > 0;
    final keyRes = await effectiveKeyStore.read();
    final key = keyRes.valueOrNull;

    if (fileExists) {
      final isEncrypted = _isEncrypted(file);
      if (isEncrypted) {
        // Encrypted database on disk
        if (key == null) {
          // Secure storage without key (RN-417, CA-3.5)
          // Do NOT create empty database or overwrite
          return VaultKeyUnavailable();
        }
        if (!_canOpenWithKey(file, key)) {
          return VaultKeyUnavailable();
        }
        final db = _createDb(file, key);
        _activeDb = db;
        return VaultReady(db);
      } else {
        // Plaintext database (legacy v7) - convert to encrypted (RN-415, RN-416, CA-3.3, CA-3.4)
        Uint8List activeKey;
        if (key == null) {
          final createRes = await effectiveKeyStore.create();
          if (createRes.isErr) {
            return VaultKeyUnavailable();
          }
          activeKey = createRes.valueOrNull!;
        } else {
          activeKey = key;
        }

        final conv = conversion ?? const DatabaseConversion();
        final convRes = await conv.encryptInPlaceSafely(file, activeKey);
        if (convRes.isErr) {
          // Conversion failed: original db intact, offer backup export (RN-416, CA-3.4)
          final plaintextDb = _createPlaintextDb(file);
          _activeDb = plaintextDb;
          return VaultConversionFailed(plaintextDb);
        }

        final db = _createDb(file, activeKey);
        _activeDb = db;
        return VaultReady(db);
      }
    } else {
      // New database: create key if none exists
      Uint8List activeKey;
      if (key == null) {
        final createRes = await effectiveKeyStore.create();
        if (createRes.isErr) {
          return VaultKeyUnavailable();
        }
        activeKey = createRes.valueOrNull!;
      } else {
        activeKey = key;
      }
      final db = _createDb(file, activeKey);
      _activeDb = db;
      return VaultReady(db);
    }
  }

  @override
  Future<Result<void, Failure>> destroy() async {
    try {
      if (_activeDb != null) {
        await _activeDb!.close();
        _activeDb = null;
      }
      final file = await _resolveFile();
      final basePath = file.path;
      final candidates = [
        file,
        File('$basePath-wal'),
        File('$basePath-shm'),
        File('$basePath-journal'),
        File('$basePath.enc-tmp'),
      ];
      for (final candidate in candidates) {
        if (candidate.existsSync()) {
          candidate.deleteSync();
        }
      }
      final effectiveKeyStore = keyStore ?? SecureDatabaseKeyStore();
      await effectiveKeyStore.wipe();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Failed to destroy vault', cause: e));
    }
  }
}

final class _EncryptedDbSetup {
  const _EncryptedDbSetup(this.hexKey);

  final String hexKey;

  void call(sqlite3.Database rawDb) {
    rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
    rawDb.select('SELECT count(*) FROM sqlite_master;');
    rawDb.execute('PRAGMA foreign_keys = ON;');
  }
}

LazyDatabase _buildEncryptedLazyDb(
  File file,
  String hexKey, {
  required bool inBackground,
}) {
  final setup = _EncryptedDbSetup(hexKey).call;
  return LazyDatabase(() {
    if (inBackground) {
      return NativeDatabase.createInBackground(file, setup: setup);
    }
    return NativeDatabase(file, setup: setup);
  });
}

LazyDatabase _buildPlaintextLazyDb(File file, {required bool inBackground}) {
  return LazyDatabase(() {
    if (inBackground) {
      return NativeDatabase.createInBackground(file);
    }
    return NativeDatabase(file);
  });
}
