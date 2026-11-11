import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/cloud_ocr_consent_evaluator.dart';
import 'package:my_sweet_home/features/ocr/domain/models/manual_purchase_args.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/ocr_fallback_handler.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_photo_cleaner.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_capture_screen.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/cloud_ocr_consent_dialog.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/ocr_total_failure_dialog.dart';

import '../../fakes/fake_file_store.dart';
import '../../fakes/fake_image_picker.dart';
import '../../fakes/fake_image_quality_checker.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_text_recognizer_adapter.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Modo avião ativo (RNF-005, CA-1.1): nenhuma requisição de rede permitida.',
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('T-V2 - CA-1.1 & RNF-005: OCR processing without network requests (HttpOverrides)', () {
    late FakeSettingsRepository settingsRepo;

    setUp(() {
      settingsRepo = FakeSettingsRepository();
    });

    test('CA-1.1: OcrDocument is processed on-device by ReceiptParser without HTTP connections', () async {
      final doc = OcrDocument(
        lines: const [
          OcrTextLine(
            text: 'MERCADO OFFLINE LTDA',
            confidence: 0.98,
            boundingBox: OcrBoundingBox(
              top: 10,
              left: 10,
              right: 380,
              bottom: 30,
            ),
          ),
          OcrTextLine(
            text: 'CNPJ: 45.543.915/0001-81',
            confidence: 0.95,
            boundingBox: OcrBoundingBox(
              top: 35,
              left: 10,
              right: 250,
              bottom: 50,
            ),
          ),
          OcrTextLine(
            text: 'DATA: 21/09/2026 14:30:00',
            confidence: 0.95,
            boundingBox: OcrBoundingBox(
              top: 55,
              left: 10,
              right: 250,
              bottom: 70,
            ),
          ),
          OcrTextLine(
            text: 'CÓDIGO DESCRIÇÃO QTD VL UN VL TOTAL',
            confidence: 0.96,
            boundingBox: OcrBoundingBox(
              top: 80,
              left: 10,
              right: 380,
              bottom: 95,
            ),
          ),
          OcrTextLine(
            text: '001 ARROZ AGULH 5KG 1 UN X 25,00 25,00',
            confidence: 0.92,
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 380,
              bottom: 120,
            ),
          ),
          OcrTextLine(
            text: 'TOTAL R\$ 25,00',
            confidence: 0.95,
            boundingBox: OcrBoundingBox(
              top: 180,
              left: 10,
              right: 380,
              bottom: 200,
            ),
          ),
        ],
        imageWidth: 400,
        imageHeight: 600,
      );

      final parser = const DefaultReceiptParser();
      final draft = parser.parse(doc);

      expect(draft.store.name, equals('MERCADO OFFLINE LTDA'));
      expect(draft.items, hasLength(1));
      expect(draft.items.first.rawDescription, equals('ARROZ AGULH 5KG'));
      expect(draft.total, equals(const Money(2500)));
    });

    testWidgets(
      'CA-1.1: Screen capture and transition to review UI occur 100% offline',
      (tester) async {
        final fakePicker = FakeImagePickerPort()
          ..galleryResultPath = '/tmp/offline_receipt.jpg';
        final fakeQualityChecker = FakeImageQualityChecker()
          ..reportToReturn = const QualityReport(
            isAcceptable: true,
            issues: [],
          );

        String? capturedPath;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
              onImageCaptured: (path) => capturedPath = path,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Escanear nota fiscal'), findsOneWidget);

        await tester.tap(find.byIcon(AppIcons.gallery));
        await tester.pumpAndSettle();

        expect(capturedPath, equals('/tmp/offline_receipt.jpg'));

        final sampleDraft = ReceiptDraft(
          store: const StoreDraft(
            name: 'Supermercado Offline',
            cnpj: '45.543.915/0001-81',
            isCnpjValid: true,
          ),
          purchasedAt: DateTime(2026, 9, 21, 14, 30),
          items: [
            ReceiptItemDraft(
              rawDescription: 'FEIJAO PRETO 1KG',
              quantity: const Quantity(1000, Unit.un),
              unitPrice: const Money(850),
              totalPrice: const Money(850),
              confidence: 0.95,
              selected: true,
            ),
          ],
          total: const Money(850),
          confidence: 0.95,
        );

        ReceiptDraft? savedDraft;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OcrReviewScreen(
              draft: sampleDraft,
              onSave: (draft) => savedDraft = draft,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Supermercado Offline'), findsOneWidget);
        expect(find.text('FEIJAO PRETO 1KG'), findsOneWidget);

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(savedDraft, equals(sampleDraft));
      },
    );

    test('CA-1.1 & CA-1.3: Denied cloud_ocr consent (default) does not request network when evaluating low confidence', () async {
      settingsRepo.cloudOcrAllowed = false;
      final evaluator = CloudOcrConsentEvaluator(
        settingsRepository: settingsRepo,
      );

      final action = await evaluator.evaluate(averageConfidence: 0.40);

      expect(action, equals(CloudOcrConsentAction.suggestNewPhoto));
    });

    testWidgets(
      'CA-1.3 & RN-207: Consent dialog with cloudOcrAllowed=false suggests new photo and DOES NOT include cloud or network options',
      (tester) async {
        bool retakeCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CloudOcrConsentDialog(
                action: CloudOcrConsentAction.suggestNewPhoto,
                onContinueLocal: () {},
                onRetake: () => retakeCalled = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Leitura com baixa precisão'), findsOneWidget);
        expect(find.textContaining('nuvem'), findsNothing);
        expect(find.textContaining('internet'), findsNothing);

        await tester.tap(find.text('Tirar outra foto'));
        await tester.pumpAndSettle();

        expect(retakeCalled, isTrue);
      },
    );

    test('CA-1.1 & CA-7.1: Total OCR failure routes to offline manual entry with attached photo', () async {
      const handler = OcrFallbackHandler();
      final fakeRecognizer = FakeTextRecognizerAdapter(
        failureToReturn: const OcrFailure(message: 'Falha no motor local'),
      );

      final result = await fakeRecognizer.recognizeFile('/tmp/cupom_falho.jpg');
      final fallbackArgs = handler.evaluateResult(
        result,
        imagePath: '/tmp/cupom_falho.jpg',
      );

      expect(fallbackArgs.isTotalFailure, isTrue);
      expect(fallbackArgs.attachedImagePath, equals('/tmp/cupom_falho.jpg'));
      expect(ManualPurchaseArgs.targetRoute, equals('/compras/nova'));
    });

    testWidgets(
      'CA-7.1: OcrTotalFailureDialog displays friendly message and manual entry option without network traffic',
      (tester) async {
        bool manualCalled = false;

        const args = ManualPurchaseArgs(
          attachedImagePath: '/tmp/cupom_offline.jpg',
          userFriendlyMessage: 'Não foi possível ler os dados da nota.',
          isTotalFailure: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OcrTotalFailureDialog(
                args: args,
                onManualEntry: () => manualCalled = true,
                onRetake: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lançar manualmente'), findsOneWidget);
        await tester.tap(find.text('Lançar manualmente'));
        await tester.pumpAndSettle();

        expect(manualCalled, isTrue);
      },
    );

    test('CA-1.1 & CA-6.1: Deleting private photo post-processing occurs locally on file system', () async {
      final fileStore = FakeFileStore();
      final photoPath = await fileStore.save(
        Uint8List.fromList([1, 2, 3]),
        name: 'photo_off.jpg',
      );

      final cleaner = ReceiptPhotoCleaner(
        fileStorePort: fileStore,
        settingsRepository: settingsRepo,
      );

      final cleanupResult = await cleaner.cleanUpPhoto(photoPath);

      expect(cleanupResult, equals(PhotoCleanupResult.deleted));
      expect(await fileStore.exists(photoPath), isFalse);
    });
  });
}
