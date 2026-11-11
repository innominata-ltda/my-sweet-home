import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/manual_purchase_args.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/ocr_fallback_handler.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/ocr_total_failure_dialog.dart';

void main() {
  group(
    'OcrFallbackHandler & ManualPurchaseArgs (T-21, RF-047, RN-203, CA-7.1)',
    () {
      const handler = OcrFallbackHandler();

      test('CA-7.1: Empty OcrDocument results in total failure with route /compras/nova and attached photo', () {
        final emptyDoc = OcrDocument();
        const imagePath = '/path/to/receipt_photo.jpg';

        final args = handler.evaluateDocument(emptyDoc, imagePath: imagePath);

        expect(args.isTotalFailure, isTrue);
        expect(args.attachedImagePath, equals(imagePath));
        expect(ManualPurchaseArgs.targetRoute, equals('/compras/nova'));
        expect(
          args.userFriendlyMessage,
          contains('Não foi possível ler os dados da nota'),
        );
      });

      test('CA-7.1: No technical error message is exposed in OcrFailure', () {
        const failure = OcrFailure(
          message: 'Internal MLKitException: Failed to initialize native detector code 5042',
        );
        final result = Err<OcrDocument, OcrFailure>(failure);
        const imagePath = '/storage/emulated/0/DCIM/cupom.jpg';

        final args = handler.evaluateResult(result, imagePath: imagePath);

        expect(args.isTotalFailure, isTrue);
        expect(args.attachedImagePath, equals(imagePath));
        expect(args.userFriendlyMessage, isNot(contains('MLKitException')));
        expect(args.userFriendlyMessage, isNot(contains('code 5042')));
        expect(
          args.userFriendlyMessage,
          contains('Não foi possível ler os dados da nota'),
        );
      });

      test('RN-203: Preserves partial draft obtained prior to failure', () {
        final partialDraft = ReceiptDraft(
          store: const StoreDraft(name: 'Mercado Parcial', cnpj: null),
          items: const [],
          confidence: 0.2,
        );

        final args = handler.evaluateDraft(
          partialDraft,
          imagePath: '/tmp/receipt.jpg',
        );

        expect(args.isTotalFailure, isTrue);
        expect(args.partialDraft, equals(partialDraft));
        expect(args.partialDraft?.store.name, equals('Mercado Parcial'));
        expect(args.attachedImagePath, equals('/tmp/receipt.jpg'));
      });

      test('OcrFallbackHandler.evaluateDraft identifies draft with items as not being total failure', () {
        final validDraft = ReceiptDraft(
          store: const StoreDraft(name: 'Supermercado Exemplo', cnpj: null),
          items: const [],
          confidence: 0.9,
        );

        final args = handler.evaluateDraft(
          validDraft,
          imagePath: '/tmp/receipt.jpg',
        );

        expect(args.isTotalFailure, isFalse);
      });

      test('ManualPurchaseArgs equality and hashCode work correctly', () {
        const args1 = ManualPurchaseArgs(
          attachedImagePath: '/path/1.jpg',
          userFriendlyMessage: 'Mensagem',
          isTotalFailure: true,
        );
        const args2 = ManualPurchaseArgs(
          attachedImagePath: '/path/1.jpg',
          userFriendlyMessage: 'Mensagem',
          isTotalFailure: true,
        );
        const args3 = ManualPurchaseArgs(
          attachedImagePath: '/path/2.jpg',
          userFriendlyMessage: 'Outra',
          isTotalFailure: false,
        );

        expect(args1, equals(args2));
        expect(args1.hashCode, equals(args2.hashCode));
        expect(args1, isNot(equals(args3)));
        expect(args1.toString(), contains('/path/1.jpg'));
      });
    },
  );

  group('OcrTotalFailureDialog (T-21, RN-203, CA-7.1)', () {
    testWidgets('displays friendly message and attached photo indicator', (
      tester,
    ) async {
      const args = ManualPurchaseArgs(
        attachedImagePath: '/storage/cupom_123.jpg',
        userFriendlyMessage: 'Não foi possível ler os dados da nota fiscal.',
        isTotalFailure: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrTotalFailureDialog(
              args: args,
              onManualEntry: () {},
              onRetake: () {},
            ),
          ),
        ),
      );

      expect(find.text('Não foi possível ler a nota'), findsOneWidget);
      expect(
        find.text('Não foi possível ler os dados da nota fiscal.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Foto anexada: /storage/cupom_123.jpg'),
        findsOneWidget,
      );
      expect(find.text('Lançar manualmente'), findsOneWidget);
      expect(find.text('Tirar outra foto'), findsOneWidget);
    });

    testWidgets('triggers onManualEntry callback when tapping manual entry', (
      tester,
    ) async {
      bool manualEntryCalled = false;
      bool retakeCalled = false;

      const args = ManualPurchaseArgs(
        attachedImagePath: '/storage/cupom_123.jpg',
        userFriendlyMessage: 'Mensagem amigável',
        isTotalFailure: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrTotalFailureDialog(
              args: args,
              onManualEntry: () => manualEntryCalled = true,
              onRetake: () => retakeCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Lançar manualmente'));
      await tester.pump();

      expect(manualEntryCalled, isTrue);
      expect(retakeCalled, isFalse);
    });

    testWidgets('triggers onRetake callback when tapping retake photo', (
      tester,
    ) async {
      bool manualEntryCalled = false;
      bool retakeCalled = false;

      const args = ManualPurchaseArgs(
        attachedImagePath: '/storage/cupom_123.jpg',
        userFriendlyMessage: 'Mensagem amigável',
        isTotalFailure: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrTotalFailureDialog(
              args: args,
              onManualEntry: () => manualEntryCalled = true,
              onRetake: () => retakeCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tirar outra foto'));
      await tester.pump();

      expect(retakeCalled, isTrue);
      expect(manualEntryCalled, isFalse);
    });

    testWidgets('static show method displays dialog modal', (tester) async {
      bool manualTriggered = false;

      const args = ManualPurchaseArgs(
        attachedImagePath: '/storage/cupom_456.jpg',
        userFriendlyMessage: 'Não foi possível ler a nota.',
        isTotalFailure: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OcrTotalFailureDialog.show(
                    context: context,
                    args: args,
                    onManualEntry: () => manualTriggered = true,
                  );
                },
                child: const Text('Abrir Erro'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Erro'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível ler a nota'), findsOneWidget);

      await tester.tap(find.text('Lançar manualmente'));
      await tester.pumpAndSettle();

      expect(manualTriggered, isTrue);
      expect(find.text('Não foi possível ler a nota'), findsNothing);
    });
  });
}
