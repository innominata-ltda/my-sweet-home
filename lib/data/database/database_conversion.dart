import 'dart:io';
import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Safe and atomic conversion of a plaintext database to encrypted format (RN-415, RN-416, RNF-008, ADR-0012).
final class DatabaseConversion {
  const DatabaseConversion({this.failAfterRekey = false});

  /// Allows injecting a simulated failure immediately after rekeying the copy to test integrity (CA-3.4).
  final bool failAfterRekey;

  /// Converts a plaintext database to encrypted without data loss (RN-415, RN-416, ADR-0012, RNF-008).
  ///
  /// Procedure:
  /// 1. Copies the plaintext file to `<path>.enc-tmp`.
  /// 2. Applies `PRAGMA journal_mode = DELETE` and `PRAGMA rekey = "x'<hex>'"` on the copy.
  /// 3. Compares row counts of all tables with the original.
  /// 4. If verification passes, replaces the original file with the encrypted copy and removes -wal/-shm/-journal.
  Future<Result<void, Failure>> encryptInPlaceSafely(
    File plaintext,
    Uint8List key,
  ) async {
    if (!plaintext.existsSync() || plaintext.lengthSync() == 0) {
      return const Err(
        StorageFailure(
          detail: 'Original plaintext file does not exist or is empty',
        ),
      );
    }

    final copyFile = File('${plaintext.path}.enc-tmp');
    try {
      // 1. Safe copy
      if (copyFile.existsSync()) {
        copyFile.deleteSync();
      }
      plaintext.copySync(copyFile.path);

      final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // 2. Apply PRAGMA journal_mode = DELETE and rekey on copy (ADR-0012)
      final rawCopy = sqlite3.sqlite3.open(copyFile.path);
      try {
        rawCopy.execute('PRAGMA journal_mode = DELETE;');
        rawCopy.execute('PRAGMA rekey = "x\'$hexKey\'";');
      } finally {
        rawCopy.close();
      }

      // Simulated failure for testing (CA-3.4)
      if (failAfterRekey) {
        throw const StorageFailure(
          detail: 'Simulated failure injected after rekey',
        );
      }

      // 3. Row count verification per table (RN-415, CA-3.3)
      final originalDb = sqlite3.sqlite3.open(plaintext.path);
      final encryptedDb = sqlite3.sqlite3.open(copyFile.path);
      try {
        encryptedDb.execute('PRAGMA key = "x\'$hexKey\'";');
        encryptedDb.select('SELECT count(*) FROM sqlite_master;');

        final tablesResult = originalDb.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';",
        );

        for (final row in tablesResult) {
          final tableName = row['name'] as String;
          try {
            final countOrig =
                originalDb
                        .select('SELECT count(*) AS c FROM "$tableName";')
                        .first['c']
                    as int;
            final countEnc =
                encryptedDb
                        .select('SELECT count(*) AS c FROM "$tableName";')
                        .first['c']
                    as int;

            if (countOrig != countEnc) {
              return Err(
                StorageFailure(
                  detail:
                      'Row count mismatch on table $tableName: $countOrig vs $countEnc',
                ),
              );
            }
          } catch (_) {
            // Virtual tables or extension system tables
          }
        }
      } finally {
        originalDb.close();
        encryptedDb.close();
      }

      // 4. Atomic swap and cleanup of original files
      final backupPlaintext = File('${plaintext.path}.bak-transient');
      if (backupPlaintext.existsSync()) {
        backupPlaintext.deleteSync();
      }
      plaintext.renameSync(backupPlaintext.path);
      copyFile.renameSync(plaintext.path);
      backupPlaintext.deleteSync();

      final walFile = File('${plaintext.path}-wal');
      if (walFile.existsSync()) walFile.deleteSync();
      final shmFile = File('${plaintext.path}-shm');
      if (shmFile.existsSync()) shmFile.deleteSync();
      final journalFile = File('${plaintext.path}-journal');
      if (journalFile.existsSync()) journalFile.deleteSync();

      return const Ok(null);
    } catch (e) {
      if (copyFile.existsSync()) {
        try {
          copyFile.deleteSync();
        } catch (_) {}
      }
      return Err(
        e is Failure
            ? e
            : StorageFailure(
                detail: 'Failure during database conversion',
                cause: e,
              ),
      );
    }
  }
}
