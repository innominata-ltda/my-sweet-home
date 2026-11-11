import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/cloud_ocr_consent_evaluator.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/cloud_ocr_consent_dialog.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  group('CloudOcrConsentEvaluator (T-22, RN-190, RN-207, CA-1.2, CA-1.3)', () {
    late FakeSettingsRepository fakeSettings;

    setUp(() {
      fakeSettings = FakeSettingsRepository();
    });

    test(
      'returns proceedLocal when average confidence is sufficient (>= 0.6)',
      () async {
        fakeSettings.cloudOcrAllowed = false;
        final evaluator = CloudOcrConsentEvaluator(
          settingsRepository: fakeSettings,
        );

        final action = await evaluator.evaluate(averageConfidence: 0.85);

        expect(action, equals(CloudOcrConsentAction.proceedLocal));
      },
    );

    test('returns proceedLocal when confidence >= 0.6 even if cloudOcrAllowed is true', () async {
      fakeSettings.cloudOcrAllowed = true;
      final evaluator = CloudOcrConsentEvaluator(
        settingsRepository: fakeSettings,
      );

      final action = await evaluator.evaluate(averageConfidence: 0.6);

      expect(action, equals(CloudOcrConsentAction.proceedLocal));
    });

    test('CA-1.2: returns requestOperationConfirmation when confidence < 0.6 AND prior consent granted', () async {
      fakeSettings.cloudOcrAllowed = true;
      final evaluator = CloudOcrConsentEvaluator(
        settingsRepository: fakeSettings,
      );

      final action = await evaluator.evaluate(averageConfidence: 0.45);

      expect(
        action,
        equals(CloudOcrConsentAction.requestOperationConfirmation),
      );
    });

    test('CA-1.3: returns suggestNewPhoto when confidence < 0.6 AND prior consent denied', () async {
      fakeSettings.cloudOcrAllowed = false;
      final evaluator = CloudOcrConsentEvaluator(
        settingsRepository: fakeSettings,
      );

      final action = await evaluator.evaluate(averageConfidence: 0.45);

      expect(action, equals(CloudOcrConsentAction.suggestNewPhoto));
    });

    test('respects custom confidence threshold in constructor', () async {
      fakeSettings.cloudOcrAllowed = true;
      final evaluator = CloudOcrConsentEvaluator(
        settingsRepository: fakeSettings,
        confidenceThreshold: 0.75,
      );

      final action1 = await evaluator.evaluate(averageConfidence: 0.70);
      final action2 = await evaluator.evaluate(averageConfidence: 0.80);

      expect(
        action1,
        equals(CloudOcrConsentAction.requestOperationConfirmation),
      );
      expect(action2, equals(CloudOcrConsentAction.proceedLocal));
    });
  });

  group(
    'CloudOcrConsentDialog (T-22, RF-043, RN-190, RN-207, CA-1.2, CA-1.3)',
    () {
      testWidgets(
        'CA-1.2: with prior consent granted, requests explicit confirmation during operation',
        (tester) async {
          bool confirmCloudCalled = false;
          bool continueLocalCalled = false;
          bool retakeCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CloudOcrConsentDialog(
                  action: CloudOcrConsentAction.requestOperationConfirmation,
                  onConfirmCloud: () => confirmCloudCalled = true,
                  onContinueLocal: () => continueLocalCalled = true,
                  onRetake: () => retakeCalled = true,
                ),
              ),
            ),
          );

          expect(find.text('Melhorar leitura na nuvem?'), findsOneWidget);
          expect(
            find.textContaining(
              'deseja tentar melhorar a leitura enviando esta nota',
            ),
            findsOneWidget,
          );
          expect(find.text('Usar OCR na nuvem'), findsOneWidget);
          expect(find.text('Continuar sem nuvem'), findsOneWidget);
          expect(find.text('Tirar outra foto'), findsOneWidget);

          await tester.tap(find.text('Usar OCR na nuvem'));
          await tester.pump();

          expect(confirmCloudCalled, isTrue);
          expect(continueLocalCalled, isFalse);
          expect(retakeCalled, isFalse);
        },
      );

      testWidgets(
        'CA-1.2: triggers onContinueLocal callback when refusing cloud submission during operation',
        (tester) async {
          bool confirmCloudCalled = false;
          bool continueLocalCalled = false;
          bool retakeCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CloudOcrConsentDialog(
                  action: CloudOcrConsentAction.requestOperationConfirmation,
                  onConfirmCloud: () => confirmCloudCalled = true,
                  onContinueLocal: () => continueLocalCalled = true,
                  onRetake: () => retakeCalled = true,
                ),
              ),
            ),
          );

          await tester.tap(find.text('Continuar sem nuvem'));
          await tester.pump();

          expect(continueLocalCalled, isTrue);
          expect(confirmCloudCalled, isFalse);
          expect(retakeCalled, isFalse);
        },
      );

      testWidgets(
        'CA-1.3: with consent denied, suggests new photo and DOES NOT offer enabling cloud OCR',
        (tester) async {
          bool continueLocalCalled = false;
          bool retakeCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CloudOcrConsentDialog(
                  action: CloudOcrConsentAction.suggestNewPhoto,
                  onContinueLocal: () => continueLocalCalled = true,
                  onRetake: () => retakeCalled = true,
                ),
              ),
            ),
          );

          expect(find.text('Leitura com baixa precisão'), findsOneWidget);
          expect(
            find.textContaining('Recomendamos tirar uma nova foto'),
            findsOneWidget,
          );
          expect(find.text('Tirar outra foto'), findsOneWidget);
          expect(find.text('Continuar com estes dados'), findsOneWidget);

          // RN-207 & CA-1.3: MUST NOT offer enabling or using cloud OCR
          expect(
            find.textContaining('nuvem', findRichText: true),
            findsNothing,
          );
          expect(
            find.textContaining('cloud', findRichText: true),
            findsNothing,
          );
          expect(
            find.textContaining('internet', findRichText: true),
            findsNothing,
          );

          await tester.tap(find.text('Tirar outra foto'));
          await tester.pump();

          expect(retakeCalled, isTrue);
          expect(continueLocalCalled, isFalse);
        },
      );

      testWidgets(
        'static show method displays dialog modal for operation confirmation',
        (tester) async {
          bool cloudConfirmed = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      CloudOcrConsentDialog.show(
                        context: context,
                        action:
                            CloudOcrConsentAction.requestOperationConfirmation,
                        onRetake: () {},
                        onContinueLocal: () {},
                        onConfirmCloud: () => cloudConfirmed = true,
                      );
                    },
                    child: const Text('Abrir Diálogo'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Abrir Diálogo'));
          await tester.pumpAndSettle();

          expect(find.text('Melhorar leitura na nuvem?'), findsOneWidget);

          await tester.tap(find.text('Usar OCR na nuvem'));
          await tester.pumpAndSettle();

          expect(cloudConfirmed, isTrue);
          expect(find.text('Melhorar leitura na nuvem?'), findsNothing);
        },
      );

      testWidgets(
        'static show method displays dialog modal for new photo suggestion',
        (tester) async {
          bool retakeTriggered = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      CloudOcrConsentDialog.show(
                        context: context,
                        action: CloudOcrConsentAction.suggestNewPhoto,
                        onRetake: () => retakeTriggered = true,
                        onContinueLocal: () {},
                      );
                    },
                    child: const Text('Abrir Diálogo'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Abrir Diálogo'));
          await tester.pumpAndSettle();

          expect(find.text('Leitura com baixa precisão'), findsOneWidget);

          await tester.tap(find.text('Tirar outra foto'));
          await tester.pumpAndSettle();

          expect(retakeTriggered, isTrue);
          expect(find.text('Leitura com baixa precisão'), findsNothing);
        },
      );
    },
  );
}
