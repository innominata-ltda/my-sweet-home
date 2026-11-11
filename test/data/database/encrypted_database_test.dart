import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

import '../../fakes/fake_database_key_store.dart';
import '../../fakes/recording_background_runner.dart';

void main() {
  group('Encrypted Database — CA-3.2 (RN-414)', () {
    late Directory tempDir;
    late File dbFile;
    late Uint8List encryptionKey;
    late String hexKey;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('msh_enc_db_test_');
      dbFile = File('${tempDir.path}/test_encrypted.db');
      encryptionKey = Uint8List.fromList(
        List<int>.generate(32, (index) => (index * 7 + 13) % 256),
      );
      hexKey = encryptionKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('CA-3.2: banco cifrado aberto sem chave falha com SqliteException (SQLITE_NOTADB)', () {
      // 1. Cria banco e define chave com sqlite3mc
      final db = sqlite3.open(dbFile.path);
      db.execute('PRAGMA key = "x\'$hexKey\'";');
      db.execute('CREATE TABLE secrets (id INT PRIMARY KEY, value TEXT);');
      db.execute("INSERT INTO secrets VALUES (1, 'my-super-secret');");
      db.close();

      expect(dbFile.existsSync(), isTrue);
      expect(dbFile.lengthSync(), greaterThan(0));

      // 2. Open without key: reading sqlite_master or table MUST fail with SqliteException (SQLITE_NOTADB)
      final unkeyedDb = sqlite3.open(dbFile.path);
      addTearDown(unkeyedDb.close);

      expect(
        () => unkeyedDb.select('SELECT count(*) FROM sqlite_master;'),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.resultCode,
            'resultCode (SQLITE_NOTADB = 26)',
            26,
          ),
        ),
      );
    });

    test('reopening with correct key reads data successfully', () {
      // 1. Cria e cifra
      final db = sqlite3.open(dbFile.path);
      db.execute('PRAGMA key = "x\'$hexKey\'";');
      db.execute('CREATE TABLE data (id INT PRIMARY KEY, name TEXT);');
      db.execute("INSERT INTO data VALUES (42, 'My Sweet Home');");
      db.close();

      // 2. Reabre com a mesma chave
      final rekeyedDb = sqlite3.open(dbFile.path);
      addTearDown(rekeyedDb.close);

      rekeyedDb.execute('PRAGMA key = "x\'$hexKey\'";');
      final result = rekeyedDb.select('SELECT name FROM data WHERE id = 42;');

      expect(result, isNotEmpty);
      expect(result.first['name'], 'My Sweet Home');
    });

    test('CA-3.7: exported backup of encrypted database never contains database key (hex or base64)', () async {
      final keyStore = FakeDatabaseKeyStore(initialKey: encryptionKey);
      final vault = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => dbFile,
        inBackground: false,
      );

      final opening = await vault.open();
      expect(opening, isA<VaultReady>());
      final db = (opening as VaultReady).db;
      addTearDown(db.close);

      // Exporta o backup usando DriftBackupService
      final backupService = DriftBackupService(
        db,
        runner: RecordingBackgroundRunner(),
      );

      final backupRes = await backupService.exportBackup();
      expect(backupRes.isOk, isTrue);
      final backupJson = backupRes.valueOrNull!.toJsonString();

      // CA-3.7: nem o hex nem o base64 da chave do banco podem estar no backup
      expect(backupJson.contains(hexKey), isFalse);
      final base64Key = base64Encode(encryptionKey);
      expect(backupJson.contains(base64Key), isFalse);
    });
  });
}
