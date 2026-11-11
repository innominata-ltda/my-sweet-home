import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/quality_warning_dialog.dart';

void main() {
  group('QualityWarningDialog (T-13, RN-204)', () {
    testWidgets('displays title message and reported issues', (tester) async {
      const report = QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.blur, QualityIssue.tooDark],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QualityWarningDialog(
              report: report,
              onRetake: () {},
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Foto com baixa qualidade'), findsOneWidget);
      expect(find.textContaining('Imagem desfocada'), findsOneWidget);
      expect(find.textContaining('Iluminação muito baixa'), findsOneWidget);
      expect(find.text('Tirar outra foto'), findsOneWidget);
      expect(find.text('Continuar mesmo assim'), findsOneWidget);
    });

    testWidgets('calls onRetake callback when tapping retake photo', (
      tester,
    ) async {
      bool retakeCalled = false;
      bool continueCalled = false;

      const report = QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.badFraming],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QualityWarningDialog(
              report: report,
              onRetake: () => retakeCalled = true,
              onContinue: () => continueCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tirar outra foto'));
      await tester.pump();

      expect(retakeCalled, isTrue);
      expect(continueCalled, isFalse);
    });

    testWidgets('calls onContinue callback when tapping continue anyway', (
      tester,
    ) async {
      bool retakeCalled = false;
      bool continueCalled = false;

      const report = QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.tooBright],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QualityWarningDialog(
              report: report,
              onRetake: () => retakeCalled = true,
              onContinue: () => continueCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continuar mesmo assim'));
      await tester.pump();

      expect(continueCalled, isTrue);
      expect(retakeCalled, isFalse);
    });

    testWidgets('static show method opens dialog in context', (tester) async {
      bool retakeTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  QualityWarningDialog.show(
                    context: context,
                    report: const QualityReport(
                      isAcceptable: false,
                      issues: [QualityIssue.invalidImage],
                    ),
                    onRetake: () => retakeTriggered = true,
                    onContinue: () {},
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Foto com baixa qualidade'), findsOneWidget);
      expect(
        find.textContaining('Não foi possível decodificar'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tirar outra foto'));
      await tester.pumpAndSettle();

      expect(retakeTriggered, isTrue);
      expect(find.text('Foto com baixa qualidade'), findsNothing);
    });
  });
}
