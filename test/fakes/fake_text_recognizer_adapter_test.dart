import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

import 'fake_text_recognizer_adapter.dart';

void main() {
  group('FakeTextRecognizerAdapter', () {
    late FakeTextRecognizerAdapter adapter;

    setUp(() {
      adapter = FakeTextRecognizerAdapter();
    });

    test(
      'returns Ok(OcrDocument) by default when no return is configured',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3]);
        final result = await adapter.recognize(bytes);

        expect(result.isOk, isTrue);
        expect(result.valueOrNull, isNotNull);
        expect(adapter.recognizeCallCount, equals(1));
        expect(adapter.recognizeBytesHistory.length, equals(1));
      },
    );

    test('returns custom document configured in documentToReturn', () async {
      final expectedDoc = OcrDocument(
        lines: [
          const OcrTextLine(
            text: 'MERCADO TESTE',
            boundingBox: OcrBoundingBox(
              top: 0,
              left: 0,
              right: 100,
              bottom: 20,
            ),
            confidence: 0.95,
          ),
        ],
        imageWidth: 800,
        imageHeight: 600,
      );

      adapter.documentToReturn = expectedDoc;
      final result = await adapter.recognizeFile('/caminho/foto.jpg');

      expect(result.isOk, isTrue);
      final doc = result.valueOrNull!;
      expect(doc.lines.length, equals(1));
      expect(doc.lines.first.text, equals('MERCADO TESTE'));
      expect(adapter.recognizeFileCallCount, equals(1));
      expect(adapter.recognizeFileHistory, contains('/caminho/foto.jpg'));
    });

    test('returns Err(OcrFailure) when bytes are empty', () async {
      final result = await adapter.recognize(Uint8List(0));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<OcrFailure>());
    });

    test('returns Err(OcrFailure) when file path is empty', () async {
      final result = await adapter.recognizeFile('');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<OcrFailure>());
    });

    test('returns custom failure configured in failureToReturn', () async {
      const failure = OcrFailure(message: 'Falha no motor nativo');
      adapter.failureToReturn = failure;

      final result = await adapter.recognize(Uint8List.fromList([10, 20]));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('records termination in close() method', () async {
      expect(adapter.isClosed, isFalse);
      await adapter.close();
      expect(adapter.isClosed, isTrue);
    });
  });
}
