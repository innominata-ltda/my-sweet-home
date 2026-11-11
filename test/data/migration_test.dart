import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  test('Migration v1 to v2 preserves data (T-12)', () async {
    // 1. Copies v1.sqlite fixture to temporary file
    final fixtureFile = File('test/fixtures/db/v1.sqlite');
    expect(
      fixtureFile.existsSync(),
      isTrue,
      reason: 'Execute scripts/generate_fixture_v1.dart antes',
    );

    final tempDir = Directory.systemTemp.createTempSync('drift_migration_test');
    final dbFile = File('${tempDir.path}/app.db');
    fixtureFile.copySync(dbFile.path);

    // 2. Opens database in new version (v2)
    final db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));

    // 3. Forces opening/migration
    await db.customSelect('SELECT 1').get();

    // 4. Verifica se a coluna de teste foi adicionada na tabela settings
    // This confirms migration ran.
    final columns = await db.customSelect('PRAGMA table_info(settings)').get();
    final hasTestColumn = columns.any(
      (row) => row.read<String>('name') == 'test_column',
    );
    expect(hasTestColumn, isTrue);

    // 5. Verify existing data in v1 fixture was preserved
    final expensesCount = await db.expenses.count().getSingle();
    expect(expensesCount, 1);

    final expense = await db.select(db.expenses).getSingle();
    expect(expense.amountCents, 1500);

    final purchasesCount = await db.purchases.count().getSingle();
    expect(purchasesCount, 1);

    final purchase = await db.select(db.purchases).getSingle();
    expect(purchase.totalCents, 1500);

    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'Migration to v4 creates stock_items and checklist_items tables (T-I01)',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'drift_migration_v4_test',
      );
      final dbFile = File('${tempDir.path}/app.db');

      final db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));

      // Forces opening/migration
      await db.customSelect('SELECT 1').get();

      // Verifica que as tabelas stock_items e checklist_items existem
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final tableNames = tables.map((row) => row.read<String>('name')).toList();

      expect(tableNames, contains('stock_items'));
      expect(tableNames, contains('checklist_items'));

      await db.close();
      tempDir.deleteSync(recursive: true);
    },
  );

  test('Migration to v5 creates sync_* tables and triggers disabled by default (013/T-I01)', () async {
    final fixtureFile = File('test/fixtures/db/v4.sqlite');
    expect(fixtureFile.existsSync(), isTrue);

    final tempDir = Directory.systemTemp.createTempSync(
      'drift_migration_v5_summary_test',
    );
    final dbFile = File('${tempDir.path}/app.db');
    fixtureFile.copySync(dbFile.path);

    final db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));

    // Forces opening and migration
    await db.customSelect('SELECT 1').get();

    // Verifica tabelas sync_*
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final tableNames = tables.map((r) => r.read<String>('name')).toSet();

    expect(tableNames, contains('sync_household'));
    expect(tableNames, contains('sync_members'));
    expect(tableNames, contains('sync_column_versions'));
    expect(tableNames, contains('sync_row_tombstones'));
    expect(tableNames, contains('sync_peer_vectors'));

    // Triggers disabled by default when sync_household is empty
    expect(await db.syncColumnVersions.count().getSingle(), equals(0));

    await db.close();
    tempDir.deleteSync(recursive: true);
  });
}
