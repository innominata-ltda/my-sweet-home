import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_quality_port.dart';

/// Aferidor de qualidade de imagem para OCR (RN-204).
///
/// Evaluates focus (blur/sharpness), lighting (dark/blown-out) and
/// framing (dimensions/aspect ratio) of receipts.
class ImageQualityChecker implements ImageQualityPort {
  /// Minimum sharpness threshold (variance of luminance gradient).
  final double minSharpness;

  /// Minimum mean luminance threshold (0..255) for adequate lighting.
  final double minBrightness;

  /// Maximum mean luminance threshold (0..255) for adequate lighting.
  final double maxBrightness;

  /// Minimum dimension (width or height in pixels) acceptable for receipt.
  final int minDimension;

  final Future<T> Function<T>(FutureOr<T> Function() computation)?
  isolateRunner;

  const ImageQualityChecker({
    this.minSharpness = 25.0,
    this.minBrightness = 30.0,
    this.maxBrightness = 235.0,
    this.minDimension = 250,
    this.isolateRunner,
  });

  @override
  Future<QualityReport> assess(Uint8List raw) async {
    if (raw.isEmpty) {
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }

    final runner = isolateRunner ?? Isolate.run;
    try {
      final report = await runner(() => assessSync(raw));
      return report;
    } catch (_) {
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }
  }

  /// Synchronous evaluation of image bytes.
  QualityReport assessSync(Uint8List raw) {
    if (raw.isEmpty) {
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }

    img.Image? decoded;
    try {
      decoded = img.decodeImage(raw);
    } catch (_) {
      if (_isHeicOrAvifContainer(raw)) {
        return const QualityReport(
          isAcceptable: true,
          issues: [],
          sharpnessScore: 100.0,
        );
      }
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }

    if (decoded == null) {
      if (_isHeicOrAvifContainer(raw)) {
        return const QualityReport(
          isAcceptable: true,
          issues: [],
          sharpnessScore: 100.0,
        );
      }
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }

    final image = img.bakeOrientation(decoded);
    final issues = <QualityIssue>[];

    // 1. Framing and dimensions
    double framingScore = 1.0;
    if (image.width < minDimension || image.height < minDimension) {
      issues.add(QualityIssue.badFraming);
      framingScore = 0.3;
    } else {
      final aspect = image.width / image.height;
      if (aspect > 5.0 || aspect < 0.08) {
        issues.add(QualityIssue.badFraming);
        framingScore = 0.5;
      }
    }

    // Sampling for quick lighting and sharpness calculation
    const maxSampleDim = 600;
    img.Image sampleImage = image;
    if (image.width > maxSampleDim || image.height > maxSampleDim) {
      if (image.width >= image.height) {
        sampleImage = img.copyResize(image, width: maxSampleDim);
      } else {
        sampleImage = img.copyResize(image, height: maxSampleDim);
      }
    }

    final width = sampleImage.width;
    final height = sampleImage.height;
    final totalPixels = width * height;

    if (totalPixels == 0) {
      return const QualityReport(
        isAcceptable: false,
        issues: [QualityIssue.invalidImage],
        sharpnessScore: 0,
        brightnessScore: 0,
        framingScore: 0,
      );
    }

    // 2. Lighting (brightness / average luminance)
    double totalLuminance = 0;
    final luminanceGrid = List<double>.filled(totalPixels, 0);

    var idx = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = sampleImage.getPixel(x, y);
        // ITU-R BT.601 luminance
        final lum = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        luminanceGrid[idx++] = lum;
        totalLuminance += lum;
      }
    }

    final avgLuminance = totalLuminance / totalPixels;
    final brightnessScore = avgLuminance / 255.0;

    if (avgLuminance < minBrightness) {
      issues.add(QualityIssue.tooDark);
    } else if (avgLuminance > maxBrightness) {
      issues.add(QualityIssue.tooBright);
    }

    // 3. Focus / Sharpness (global variance + text block variance)
    double sumGrad = 0;
    double sumGradSq = 0;
    int gradCount = 0;

    const gridCols = 8;
    const gridRows = 8;
    final blockSum = List<double>.filled(gridCols * gridRows, 0.0);
    final blockSumSq = List<double>.filled(gridCols * gridRows, 0.0);
    final blockCount = List<int>.filled(gridCols * gridRows, 0);

    for (var y = 0; y < height - 1; y++) {
      final bRow = (y * gridRows) ~/ height;
      for (var x = 0; x < width - 1; x++) {
        final currIndex = y * width + x;
        final currLum = luminanceGrid[currIndex];
        final rightLum = luminanceGrid[currIndex + 1];
        final bottomLum = luminanceGrid[currIndex + width];

        final dx = rightLum - currLum;
        final dy = bottomLum - currLum;
        final gradMag = math.sqrt(dx * dx + dy * dy);
        final gradSq = gradMag * gradMag;

        sumGrad += gradMag;
        sumGradSq += gradSq;
        gradCount++;

        final bCol = (x * gridCols) ~/ width;
        final bIdx = bRow * gridCols + bCol;
        blockSum[bIdx] += gradMag;
        blockSumSq[bIdx] += gradSq;
        blockCount[bIdx]++;
      }
    }

    double globalVariance = 0.0;
    if (gradCount > 0) {
      final meanGrad = sumGrad / gradCount;
      globalVariance = math.max(
        0.0,
        (sumGradSq / gradCount) - (meanGrad * meanGrad),
      );
    }

    final blockVariances = <double>[];
    for (var i = 0; i < gridCols * gridRows; i++) {
      final cnt = blockCount[i];
      if (cnt > 0) {
        final m = blockSum[i] / cnt;
        final v = math.max(0.0, (blockSumSq[i] / cnt) - (m * m));
        blockVariances.add(v);
      }
    }

    double topBlocksVariance = 0.0;
    if (blockVariances.isNotEmpty) {
      blockVariances.sort((a, b) => b.compareTo(a));
      // Considers top 20% sharpest blocks (where receipt text concentrates)
      final topCount = math.max(1, (blockVariances.length * 0.20).ceil());
      var sumTop = 0.0;
      for (var i = 0; i < topCount; i++) {
        sumTop += blockVariances[i];
      }
      topBlocksVariance = sumTop / topCount;
    }

    final sharpnessScore = math.max(globalVariance, topBlocksVariance);

    if (sharpnessScore < minSharpness) {
      issues.add(QualityIssue.blur);
    }

    final isAcceptable = issues.isEmpty;

    return QualityReport(
      isAcceptable: isAcceptable,
      issues: issues,
      sharpnessScore: sharpnessScore,
      brightnessScore: brightnessScore,
      framingScore: framingScore,
    );
  }

  /// Verifies if bytes match an ISOBMFF container (HEIC/HEIF/AVIF),
  /// which is natively supported by OS/ML Kit, but not pure `package:image`.
  static bool _isHeicOrAvifContainer(Uint8List raw) {
    if (raw.length < 12) return false;
    // Bytes 4..8 devem ser 'ftyp' (0x66, 0x74, 0x79, 0x70)
    if (raw[4] != 0x66 || raw[5] != 0x74 || raw[6] != 0x79 || raw[7] != 0x70) {
      return false;
    }
    final brand = String.fromCharCodes(raw.sublist(8, 12)).toLowerCase();
    return brand == 'heic' ||
        brand == 'heix' ||
        brand == 'hevc' ||
        brand == 'heim' ||
        brand == 'heis' ||
        brand == 'mif1' ||
        brand == 'msf1' ||
        brand == 'avif' ||
        brand == 'avis';
  }
}
