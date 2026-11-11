import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

/// Port for optical character recognition (OCR) service.
///
/// Permite isolar o motor de OCR (Google ML Kit, Tesseract, etc.) do restante
/// do aplicativo, garantindo testabilidade e desacoplamento de plataforma.
abstract interface class TextRecognizerPort {
  /// Reconhece o texto em uma imagem fornecida como bytes [Uint8List].
  Future<Result<OcrDocument, OcrFailure>> recognize(Uint8List bytes);

  /// Reconhece o texto em um arquivo de imagem localizado no caminho [filePath].
  Future<Result<OcrDocument, OcrFailure>> recognizeFile(String filePath);

  /// Libera quaisquer recursos associados ao motor de OCR.
  Future<void> close();
}
