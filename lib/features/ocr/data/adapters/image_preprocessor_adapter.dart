import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_preprocessor_port.dart';

/// Image preprocessing adapter using `package:image`.
///
/// Performs decoding, resizing (max 1600px in any dimension),
/// grayscale conversion, contrast adjustment and noise reduction (blur)
/// in a separate Isolate to avoid blocking UI thread (RN-192, RNF-001).
class ImagePreprocessorAdapter implements ImagePreprocessorPort {
  static const int maxDimension = 1600;

  final Future<T> Function<T>(FutureOr<T> Function() computation)?
  isolateRunner;

  const ImagePreprocessorAdapter({this.isolateRunner});

  @override
  Future<Result<Uint8List, OcrFailure>> prepare(Uint8List raw) async {
    try {
      final runner = isolateRunner ?? Isolate.run;
      final processed = await runner(() => processImageBytes(raw));
      if (processed == null) {
        return const Err(
          OcrFailure(
            message: 'Não foi possível decodificar a imagem fornecida.',
          ),
        );
      }
      return Ok(processed);
    } catch (e) {
      return Err(
        OcrFailure(
          message: 'Erro durante o pré-processamento da imagem.',
          cause: e,
        ),
      );
    }
  }

  /// Static function executed inside Isolate.
  static Uint8List? processImageBytes(Uint8List raw) {
    img.Image? image;
    try {
      image = img.decodeImage(raw);
    } catch (_) {
      return null;
    }
    if (image == null) return null;

    // 0. EXIF orientation correction (native mobile camera photos)
    image = img.bakeOrientation(image);

    // 1. Resizing preserving aspect ratio (max 1600px on longest dimension)
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    // 2. Escala de cinza
    image = img.grayscale(image);

    // 3. Smooth contrast adjustment preserving sharp edges of thermal fonts
    image = img.adjustColor(image, contrast: 1.15);

    // 4. High-quality JPEG encoding (no blur to avoid degrading small digits)
    return img.encodeJpg(image, quality: 92);
  }
}
