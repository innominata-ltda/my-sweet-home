import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';

void main() {
  group(
    'CA-4.6 / RN-431: Consolidated limits in a single place (SecurityLimits)',
    () {
      test('SecurityLimits has all specified limits with default values', () {
        const limits = SecurityLimits();

        expect(limits.maxBackupBytes, equals(200 * 1024 * 1024));
        expect(limits.kdfMemoryKibMin, equals(19456));
        expect(limits.kdfMemoryKibMax, equals(65536));
        expect(limits.kdfIterationsMin, equals(2));
        expect(limits.kdfIterationsMax, equals(10));
        expect(limits.kdfParallelismMin, equals(1));
        expect(limits.kdfParallelismMax, equals(4));
        expect(limits.kdfHashLength, equals(32));
        expect(limits.lanPreAuthMaxBytes, equals(4 * 1024));
        expect(limits.lanPreAuthTimeout, equals(const Duration(seconds: 5)));
        expect(limits.lanMaxMessageBytes, equals(16 * 1024 * 1024));
        expect(limits.lanReadTimeout, equals(const Duration(seconds: 30)));
        expect(limits.lanMaxConcurrentConnections, equals(2));
        expect(limits.lanMaxAuthFailures, equals(5));
        expect(limits.lanAuthFailureWindow, equals(const Duration(minutes: 1)));
        expect(limits.lanBanDuration, equals(const Duration(minutes: 5)));
        expect(limits.discoveryTagRotation, equals(const Duration(hours: 24)));
        expect(limits.tombstoneRetention, equals(const Duration(days: 90)));
        expect(
          limits.searchDebounce,
          equals(const Duration(milliseconds: 250)),
        );
        expect(limits.diagnosticLogMaxBytes, equals(1024 * 1024));
      });

      test(
        'no security/performance limit literal outside security_limits.dart',
        () {
          final forbiddenPatterns = <RegExp>[
            RegExp(r'200\s*\*\s*1024\s*\*\s*1024'),
            RegExp(r'16\s*\*\s*1024\s*\*\s*1024'),
            RegExp(r'\b19456\b'),
            RegExp(r'\b65536\b'),
          ];

          final violations = <String>[];
          final libDir = Directory('lib');

          for (final entity in libDir.listSync(recursive: true)) {
            if (entity is! File || !entity.path.endsWith('.dart')) continue;
            final normalizedPath = entity.path.replaceAll('\\', '/');

            // Ignores security_limits.dart and generated files
            if (normalizedPath.contains('core/config/security_limits.dart')) {
              continue;
            }
            if (normalizedPath.endsWith('.g.dart')) {
              continue;
            }

            final lines = entity.readAsLinesSync();
            for (var i = 0; i < lines.length; i++) {
              final line = lines[i];
              final trimmed = line.trim();
              if (trimmed.startsWith('//') || trimmed.startsWith('/*')) {
                continue;
              }

              for (final pat in forbiddenPatterns) {
                if (pat.hasMatch(line)) {
                  violations.add(
                    '$normalizedPath:${i + 1} violates RN-431 ($pat)',
                  );
                }
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'Limit literals found outside of security_limits.dart:\n'
                '${violations.join('\n')}',
          );
        },
      );
    },
  );
}
