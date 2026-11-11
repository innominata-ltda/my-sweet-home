import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_sweet_home/features/ocr/data/adapters/image_quality_checker.dart';
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';

import '../../fakes/fake_image_quality_checker.dart';

void main() {
  group('ImageQualityChecker (T-13, RN-204)', () {
    late ImageQualityChecker checker;

    setUp(() {
      checker = const ImageQualityChecker(isolateRunner: _inlineRunner);
    });

    Uint8List createTestImage({
      required int width,
      required int height,
      int r = 128,
      int g = 128,
      int b = 128,
      bool addTextOrEdges = true,
    }) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(r, g, b));

      if (addTextOrEdges) {
        // Adds high-contrast pattern (checkerboard / text) to create gradient variation (sharpness)
        for (var y = 0; y < height; y += 10) {
          for (var x = 0; x < width; x += 10) {
            if (((x ~/ 10) + (y ~/ 10)) % 2 == 0) {
              img.fillRect(
                image,
                x1: x,
                y1: y,
                x2: mathMin(x + 5, width - 1),
                y2: mathMin(y + 5, height - 1),
                color: img.ColorRgb8(255, 255, 255),
              );
            } else {
              img.fillRect(
                image,
                x1: x,
                y1: y,
                x2: mathMin(x + 5, width - 1),
                y2: mathMin(y + 5, height - 1),
                color: img.ColorRgb8(0, 0, 0),
              );
            }
          }
        }
      }

      return img.encodeJpg(image);
    }

    test('returns invalidImage when receiving empty byte list', () async {
      final report = await checker.assess(Uint8List(0));

      expect(report.isAcceptable, isFalse);
      expect(report.issues, contains(QualityIssue.invalidImage));
    });

    test('returns invalidImage when receiving corrupted bytes', () async {
      final report = await checker.assess(Uint8List.fromList([1, 2, 3, 4, 5]));

      expect(report.isAcceptable, isFalse);
      expect(report.issues, contains(QualityIssue.invalidImage));
    });

    test('returns isAcceptable true for sharp image with good lighting and framing', () async {
      final raw = createTestImage(
        width: 400,
        height: 600,
        r: 150,
        g: 150,
        b: 150,
      );

      final report = await checker.assess(raw);

      expect(report.isAcceptable, isTrue);
      expect(report.issues, isEmpty);
      expect(report.hasIssues, isFalse);
      expect(report.isGood, isTrue);
    });

    test('accepts gallery photo where background and paper are smooth and only central region has sharp text (T-B12)', () async {
      // Simulates real mobile/gallery photo (720x1280): smooth table and paper occupying 85% of image,
      // and thin text lines only in central region of receipt.
      final image = img.Image(width: 720, height: 1280);
      img.fill(image, color: img.ColorRgb8(140, 135, 130)); // table

      // Central white paper
      img.fillRect(
        image,
        x1: 120,
        y1: 220,
        x2: 600,
        y2: 1100,
        color: img.ColorRgb8(215, 215, 215),
      );

      // Some lines simulating printed text on only part of the paper
      for (var y = 300; y < 700; y += 22) {
        for (var x = 150; x < 560; x += 8) {
          img.fillRect(
            image,
            x1: x,
            y1: y,
            x2: x + 3,
            y2: y + 4,
            color: img.ColorRgb8(45, 45, 45),
          );
        }
      }

      final raw = img.encodeJpg(image, quality: 85);
      final report = await checker.assess(raw);

      expect(
        report.isAcceptable,
        isTrue,
        reason:
            'Real photo of receipt on table should not be rejected by blur diluted by smooth background (sharpness=${report.sharpnessScore})',
      );
      expect(report.issues, isEmpty);
    });

    test('accepts real corpus photos in test/fixtures/ocr/images and .temp/Notas without low quality false positive', () async {
      final paths = <String>[
        '.temp/Notas/Nota 1/original.jpg',
        '.temp/Notas/Nota 2/original.jpg',
        '.temp/Notas/Nota 3/original.jpg',
        'test/fixtures/ocr/images/20261003_203526.jpg',
        'test/fixtures/ocr/images/20261003_203610.jpg',
        'test/fixtures/ocr/images/20261003_203701.jpg',
      ];

      for (final p in paths) {
        final file = File(p);
        if (!file.existsSync()) continue;
        final bytes = file.readAsBytesSync();
        final report = checker.assessSync(bytes);
        expect(
          report.isAcceptable,
          isTrue,
          reason:
              'Real photo "$p" was improperly rejected: issues=${report.issues}, sharpness=${report.sharpnessScore}, brightness=${report.brightnessScore}',
        );
      }
    });

    test('detects bad framing when dimensions are too small', () async {
      final raw = createTestImage(width: 150, height: 150);

      final report = await checker.assess(raw);

      expect(report.isAcceptable, isFalse);
      expect(report.issues, contains(QualityIssue.badFraming));
    });

    test('detects image that is too dark (tooDark)', () async {
      // Almost black image (r=10, g=10, b=10) without high contrast edges
      final image = img.Image(width: 400, height: 400);
      img.fill(image, color: img.ColorRgb8(10, 10, 10));
      final raw = img.encodeJpg(image);

      final report = await checker.assess(raw);

      expect(report.isAcceptable, isFalse);
      expect(report.issues, contains(QualityIssue.tooDark));
    });

    test('detects image that is too bright / washed out (tooBright)', () async {
      // Almost white image (r=245, g=245, b=245)
      final image = img.Image(width: 400, height: 400);
      img.fill(image, color: img.ColorRgb8(245, 245, 245));
      final raw = img.encodeJpg(image);

      final report = await checker.assess(raw);

      expect(report.isAcceptable, isFalse);
      expect(report.issues, contains(QualityIssue.tooBright));
    });

    test(
      'detects blur in uniform color image (without gradient variation)',
      () async {
        // Completely smooth image with neutral color without text or edges
        final image = img.Image(width: 400, height: 400);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final raw = img.encodeJpg(image);

        final report = await checker.assess(raw);

        expect(report.isAcceptable, isFalse);
        expect(report.issues, contains(QualityIssue.blur));
      },
    );

    test('supports custom thresholds via constructor', () async {
      const customChecker = ImageQualityChecker(
        minSharpness: 1.0,
        minBrightness: 10.0,
        maxBrightness: 250.0,
        minDimension: 100,
        isolateRunner: _inlineRunner,
      );

      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));
      final raw = img.encodeJpg(image);

      final report = await customChecker.assess(raw);

      // With expanded lighting threshold (10..250) and dimension 100, lighting and framing pass
      expect(report.issues.contains(QualityIssue.tooDark), isFalse);
      expect(report.issues.contains(QualityIssue.badFraming), isFalse);
    });
  });

  group('FakeImageQualityChecker', () {
    test('returns configured report and increments counters', () async {
      final fake = FakeImageQualityChecker(
        reportToReturn: const QualityReport(
          isAcceptable: false,
          issues: [QualityIssue.blur],
        ),
      );
      final raw = Uint8List.fromList([10, 20, 30]);

      final report = await fake.assess(raw);

      expect(fake.assessCallCount, equals(1));
      expect(fake.lastAssessedRaw, equals(raw));
      expect(report.isAcceptable, isFalse);
      expect(report.issues, equals([QualityIssue.blur]));
    });
  });

  group('QualityReport model', () {
    test('hasIssues and isGood reflect state correctly', () {
      const good = QualityReport(isAcceptable: true, issues: []);
      expect(good.hasIssues, isFalse);
      expect(good.isGood, isTrue);

      const withIssues = QualityReport(
        isAcceptable: true,
        issues: [QualityIssue.tooDark],
      );
      expect(withIssues.hasIssues, isTrue);
      expect(withIssues.isGood, isFalse);

      const rejected = QualityReport(isAcceptable: false, issues: []);
      expect(rejected.isGood, isFalse);
    });

    test('operator ==, hashCode e toString', () {
      const r1 = QualityReport(
        isAcceptable: true,
        issues: [QualityIssue.blur],
        sharpnessScore: 0.8,
        brightnessScore: 0.6,
        framingScore: 0.9,
      );
      const r2 = QualityReport(
        isAcceptable: true,
        issues: [QualityIssue.blur],
        sharpnessScore: 0.8,
        brightnessScore: 0.6,
        framingScore: 0.9,
      );
      const r3 = QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.blur],
        sharpnessScore: 0.8,
        brightnessScore: 0.6,
        framingScore: 0.9,
      );
      const r4 = QualityReport(
        isAcceptable: true,
        issues: [QualityIssue.tooDark],
        sharpnessScore: 0.8,
        brightnessScore: 0.6,
        framingScore: 0.9,
      );

      expect(r1, equals(r1));
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1, isNot(equals(r4)));
      expect(r1, isNot(equals('string')));
      expect(r1.toString(), contains('QualityReport(isAcceptable: true'));
    });
  });
}

Future<T> _inlineRunner<T>(FutureOr<T> Function() computation) async {
  return await computation();
}

int mathMin(int a, int b) => a < b ? a : b;
