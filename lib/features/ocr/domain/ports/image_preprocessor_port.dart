import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';

/// Port interface for image preprocessing for OCR.
///
/// Resizes images to at most 1600px, applies grayscale,
/// contrast and noise reduction in Isolate off UI thread (RN-192, RNF-001).
abstract interface class ImagePreprocessorPort {
  /// Prepares a raw image for OCR.
  ///
  /// Returns [Ok] containing preprocessed image bytes in JPEG format,
  /// or [Err] containing [OcrFailure] in case of invalid image or processing error.
  Future<Result<Uint8List, OcrFailure>> prepare(Uint8List raw);
}
