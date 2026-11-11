@Tags(['device'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/ml_kit_text_recognizer_adapter.dart';

class MockTextRecognizer extends Mock implements TextRecognizer {}

class MockRecognizedText extends Mock implements RecognizedText {}

class MockTextBlock extends Mock implements TextBlock {}

class MockTextLine extends Mock implements TextLine {}

class MockTextElement extends Mock implements TextElement {}

class FakeInputImage extends Fake implements InputImage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeInputImage());
  });

  group('MlKitTextRecognizerAdapter', () {
    late MockTextRecognizer mockRecognizer;
    late MlKitTextRecognizerAdapter adapter;

    setUp(() {
      mockRecognizer = MockTextRecognizer();
      adapter = MlKitTextRecognizerAdapter(recognizer: mockRecognizer);
    });

    test('returns Err(OcrFailure) when file does not exist', () async {
      final result = await adapter.recognizeFile(
        '/caminho/inexistente/foto_inexistente_12345.jpg',
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<OcrFailure>());
      final failure = result.failureOrNull as OcrFailure;
      expect(failure.message, contains('não existe'));
    });

    test('returns Err(OcrFailure) when bytes are empty', () async {
      final result = await adapter.recognize(Uint8List(0));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<OcrFailure>());
      final failure = result.failureOrNull as OcrFailure;
      expect(failure.message, contains('vazios'));
    });

    test('maps ML Kit RecognizedText to serializable OcrDocument with blocks, lines, and elements', () async {
      final mockRecognizedText = MockRecognizedText();
      final mockBlock = MockTextBlock();
      final mockLine = MockTextLine();
      final mockElement = MockTextElement();

      when(() => mockElement.text).thenReturn('CARREFOUR');
      when(() => mockElement.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 100, 30));
      when(() => mockElement.confidence).thenReturn(0.98);

      when(() => mockLine.text).thenReturn('CARREFOUR HIPERMERCADO');
      when(() => mockLine.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 300, 30));
      when(() => mockLine.confidence).thenReturn(0.95);
      when(() => mockLine.elements).thenReturn([mockElement]);

      when(() => mockBlock.text).thenReturn('CARREFOUR HIPERMERCADO');
      when(() => mockBlock.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 300, 30));
      when(() => mockBlock.lines).thenReturn([mockLine]);

      when(() => mockRecognizedText.blocks).thenReturn([mockBlock]);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/test_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(
        Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00, // Synthetic JPEG header
        ]),
      );

      try {
        final result = await adapter.recognizeFile(tempFile.path);

        expect(result.isOk, isTrue);
        final doc = result.valueOrNull!;
        expect(doc.blocks.length, equals(1));
        expect(doc.blocks.first.text, equals('CARREFOUR HIPERMERCADO'));
        expect(doc.lines.length, equals(1));
        expect(doc.lines.first.text, equals('CARREFOUR HIPERMERCADO'));
        expect(doc.lines.first.confidence, equals(0.95));
        expect(doc.lines.first.elements.length, equals(1));
        expect(doc.lines.first.elements.first.text, equals('CARREFOUR'));
        expect(doc.lines.first.elements.first.confidence, equals(0.98));
        expect(doc.lines.first.elements.first.boundingBox.top, equals(10.0));
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });

    test('calculates line confidence as average of elements when line confidence is null', () async {
      final mockRecognizedText = MockRecognizedText();
      final mockBlock = MockTextBlock();
      final mockLine = MockTextLine();
      final mockElement1 = MockTextElement();
      final mockElement2 = MockTextElement();

      when(() => mockElement1.text).thenReturn('ITEM');
      when(() => mockElement1.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 50, 30));
      when(() => mockElement1.confidence).thenReturn(0.40);

      when(() => mockElement2.text).thenReturn('TESTE');
      when(() => mockElement2.boundingBox)
          .thenReturn(const Rect.fromLTRB(60, 10, 100, 30));
      when(() => mockElement2.confidence).thenReturn(0.50);

      when(() => mockLine.text).thenReturn('ITEM TESTE');
      when(() => mockLine.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 100, 30));
      when(() => mockLine.confidence).thenReturn(null); // ML Kit returns null
      when(() => mockLine.elements).thenReturn([mockElement1, mockElement2]);

      when(() => mockBlock.text).thenReturn('ITEM TESTE');
      when(() => mockBlock.boundingBox)
          .thenReturn(const Rect.fromLTRB(10, 10, 100, 30));
      when(() => mockBlock.lines).thenReturn([mockLine]);

      when(() => mockRecognizedText.blocks).thenReturn([mockBlock]);
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => mockRecognizedText);

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/test_ocr_conf_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(
        Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
        ]),
      );

      try {
        final result = await adapter.recognizeFile(tempFile.path);

        expect(result.isOk, isTrue);
        final doc = result.valueOrNull!;
        expect(doc.lines.length, equals(1));
        // Average of 0.40 and 0.50 = 0.45 (should respect average and not yield 1.0)
        expect(doc.lines.first.confidence, closeTo(0.45, 0.001));
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });

    test('converts exception thrown by ML Kit into Err(OcrFailure)', () async {
      when(() => mockRecognizer.processImage(any()))
          .thenThrow(Exception('Falha interna do motor ML Kit'));

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/test_ocr_err_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

      try {
        final result = await adapter.recognizeFile(tempFile.path);

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<OcrFailure>());
        final failure = result.failureOrNull as OcrFailure;
        expect(failure.message, contains('Falha interna do motor ML Kit'));
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });

    test(
      'releases resources in close() only if it owns the recognizer',
      () async {
        when(() => mockRecognizer.close()).thenAnswer((_) async {});

        await adapter.close();

        // Since the recognizer was injected (external), close responsibility is not adapter's
        verifyNever(() => mockRecognizer.close());

        final defaultAdapter = MlKitTextRecognizerAdapter();
        // Does not throw when closing adapter with own recognizer
        await defaultAdapter.close();
      },
    );
  });
}
