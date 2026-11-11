import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';
import 'package:my_sweet_home/features/backup/presentation/wipe_all_data_screen.dart';

class FakeWipeAllDataUseCase implements WipeAllDataUseCase {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<void> call() async {
    callCount++;
    if (shouldFail) {
      throw Exception('Test failure');
    }
  }
}

void main() {
  group('SPEC-010 T-02 — WipeAllDataScreen Widget Test', () {
    late FakeWipeAllDataUseCase fakeUseCase;

    setUp(() {
      fakeUseCase = FakeWipeAllDataUseCase();
    });

    Widget buildTestApp() {
      return ProviderScope(
        child: MaterialApp(
          theme: lightTheme(),
          home: WipeAllDataScreen(wipeAllDataUseCase: fakeUseCase),
        ),
      );
    }

    testWidgets('displays title, warning, and main button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Apagar Tudo'), findsOneWidget);
      expect(find.textContaining('Atenção: Ação Irreversível'), findsOneWidget);
      expect(find.text('Apagar todos os dados'), findsOneWidget);
    });

    testWidgets('first dialog: cancel does not execute wipe', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apagar todos os dados'));
      await tester.pumpAndSettle();

      // First dialog visible
      expect(find.text('Confirmar exclusão de dados'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog closed and use case was not called
      expect(find.text('Confirmar exclusão de dados'), findsNothing);
      expect(fakeUseCase.callCount, equals(0));
    });

    testWidgets(
      'second dialog: cancel on final confirmation does not execute wipe',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apagar todos os dados'));
        await tester.pumpAndSettle();

        // Advance to second dialog
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Second dialog visible
        expect(find.text('Confirmação Final'), findsOneWidget);
        expect(find.text('Apagar tudo permanentemente'), findsOneWidget);

        // Tap Cancel on second dialog
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('Confirmação Final'), findsNothing);
        expect(fakeUseCase.callCount, equals(0));
      },
    );

    testWidgets(
      'double confirmation completed: destructive button (A11Y-5) executes wipe and displays success (RF-006, RN-233, CA-2.1)',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // 1. Tap main button
        await tester.tap(find.text('Apagar todos os dados'));
        await tester.pumpAndSettle();

        // 2. Confirmation 1: Tap Continue
        expect(find.text('Confirmar exclusão de dados'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // 3. Confirmation 2: Tap explicitly labeled destructive button (A11Y-5)
        expect(find.text('Confirmação Final'), findsOneWidget);
        final confirmBtn = find.text('Apagar tudo permanentemente');
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // 4. Verify wipe was called and success feedback is displayed
        expect(fakeUseCase.callCount, equals(1));
        expect(
          find.text('Todos os dados foram apagados permanentemente.'),
          findsOneWidget,
        );
      },
    );
  });
}
