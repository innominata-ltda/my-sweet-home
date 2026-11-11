import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';
import 'package:my_sweet_home/core/result/result.dart';

void main() {
  group('CA-4.7 / CA-4.8 / RN-432 / RN-433: DiagnosticEntry', () {
    test(
      'fromError sanitiza completamente detalhes de erro, sql, args e valores',
      () {
        final atUtc = DateTime.utc(2026, 10, 29, 12, 0, 0);
        final failure = StorageFailure(
          detail: 'Falha ao salvar Aluguel R\$ 1.500,00 (150000 centavos) em /data/user/0/app.db',
          cause: Exception(
            'SqliteException: INSERT INTO expenses VALUES ("Aluguel", 150000)',
          ),
        );
        final fakeStack = StackTrace.fromString('''
#0      ExpensesRepository.save (package:my_sweet_home/features/expenses/data/expenses_repository.dart:42:5)
#1      SaveExpenseUseCase.call (package:my_sweet_home/features/expenses/domain/save_expense.dart:18:10)
#2      _dispatch (dart:async/zone.dart:123:4)
''');

        final entry = DiagnosticEntry.fromError(
          atUtc: atUtc,
          level: DiagnosticLevel.error,
          origin: 'expenses.save',
          error: failure,
          stack: fakeStack,
        );

        expect(entry.atUtc, equals(atUtc));
        expect(entry.level, equals(DiagnosticLevel.error));
        expect(entry.origin, equals('expenses.save'));
        expect(entry.errorType, equals('StorageFailure'));
        expect(entry.frames.length, equals(2));
        expect(
          entry.frames[0],
          contains(
            'package:my_sweet_home/features/expenses/data/expenses_repository.dart:42:5',
          ),
        );
        expect(
          entry.frames[1],
          contains(
            'package:my_sweet_home/features/expenses/domain/save_expense.dart:18:10',
          ),
        );

        final encoded = entry.encode();

        // CA-4.8 / RN-433: No confidential data, user text, or financial amount
        expect(encoded.contains('Aluguel'), isFalse);
        expect(encoded.contains('1500'), isFalse);
        expect(encoded.contains('150000'), isFalse);
        expect(encoded.contains('1.500'), isFalse);
        expect(encoded.contains('/data/user/0/app.db'), isFalse);
        expect(encoded.contains('INSERT INTO'), isFalse);

        // Decoding preserves structure
        final decoded = DiagnosticEntry.decode(encoded);
        expect(decoded.atUtc, equals(atUtc));
        expect(decoded.level, equals(DiagnosticLevel.error));
        expect(decoded.origin, equals('expenses.save'));
        expect(decoded.errorType, equals('StorageFailure'));
        expect(decoded.frames, equals(entry.frames));
      },
    );

    test('limits stack frames to at most 8 package frames', () {
      final buffer = StringBuffer();
      for (var i = 1; i <= 20; i++) {
        buffer.writeln(
          '#$i      Func$i (package:my_sweet_home/core/x$i.dart:$i:$i)',
        );
      }
      final stack = StackTrace.fromString(buffer.toString());

      final entry = DiagnosticEntry.fromError(
        atUtc: DateTime.utc(2026, 10, 29),
        level: DiagnosticLevel.warning,
        origin: 'test.origin',
        error: Exception('qualquer coisa'),
        stack: stack,
      );

      expect(entry.frames.length, equals(8));
      expect(
        entry.frames.first,
        contains('package:my_sweet_home/core/x1.dart:1:1'),
      );
      expect(
        entry.frames.last,
        contains('package:my_sweet_home/core/x8.dart:8:8'),
      );
    });
  });
}
