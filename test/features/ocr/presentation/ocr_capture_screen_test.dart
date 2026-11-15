import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_capture_screen.dart';

void main() {
  testWidgets('benchmark button visibility follows kDebugMode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme(),
        home: const OcrCaptureScreen(cameraPreview: SizedBox.shrink()),
      ),
    );

    expect(
      find.byTooltip('Benchmark de Precisão OCR'),
      kDebugMode ? findsOneWidget : findsNothing,
    );
  });
}
