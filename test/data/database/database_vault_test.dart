import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../fakes/fake_database_key_store.dart';

void main() {
  group('DefaultDatabaseVault — CA-3.5 & RN-414..418', () {
    late Directory tempDir;
    late File dbFile;
    late FakeDatabaseKeyStore keyStore;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('msh_vault_test_');
      dbFile = File('${tempDir.path}/vault_test.db');
      keyStore = FakeDatabaseKeyStore();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'new database: without key and file creates key and returns VaultReady',
      () async {
        final vault = DefaultDatabaseVault(
          keyStore: keyStore,
          dbFileProvider: () async => dbFile,
          inBackground: false,
        );

        final opening = await vault.open();
        expect(opening, isA<VaultReady>());
        expect(keyStore.currentKey, isNotNull);
        expect(keyStore.currentKey!.length, 32);

        final ready = opening as VaultReady;
        await ready.db.customSelect('SELECT 1;').getSingle();
        await ready.db.close();
      },
    );

    test('reopening with existing key returns VaultReady', () async {
      // 1. Cria com vault
      final vault1 = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => dbFile,
        inBackground: false,
      );
      final opening1 = await vault1.open();
      expect(opening1, isA<VaultReady>());
      final db1 = (opening1 as VaultReady).db;
      await db1.customSelect('SELECT 1;').getSingle();
      await db1.close();

      // 2. Reabre com o mesmo keyStore
      final vault2 = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => dbFile,
        inBackground: false,
      );
      final opening2 = await vault2.open();
      expect(opening2, isA<VaultReady>());
      final db2 = (opening2 as VaultReady).db;
      await db2.customSelect('SELECT 1;').getSingle();
      await db2.close();
    });

    test('CA-3.5: encrypted file present without KeyStore key returns VaultKeyUnavailable without altering file', () async {
      // 1. Prepare real encrypted file with sqlite3mc
      final key = Uint8List.fromList(List.generate(32, (i) => (i + 1) % 256));
      final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final rawDb = sqlite3.sqlite3.open(dbFile.path);
      rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
      rawDb.execute('CREATE TABLE data (id INT);');
      rawDb.execute('INSERT INTO data VALUES (123);');
      rawDb.close();

      final originalLength = dbFile.lengthSync();
      final originalModified = dbFile.lastModifiedSync();

      // 2. Tenta abrir com KeyStore vazio (sem a chave)
      final emptyKeyStore = FakeDatabaseKeyStore(initialKey: null);
      final vault = DefaultDatabaseVault(
        keyStore: emptyKeyStore,
        dbFileProvider: () async => dbFile,
        inBackground: false,
      );

      final opening = await vault.open();

      // CA-3.5: retorna VaultKeyUnavailable
      expect(opening, isA<VaultKeyUnavailable>());

      // Does not create new key nor modify file
      expect(emptyKeyStore.currentKey, isNull);
      expect(dbFile.lengthSync(), originalLength);
      expect(dbFile.lastModifiedSync(), originalModified);
    });

    test('encrypted file present with incompatible key returns VaultKeyUnavailable', () async {
      // Cria cifrado com chave A
      final keyA = Uint8List.fromList(List.generate(32, (i) => 1));
      final hexKeyA = keyA
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final rawDb = sqlite3.sqlite3.open(dbFile.path);
      rawDb.execute('PRAGMA key = "x\'$hexKeyA\'";');
      rawDb.execute('CREATE TABLE data (id INT);');
      rawDb.close();

      // KeyStore contains key B
      final keyB = Uint8List.fromList(List.generate(32, (i) => 2));
      final badKeyStore = FakeDatabaseKeyStore(initialKey: keyB);

      final vault = DefaultDatabaseVault(
        keyStore: badKeyStore,
        dbFileProvider: () async => dbFile,
        inBackground: false,
      );

      final opening = await vault.open();
      expect(opening, isA<VaultKeyUnavailable>());
    });

    test(
      'destroy apaga arquivos de banco (-wal, -shm, etc.) e a chave (RN-418)',
      () async {
        // Cria arquivos auxiliares
        dbFile.writeAsStringSync('db');
        final walFile = File('${dbFile.path}-wal')..writeAsStringSync('wal');
        final shmFile = File('${dbFile.path}-shm')..writeAsStringSync('shm');
        final journalFile = File('${dbFile.path}-journal')
          ..writeAsStringSync('journal');
        final encTmpFile = File('${dbFile.path}.enc-tmp')
          ..writeAsStringSync('tmp');

        final key = Uint8List.fromList(List.generate(32, (i) => i));
        final populatedKeyStore = FakeDatabaseKeyStore(initialKey: key);

        final vault = DefaultDatabaseVault(
          keyStore: populatedKeyStore,
          dbFileProvider: () async => dbFile,
          inBackground: false,
        );

        final destroyRes = await vault.destroy();
        expect(destroyRes.isOk, isTrue);

        expect(dbFile.existsSync(), isFalse);
        expect(walFile.existsSync(), isFalse);
        expect(shmFile.existsSync(), isFalse);
        expect(journalFile.existsSync(), isFalse);
        expect(encTmpFile.existsSync(), isFalse);
        expect(populatedKeyStore.currentKey, isNull);
      },
    );

    test('inBackground: true opens encrypted database in background isolate without SendPort error', () async {
      final vault = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => dbFile,
        inBackground: true,
      );

      final opening = await vault.open();
      expect(opening, isA<VaultReady>());

      final ready = opening as VaultReady;
      final row = await ready.db.customSelect('SELECT 1 AS ok;').getSingle();
      expect(row.read<int>('ok'), 1);
      await ready.db.close();
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
