import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/image_preprocessor_adapter.dart';

import '../../fakes/fake_image_preprocessor.dart';

void main() {
  group('ImagePreprocessorAdapter (T-12, RN-192, RNF-001)', () {
    late ImagePreprocessorAdapter preprocessor;

    setUp(() {
      preprocessor = const ImagePreprocessorAdapter();
    });

    Uint8List createTestImageBytes({required int width, required int height}) {
      final image = img.Image(width: width, height: height);
      // Fill with some colors to ensure decoding and processing works
      img.fill(image, color: img.ColorRgb8(200, 100, 50));
      return img.encodeJpg(image);
    }

    test('resizes image larger than 1600px keeping aspect ratio', () async {
      final raw = createTestImageBytes(width: 2400, height: 1200);

      final result = await preprocessor.prepare(raw);

      expect(result.isOk, isTrue);
      final processedBytes = result.valueOrNull!;
      final processedImg = img.decodeImage(processedBytes);
      expect(processedImg, isNotNull);
      expect(processedImg!.width, equals(1600));
      expect(processedImg.height, equals(800));
    });

    test('resizes vertical image larger than 1600px in height', () async {
      final raw = createTestImageBytes(width: 1000, height: 2000);

      final result = await preprocessor.prepare(raw);

      expect(result.isOk, isTrue);
      final processedBytes = result.valueOrNull!;
      final processedImg = img.decodeImage(processedBytes);
      expect(processedImg, isNotNull);
      expect(processedImg!.height, equals(1600));
      expect(processedImg.width, equals(800));
    });

    test('keeps dimensions of image smaller than 1600px', () async {
      final raw = createTestImageBytes(width: 800, height: 600);

      final result = await preprocessor.prepare(raw);

      expect(result.isOk, isTrue);
      final processedBytes = result.valueOrNull!;
      final processedImg = img.decodeImage(processedBytes);
      expect(processedImg, isNotNull);
      expect(processedImg!.width, equals(800));
      expect(processedImg.height, equals(600));
    });

    test('returns Err with OcrFailure when image bytes are invalid', () async {
      final invalidRaw = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await preprocessor.prepare(invalidRaw);

      expect(result.isErr, isTrue);
      final failure = result.failureOrNull!;
      expect(failure, isA<OcrFailure>());
      expect(failure.message, contains('Não foi possível decodificar'));
    });

    test('allows custom isolate runner for dependency injection', () async {
      final adapter = ImagePreprocessorAdapter(
        isolateRunner: <T>(computation) async => await computation(),
      );
      final raw = createTestImageBytes(width: 100, height: 100);

      final result = await adapter.prepare(raw);

      expect(result.isOk, isTrue);
    });

    test('converts image to grayscale and applies filters', () async {
      final raw = createTestImageBytes(width: 100, height: 100);

      final result = await preprocessor.prepare(raw);

      expect(result.isOk, isTrue);
      final processedImg = img.decodeImage(result.valueOrNull!)!;
      final pixel = processedImg.getPixel(10, 10);
      expect(pixel.r, equals(pixel.g));
      expect(pixel.g, equals(pixel.b));
    });

    test(
      'normalizes EXIF orientation for photos with camera rotation',
      () async {
        final image = img.Image(width: 400, height: 200);
        img.fill(image, color: img.ColorRgb8(200, 100, 50));
        image.exif.imageIfd.orientation = 6; // EXIF 6: rotated 90 degrees CW
        final raw = img.encodeJpg(image);

        final result = await preprocessor.prepare(raw);

        expect(result.isOk, isTrue);
        final processedImg = img.decodeImage(result.valueOrNull!)!;
        // bakeOrientation should apply 90 degree rotation
        expect(processedImg.width, equals(200));
        expect(processedImg.height, equals(400));
      },
    );

    test(
      'returns Err with OcrFailure when receiving empty byte list',
      () async {
        final emptyRaw = Uint8List(0);

        final result = await preprocessor.prepare(emptyRaw);

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<OcrFailure>());
      },
    );
  });

  group('FakeImagePreprocessor', () {
    test('returns Ok by default and records calls', () async {
      final fake = FakeImagePreprocessor();
      final dummyBytes = Uint8List.fromList([1, 2, 3]);

      final result = await fake.prepare(dummyBytes);

      expect(result.isOk, isTrue);
      expect(fake.prepareCallCount, equals(1));
      expect(fake.lastPreparedRaw, equals(dummyBytes));
    });

    test('returns configured result', () async {
      const failure = OcrFailure(message: 'Simulated error');
      final fake = FakeImagePreprocessor(resultToReturn: const Err(failure));

      final result = await fake.prepare(Uint8List(0));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
