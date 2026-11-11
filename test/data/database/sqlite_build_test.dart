import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('SQLite build verification (T-I01)', () {
    test('sqlite version is >= 3.45 and cipher extension is active', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      final versionResult = db.select('SELECT sqlite_version() AS v');
      final versionStr = versionResult.first['v'] as String;
      final parts = versionStr.split('.').map(int.parse).toList();
      final major = parts[0];
      final minor = parts.length > 1 ? parts[1] : 0;
      expect(
        major > 3 || (major == 3 && minor >= 45),
        isTrue,
        reason: 'SQLite version must be >= 3.45, got $versionStr',
      );

      final cipherResult = db.select('PRAGMA cipher');
      expect(
        cipherResult,
        isNotEmpty,
        reason: 'PRAGMA cipher must respond indicating sqlite3mc is bundled',
      );
    });
  });
}
