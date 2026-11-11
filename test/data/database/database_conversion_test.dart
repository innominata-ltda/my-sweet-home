import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/database/database_conversion.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../fakes/fake_database_key_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseConversion — CA-3.3, CA-3.4 (RN-415, RN-416, RNF-008)', () {
    late Directory tempDir;
    late File fixtureFile;
    late Uint8List encryptionKey;
    late String hexKey;

    setUpAll(() async {
      fixtureFile = File('test/fixtures/db/v7_plain_populated.sqlite');
      if (!fixtureFile.existsSync()) {
        fixtureFile.parent.createSync(recursive: true);
        // Gera o banco v7 populado para o teste
        final db = AppDatabase(NativeDatabase(fixtureFile));
        await db.customSelect('SELECT 1').get();

        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-alimentacao',
                name: 'Alimentação',
                kind: 'expense',
                iconKey: 'restaurant',
              ),
            );

        // 500 contas (CA-3.3)
        await db.batch((batch) {
          for (var i = 1; i <= 500; i++) {
            batch.insert(
              db.bills,
              BillsCompanion.insert(
                id: 'bill-$i',
                title: 'Conta $i',
                dueDay: (i % 28) + 1,
                isAmountVariable: false,
                amountCents: Value(i * 1000),
                categoryId: const Value('cat-alimentacao'),
              ),
            );
          }
        });

        // 10.000 despesas em lotes (CA-3.3)
        for (var chunk = 0; chunk < 10; chunk++) {
          await db.batch((batch) {
            for (var i = 1; i <= 1000; i++) {
              final idx = chunk * 1000 + i;
              batch.insert(
                db.expenses,
                ExpensesCompanion.insert(
                  id: 'exp-$idx',
                  amountCents: (idx * 50) % 50000 + 100,
                  occurredOn:
                      '2026-10-${((idx % 28) + 1).toString().padLeft(2, '0')}',
                  description: Value('Despesa $idx'),
                  categoryId: const Value('cat-alimentacao'),
                ),
              );
            }
          });
        }

        await db.close();
      }
    });

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('msh_conversion_test_');
      encryptionKey = Uint8List.fromList(
        List<int>.generate(32, (i) => (i * 17 + 23) % 256),
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

    test('CA-3.3: plaintext database with 10,000 expenses and 500 bills is converted without loss', () async {
      final testDbFile = File('${tempDir.path}/app_plain.db');
      fixtureFile.copySync(testDbFile.path);

      // Previous counts in original plaintext database
      final rawPre = sqlite3.sqlite3.open(testDbFile.path);
      final preExpenseCount =
          rawPre.select('SELECT count(*) AS c FROM expenses;').first['c']
              as int;
      final preBillCount =
          rawPre.select('SELECT count(*) AS c FROM bills;').first['c'] as int;
      rawPre.close();

      expect(preExpenseCount, 10000);
      expect(preBillCount, 500);

      // Executes safe conversion
      const conversion = DatabaseConversion();
      final result = await conversion.encryptInPlaceSafely(
        testDbFile,
        encryptionKey,
      );

      expect(result.isOk, isTrue);

      // Original file is now encrypted: read without key must fail
      final rawNoKey = sqlite3.sqlite3.open(testDbFile.path);
      expect(
        () => rawNoKey.select('SELECT count(*) FROM sqlite_master;'),
        throwsA(isA<sqlite3.SqliteException>()),
      );
      rawNoKey.close();

      // Leitura com a chave correta: todas as linhas foram preservadas
      final rawKeyed = sqlite3.sqlite3.open(testDbFile.path);
      rawKeyed.execute('PRAGMA key = "x\'$hexKey\'";');

      final postExpenseCount =
          rawKeyed.select('SELECT count(*) AS c FROM expenses;').first['c']
              as int;
      final postBillCount =
          rawKeyed.select('SELECT count(*) AS c FROM bills;').first['c'] as int;
      rawKeyed.close();

      expect(postExpenseCount, equals(preExpenseCount));
      expect(postBillCount, equals(preBillCount));

      // Temporary copy file no longer exists
      expect(File('${testDbFile.path}.enc-tmp').existsSync(), isFalse);
    });

    test('CA-3.4: simulated failure preserves original database intact and returns VaultConversionFailed', () async {
      final testDbFile = File('${tempDir.path}/app_plain_failing.db');
      fixtureFile.copySync(testDbFile.path);

      final keyStore = FakeDatabaseKeyStore(initialKey: encryptionKey);
      final failingVault = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => testDbFile,
        conversion: const DatabaseConversion(failAfterRekey: true),
        inBackground: false,
      );

      // First opening fails on conversion
      final opening = await failingVault.open();
      expect(opening, isA<VaultConversionFailed>());

      final failed = opening as VaultConversionFailed;
      // Original data remains intact and accessible
      final expensesCount = await failed.plaintextDb
          .customSelect('SELECT count(*) AS c FROM expenses;')
          .getSingle();
      expect(expensesCount.read<int>('c'), 10000);
      await failed.plaintextDb.close();

      // Second opening with normal conversion: retries and completes
      final normalVault = DefaultDatabaseVault(
        keyStore: keyStore,
        dbFileProvider: () async => testDbFile,
        conversion: const DatabaseConversion(failAfterRekey: false),
        inBackground: false,
      );

      final secondOpening = await normalVault.open();
      expect(secondOpening, isA<VaultReady>());

      final ready = secondOpening as VaultReady;
      final postExpensesCount = await ready.db
          .customSelect('SELECT count(*) AS c FROM expenses;')
          .getSingle();
      expect(postExpensesCount.read<int>('c'), 10000);
      await ready.db.close();
    });
  });
}
