import 'package:flutter/material.dart' hide DiagnosticLevel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/error_boundary.dart';
import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_diagnostic_log.dart';

final throwingProvider = Provider<String>((ref) {
  throw Exception('Erro intencional no provider');
});

class FaultyWidget extends ConsumerWidget {
  const FaultyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(throwingProvider);
    return const Text('Nunca deve aparecer');
  }
}

void main() {
  testWidgets('CA-7.1: Build exception displays AppErrorState', (tester) async {
    final originalBuilder = ErrorWidget.builder;
    setupGlobalErrorHandling();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: FaultyWidget())),
      ),
    );

    // As Flutter test framework handles exceptions differently,
    // ErrorWidget.builder is triggered. We need to pump a frame
    // e verificar se o AppErrorState aparece.

    // The error will be printed to console by tester, so
    // ignore error logs for this test.
    final exception = tester.takeException();
    expect(exception, isNotNull);

    // O FlutterTest substitui o ErrorWidget por um que renderiza o erro.
    // In our setupGlobalErrorHandling, we redefine the builder.
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Ops! Ocorreu um erro inesperado.'), findsOneWidget);

    ErrorWidget.builder = originalBuilder;
  });

  testWidgets(
    'CA-4.7 / RN-432: setupGlobalErrorHandling records failure in diagnostic log',
    (tester) async {
      final originalBuilder = ErrorWidget.builder;
      final fakeLog = FakeDiagnosticLog();
      final fakeClock = FakeClock(DateTime.utc(2026, 10, 29, 15, 30));

      setupGlobalErrorHandling(log: fakeLog, clock: fakeClock);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: FaultyWidget())),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isNotNull);
      await tester.pump();

      final entries = await fakeLog.entries();
      expect(entries.length, equals(1));
      expect(entries.first.origin, equals('ui.error_boundary'));
      expect(entries.first.level, equals(DiagnosticLevel.error));
      expect(entries.first.atUtc, equals(DateTime.utc(2026, 10, 29, 15, 30)));

      ErrorWidget.builder = originalBuilder;
    },
  );
}
