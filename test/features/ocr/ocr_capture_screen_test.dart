import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_capture_screen.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/framing_guide_overlay.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/quality_warning_dialog.dart';

import '../../fakes/fake_image_picker.dart';
import '../../fakes/fake_image_quality_checker.dart';

void main() {
  group('FramingGuideOverlay (T-15, RF-040, A11Y-10)', () {
    testWidgets(
      'exibe instrução de enquadramento e semântica de acessibilidade',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FramingGuideOverlay(
                instructionText: 'Alinhe o cupom no retângulo',
              ),
            ),
          ),
        );

        expect(find.text('Alinhe o cupom no retângulo'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Guia de enquadramento de nota fiscal. Alinhe o cupom no retângulo',
          ),
          findsOneWidget,
        );
        handle.dispose();
      },
    );
  });

  group('OcrCaptureScreen (T-15, RF-040, A11Y-10, RN-204)', () {
    late FakeImagePickerPort fakePicker;
    late FakeImageQualityChecker fakeQualityChecker;

    setUp(() {
      fakePicker = FakeImagePickerPort();
      fakeQualityChecker = FakeImageQualityChecker();
    });

    testWidgets(
      'exibe elementos da UI: barra superior, guia, botões de galeria, foto e manual',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
            ),
          ),
        );

        expect(find.text('Escanear nota fiscal'), findsOneWidget);
        expect(find.byType(FramingGuideOverlay), findsOneWidget);

        // Bottom bar control buttons
        expect(find.text('Galeria'), findsOneWidget);
        expect(find.text('Manual'), findsOneWidget);
        expect(find.byIcon(AppIcons.camera), findsAtLeastNWidgets(1));
        expect(find.byIcon(AppIcons.gallery), findsOneWidget);
        expect(find.byIcon(AppIcons.edit), findsOneWidget);
      },
    );

    testWidgets(
      'alterna o ícone e estado do flash ao clicar no botão de flash',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
            ),
          ),
        );

        expect(find.byIcon(AppIcons.flashOff), findsOneWidget);

        await tester.tap(find.byIcon(AppIcons.flashOff));
        await tester.pump();

        expect(find.byIcon(AppIcons.flashOn), findsOneWidget);

        await tester.tap(find.byIcon(AppIcons.flashOn));
        await tester.pump();

        expect(find.byIcon(AppIcons.flashOff), findsOneWidget);
      },
    );

    testWidgets(
      'seleção da galeria com imagem aceitável aciona callback onImageCaptured',
      (tester) async {
        String? capturedPath;
        fakePicker.galleryResultPath = '/tmp/fake_gallery_receipt.jpg';
        fakeQualityChecker.reportToReturn = const QualityReport(
          isAcceptable: true,
          issues: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
              onImageCaptured: (path) => capturedPath = path,
            ),
          ),
        );

        await tester.tap(find.byIcon(AppIcons.gallery));
        await tester.pumpAndSettle();

        expect(fakePicker.galleryCallCount, equals(1));
        expect(capturedPath, equals('/tmp/fake_gallery_receipt.jpg'));
      },
    );

    testWidgets(
      'captura da câmera com imagem de baixa qualidade abre QualityWarningDialog',
      (tester) async {
        String? capturedPath;
        fakePicker.cameraResultPath = '/tmp/fake_dark_receipt.jpg';
        fakeQualityChecker.reportToReturn = const QualityReport(
          isAcceptable: false,
          issues: [QualityIssue.tooDark],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
              cameraPreview: const SizedBox(),
              onImageCaptured: (path) => capturedPath = path,
            ),
          ),
        );

        await tester.tap(find.bySemanticsLabel('Tirar foto da nota fiscal'));
        await tester.pumpAndSettle();

        expect(fakePicker.cameraCallCount, equals(1));
        expect(find.byType(QualityWarningDialog), findsOneWidget);
        expect(find.text('Foto com baixa qualidade'), findsOneWidget);

        // Clicking "Take another photo" clears dialog and remains on capture
        await tester.tap(find.text('Tirar outra foto'));
        await tester.pumpAndSettle();

        expect(find.byType(QualityWarningDialog), findsNothing);
        expect(capturedPath, isNull);
      },
    );

    testWidgets(
      'baixa qualidade -> continuar mesmo assim aciona callback onImageCaptured',
      (tester) async {
        String? capturedPath;
        fakePicker.cameraResultPath = '/tmp/fake_blurry_receipt.jpg';
        fakeQualityChecker.reportToReturn = const QualityReport(
          isAcceptable: false,
          issues: [QualityIssue.blur],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
              cameraPreview: const SizedBox(),
              onImageCaptured: (path) => capturedPath = path,
            ),
          ),
        );

        await tester.tap(find.bySemanticsLabel('Tirar foto da nota fiscal'));
        await tester.pumpAndSettle();

        expect(find.byType(QualityWarningDialog), findsOneWidget);

        await tester.tap(find.text('Continuar mesmo assim'));
        await tester.pumpAndSettle();

        expect(find.byType(QualityWarningDialog), findsNothing);
        expect(capturedPath, equals('/tmp/fake_blurry_receipt.jpg'));
      },
    );

    testWidgets(
      'botão de lançamento manual aciona callback onManualEntry (A11Y-10)',
      (tester) async {
        bool manualCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
              onManualEntry: () => manualCalled = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(AppIcons.edit));
        await tester.pump();

        expect(manualCalled, isTrue);
      },
    );

    testWidgets(
      'botões de ação possuem semântica acessível e alvos de toque adequados (A11Y-10)',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            home: OcrCaptureScreen(
              imagePickerPort: fakePicker,
              imageQualityPort: fakeQualityChecker,
            ),
          ),
        );

        expect(find.byTooltip('Escolher foto da galeria'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Tirar foto da nota fiscal'),
          findsOneWidget,
        );
        expect(find.byTooltip('Lançar manualmente'), findsOneWidget);
        expect(find.byTooltip('Ativar flash'), findsOneWidget);

        handle.dispose();
      },
    );
  });
}
