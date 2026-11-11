import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  group('Database Pragmas (T-I02 / CA-5.3)', () {
    late Directory tempDir;
    late File dbFile;
    late AppDatabase db;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('db_pragmas_test_');
      dbFile = File('${tempDir.path}/test.db');
      db = AppDatabase(NativeDatabase(dbFile));
      // Force connection open
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('configures WAL journal mode and normal synchronous mode', () async {
      final journalModeResult = await db
          .customSelect('PRAGMA journal_mode;')
          .getSingle();
      final journalMode = journalModeResult.data['journal_mode'] as String;
      expect(
        journalMode.toLowerCase(),
        equals('wal'),
        reason: 'CA-5.3: PRAGMA journal_mode must be wal',
      );

      final synchronousResult = await db
          .customSelect('PRAGMA synchronous;')
          .getSingle();
      final synchronous = synchronousResult.data['synchronous'] as int;
      expect(
        synchronous,
        equals(1),
        reason: 'CA-5.3: PRAGMA synchronous must be 1 (NORMAL)',
      );
    });
  });
}
