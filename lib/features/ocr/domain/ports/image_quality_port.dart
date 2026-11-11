import 'dart:typed_data';

import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';

/// Port interface for image quality assessment for OCR (RN-204).
///
/// Avalia se uma imagem capturada possui qualidade suficiente de foco,
/// lighting and framing before proceeding with recognition.
abstract interface class ImageQualityPort {
  /// Afere a qualidade da imagem fornecida em bytes.
  Future<QualityReport> assess(Uint8List raw);
}
