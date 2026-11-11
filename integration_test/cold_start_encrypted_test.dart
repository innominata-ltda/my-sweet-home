@Tags(['device'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../test/fakes/fake_database_key_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cold start with encrypted database', () {
    late Directory tempDir;
    late File dbFile;
    late Uint8List encryptionKey;
    late String hexKey;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('msh_cold_start_test_');
      dbFile = File('${tempDir.path}/app_encrypted.db');
      encryptionKey = Uint8List.fromList(
        List<int>.generate(32, (i) => (i * 29 + 17) % 256),
      );
      hexKey = encryptionKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // Pre-populate encrypted database with 10,000 records to simulate real load
      final rawDb = sqlite3.sqlite3.open(dbFile.path);
      rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
      rawDb.execute('''
        CREATE TABLE expenses (
          id TEXT PRIMARY KEY,
          amount_cents INTEGER NOT NULL,
          occurred_on TEXT NOT NULL,
          description TEXT
        );
      ''');

      rawDb.execute('BEGIN TRANSACTION;');
      final stmt = rawDb.prepare(
        'INSERT INTO expenses VALUES (?, 2500, "2026-10-01", "Despesa");',
      );
      for (var i = 1; i <= 10000; i++) {
        stmt.execute(['exp_$i']);
      }
      stmt.close();
      rawDb.execute('COMMIT;');
      rawDb.close();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'CA-5.9 / RNF-001: Abertura a frio com banco cifrado de 10.000 registros ocorre em <= 2s',
      (tester) async {
        final keyStore = FakeDatabaseKeyStore(initialKey: encryptionKey);
        final vault = DefaultDatabaseVault(
          keyStore: keyStore,
          dbFileProvider: () async => dbFile,
          inBackground: false,
        );

        // Measure cold start opening time
        final stopwatch = Stopwatch()..start();

        final opening = await vault.open();
        expect(opening, isA<VaultReady>());

        final ready = opening as VaultReady;
        // Consulta inicial do dashboard
        final countResult = await ready.db
            .customSelect('SELECT count(*) AS c FROM expenses;')
            .getSingle();
        final count = countResult.read<int>('c');
        expect(count, 10000);

        stopwatch.stop();

        // RNF-001 / CA-5.9: Abertura e consulta inicial devem completar em <= 2 segundos
        expect(
          stopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(2000),
          reason:
              'Abertura a frio levou ${stopwatch.elapsedMilliseconds} ms (limite: 2000 ms)',
        );

        await ready.db.close();
      },
    );
  });
}
