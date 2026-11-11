import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CA-4.3 / RN-421: presentation/ does not reference .detail, .cause, or failure.toString()', () {
    test('no file in presentation/ exposes internal failure details', () {
      final forbiddenPatterns = <RegExp>[
        RegExp(r'\bfailure\.detail\b'),
        RegExp(r'\bfailure\.cause\b'),
        RegExp(r'\bfailure\.toString\(\)'),
        RegExp(r'StorageFailure\([^\)]*\)\s*:\s*final\s+detail'),
      ];

      final violations = <String>[];
      final libDir = Directory('lib');

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalizedPath = entity.path.replaceAll('\\', '/');

        if (!normalizedPath.contains('/presentation/')) continue;
        if (normalizedPath.endsWith('.g.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

          for (final pat in forbiddenPatterns) {
            if (pat.hasMatch(line)) {
              violations.add('$normalizedPath:${i + 1} viola CA-4.3 ($pat)');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Failure detail leak violations found in presentation/:\n'
            '${violations.join('\n')}',
      );
    });
  });
}
