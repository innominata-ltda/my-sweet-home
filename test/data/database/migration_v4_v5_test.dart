import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  test('Migration v4 to v5 adds tasks.source_preset_id and preserves data (SPEC-014 T-I01)', () async {
    // 1. Copies v4.sqlite fixture to temporary file
    final fixtureFile = File('test/fixtures/db/v4.sqlite');
    expect(
      fixtureFile.existsSync(),
      isTrue,
      reason: 'Fixture v4.sqlite deve existir',
    );

    final tempDir = Directory.systemTemp.createTempSync(
      'drift_migration_v4_v5_test',
    );
    final dbFile = File('${tempDir.path}/app.db');
    fixtureFile.copySync(dbFile.path);

    // 2. Opens database in new version (v5)
    final db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));

    // 3. Forces opening and migration
    await db.customSelect('SELECT 1').get();

    // 4. Verifica se a coluna source_preset_id existe na tabela tasks
    final columns = await db.customSelect('PRAGMA table_info(tasks)').get();
    final columnNames = columns.map((row) => row.read<String>('name')).toList();
    expect(columnNames, contains('source_preset_id'));

    // 5. Verify existing data in v4 fixture was preserved
    final existingTask = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals('task_v4_existing'))).getSingle();
    expect(existingTask.title, 'Limpar fogão v4');
    expect(existingTask.notes, 'Nota v4');
    expect(existingTask.sourcePresetId, isNull);

    final expensesCount = await db.expenses.count().getSingle();
    expect(expensesCount, 1);

    final expense = await db.select(db.expenses).getSingle();
    expect(expense.amountCents, 1500);

    // 6. Insere nova tarefa com source_preset_id preenchido
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task_preset_migrated',
            title: 'Varrer o chão',
            sourcePresetId: const Value('sweep-floor'),
          ),
        );

    final newTask = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals('task_preset_migrated'))).getSingle();
    expect(newTask.sourcePresetId, 'sweep-floor');

    await db.close();
    tempDir.deleteSync(recursive: true);
  });
}
