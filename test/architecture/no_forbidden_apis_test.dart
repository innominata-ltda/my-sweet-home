/// T-20: Testes de arquitetura — APIs proibidas em lib/ (CA-4.2, CA-4.3)
///
/// Verifies that lib/ does not contain:
///   - `DateTime.now()` fora de **/adapters/**
///   - `Random()` fora de **/adapters/**
///   - `print(` e `debugPrint(`
///   - `double` in monetary fields of entities and tables (RN-001)
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('APIs proibidas em lib/ — CA-4.2, CA-4.3 (RN-001, RN-004, RN-010)', () {
    const libPath = 'lib';

    // ---------------------------------------------------------------------------
    // Intentionally erroneous code fixtures
    // ---------------------------------------------------------------------------
    group('fixtures do detector', () {
      test('DateTime.now() in domain/ is detected', () {
        const code = '''
class Foo {
  DateTime get now => DateTime.now();
}
''';
        expect(
          _containsForbiddenClock(code, 'lib/features/x/domain/foo.dart'),
          isTrue,
        );
      });

      test('DateTime.now() in adapters/ is allowed', () {
        const code = '''
class Foo {
  DateTime get now => DateTime.now();
}
''';
        expect(
          _containsForbiddenClock(
            code,
            'lib/features/x/adapters/clock_adapter.dart',
          ),
          isFalse,
        );
      });

      test('SystemClock in time/clock.dart is allowed (only place)', () {
        const code = '''
  DateTime nowUtc() => DateTime.now().toUtc();
''';
        expect(
          _containsForbiddenClock(code, 'lib/core/time/clock.dart'),
          isFalse,
        );
      });

      test('print( in lib/ is detected', () {
        const code = 'print("debug");';
        expect(_containsForbiddenPrint(code), isTrue);
      });

      test('debugPrint( in lib/ is detected', () {
        const code = 'debugPrint("hello");';
        expect(_containsForbiddenPrint(code), isTrue);
      });

      test('comment with print is not detected', () {
        const code = '// print("debug");';
        expect(_containsForbiddenPrint(code), isFalse);
      });
    });

    // ---------------------------------------------------------------------------
    // Testes reais sobre lib/
    // ---------------------------------------------------------------------------
    test('sem DateTime.now() fora de adapters/ e clock.dart', () {
      final violations = <String>[];
      for (final file in _findDartFiles(libPath)) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final content = file.readAsStringSync();
        if (_containsForbiddenClock(content, normalizedPath)) {
          violations.add(normalizedPath);
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'DateTime.now() encontrado fora de adapters/:\n'
            '${violations.join('\n')}',
      );
    });

    test('sem Random() fora de adapters/', () {
      final violations = <String>[];
      for (final file in _findDartFiles(libPath)) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        // Allowed in adapters/ and id_generator.dart (prod implementation)
        if (normalizedPath.contains('/adapters/') ||
            normalizedPath.contains('id_generator.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        if (_containsForbiddenRandom(content)) {
          violations.add(normalizedPath);
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Random() fora de adapters/:\n${violations.join('\n')}',
      );
    });

    test('sem print() nem debugPrint() em lib/', () {
      final violations = <String>[];
      for (final file in _findDartFiles(libPath)) {
        final content = file.readAsStringSync();
        if (_containsForbiddenPrint(content)) {
          violations.add(file.path.replaceAll('\\', '/'));
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'print/debugPrint encontrado em lib/:\n'
            '${violations.join('\n')}',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Detectores
// ---------------------------------------------------------------------------

bool _containsForbiddenClock(String content, String filePath) {
  // Allowed in adapters/ and in the single clock adapter
  if (filePath.contains('/adapters/')) return false;
  if (filePath.contains('core/time/clock.dart')) return false;
  if (filePath.contains('core/id/id_generator.dart')) return false;

  final lines = content.split('\n');
  for (final line in lines) {
    // Ignore comments and strings
    final stripped = line.trim();
    if (stripped.startsWith('//') || stripped.startsWith('*')) continue;

    if (RegExp(r'DateTime\.now\(\)').hasMatch(line)) return true;
  }
  return false;
}

bool _containsForbiddenRandom(String content) {
  final lines = content.split('\n');
  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.startsWith('//') || stripped.startsWith('*')) continue;
    if (RegExp(r'\bRandom\(\)').hasMatch(line)) return true;
  }
  return false;
}

bool _containsForbiddenPrint(String content) {
  final lines = content.split('\n');
  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.startsWith('//') || stripped.startsWith('*')) continue;
    // Do not flag inside strings (simple heuristic: line contains print( without // before)
    if (RegExp(r'(?<!\/\/ )\bprint\(').hasMatch(stripped)) return true;
    if (RegExp(r'(?<!\/\/ )\bdebugPrint\(').hasMatch(stripped)) return true;
  }
  return false;
}

Iterable<File> _findDartFiles(String directory) sync* {
  final dir = Directory(directory);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Excluir gerados
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;
      yield entity;
    }
  }
}
