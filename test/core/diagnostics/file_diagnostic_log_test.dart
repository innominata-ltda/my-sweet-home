import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';
import 'package:my_sweet_home/core/diagnostics/file_diagnostic_log.dart';

void main() {
  group('CA-4.9 / RN-434 / RN-435: FileDiagnosticLog', () {
    late Directory tempDir;
    late File logFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('msh_diag_test_');
      logFile = File('${tempDir.path}/diagnostic.log');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('records and retrieves entries in chronological order', () async {
      final log = FileDiagnosticLog(file: logFile);

      final e1 = DiagnosticEntry(
        atUtc: DateTime.utc(2026, 10, 29, 10, 0, 0),
        level: DiagnosticLevel.warning,
        origin: 'backup.import',
        errorType: 'ValidationFailure',
      );
      final e2 = DiagnosticEntry(
        atUtc: DateTime.utc(2026, 10, 29, 10, 5, 0),
        level: DiagnosticLevel.error,
        origin: 'sync.lan',
        errorType: 'NetworkFailure',
      );

      await log.record(e1);
      await log.record(e2);

      final entries = await log.entries();
      expect(entries.length, equals(2));
      expect(entries[0].origin, equals('backup.import'));
      expect(entries[1].origin, equals('sync.lan'));
    });

    test('wipe remove o arquivo de log e esvazia entradas', () async {
      final log = FileDiagnosticLog(file: logFile);
      await log.record(
        DiagnosticEntry(
          atUtc: DateTime.utc(2026, 10, 29),
          level: DiagnosticLevel.error,
          origin: 'test',
          errorType: 'Error',
        ),
      );

      expect(logFile.existsSync(), isTrue);
      expect((await log.entries()).isNotEmpty, isTrue);

      await log.wipe();

      expect(logFile.existsSync(), isFalse);
      expect(await log.entries(), isEmpty);
    });

    test(
      'CA-4.9 / RN-434: descarta entradas mais antigas quando excede o limite',
      () async {
        // Limite artificialmente pequeno para o teste: 500 bytes
        const testLimit = 500;
        final limits = const SecurityLimits(diagnosticLogMaxBytes: testLimit);
        final log = FileDiagnosticLog(file: logFile, limits: limits);

        // Cada entrada com frames tem cerca de ~120 bytes.
        // Gravando 15 entradas, ultrapassa 500 bytes e deve podar as antigas.
        for (var i = 0; i < 15; i++) {
          await log.record(
            DiagnosticEntry(
              atUtc: DateTime.utc(2026, 10, 29, 10, i, 0),
              level: DiagnosticLevel.error,
              origin: 'task_$i',
              errorType: 'Error$i',
            ),
          );
        }

        final fileLength = await logFile.length();
        expect(fileLength, lessThanOrEqualTo(testLimit));

        final entries = await log.entries();
        expect(entries.isNotEmpty, isTrue);
        // As entradas mais recentes devem ser preservadas
        expect(entries.last.origin, equals('task_14'));
        // A primeira gravada (task_0) deve ter sido podada
        expect(entries.any((e) => e.origin == 'task_0'), isFalse);
      },
    );
  });
}
