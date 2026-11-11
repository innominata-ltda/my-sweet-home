import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/text_recognizer_port.dart';

/// Adapter para o Google ML Kit Text Recognition rodando 100% no aparelho.
///
/// Implementa [TextRecognizerPort] sem qualquer chamada de rede (RN-190, CA-1.1).
/// Converts ML Kit [RecognizedText] into immutable serializable [OcrDocument].
class MlKitTextRecognizerAdapter implements TextRecognizerPort {
  final TextRecognizer _recognizer;
  final bool _ownsRecognizer;

  /// Cria um adapter do ML Kit.
  ///
  /// If a custom [recognizer] is not provided, creates default instance
  /// para o script latino ([TextRecognitionScript.latin]).
  MlKitTextRecognizerAdapter({TextRecognizer? recognizer})
    : _recognizer = recognizer ?? TextRecognizer(),
      _ownsRecognizer = recognizer == null;

  @override
  Future<Result<OcrDocument, OcrFailure>> recognizeFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const Err(
        OcrFailure(
          message: 'Arquivo de imagem não existe no caminho especificado.',
        ),
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return const Err(OcrFailure(message: 'Arquivo de imagem está vazio.'));
    }

    return _processImageFile(file, bytes);
  }

  @override
  Future<Result<OcrDocument, OcrFailure>> recognize(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return const Err(OcrFailure(message: 'Bytes de imagem estão vazios.'));
    }

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/ocr_temp_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      return await _processImageFile(tempFile, bytes);
    } finally {
      if (tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {
          // Ignore failure when deleting temporary file
        }
      }
    }
  }

  Future<Result<OcrDocument, OcrFailure>> _processImageFile(
    File file,
    Uint8List bytes,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizedText = await _recognizer.processImage(inputImage);

      double imageWidth = 0.0;
      double imageHeight = 0.0;

      try {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          imageWidth = decoded.width.toDouble();
          imageHeight = decoded.height.toDouble();
        }
      } catch (_) {
        // Keep 0.0 if unable to decode image
      }

      final blocks = <OcrTextBlock>[];

      for (final block in recognizedText.blocks) {
        final lines = <OcrTextLine>[];

        for (final line in block.lines) {
          final elements = <OcrTextElement>[];

          for (final element in line.elements) {
            final elemBox = element.boundingBox;
            elements.add(
              OcrTextElement(
                text: element.text,
                boundingBox: OcrBoundingBox(
                  top: elemBox.top.toDouble(),
                  left: elemBox.left.toDouble(),
                  right: elemBox.right.toDouble(),
                  bottom: elemBox.bottom.toDouble(),
                ),
                confidence: element.confidence ?? 1.0,
              ),
            );
          }

          final lineBox = line.boundingBox;
          final double lineConf;
          if (line.confidence != null) {
            lineConf = line.confidence!;
          } else if (elements.isNotEmpty) {
            final sum = elements.fold(0.0, (acc, e) => acc + e.confidence);
            lineConf = sum / elements.length;
          } else {
            lineConf = 1.0;
          }

          lines.add(
            OcrTextLine(
              text: line.text,
              boundingBox: OcrBoundingBox(
                top: lineBox.top.toDouble(),
                left: lineBox.left.toDouble(),
                right: lineBox.right.toDouble(),
                bottom: lineBox.bottom.toDouble(),
              ),
              confidence: lineConf,
              elements: elements,
            ),
          );
        }

        final blockBox = block.boundingBox;
        blocks.add(
          OcrTextBlock(
            text: block.text,
            boundingBox: OcrBoundingBox(
              top: blockBox.top.toDouble(),
              left: blockBox.left.toDouble(),
              right: blockBox.right.toDouble(),
              bottom: blockBox.bottom.toDouble(),
            ),
            lines: lines,
          ),
        );
      }

      final doc = OcrDocument(
        blocks: blocks,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

      return Ok(doc);
    } catch (e) {
      return Err(
        OcrFailure(
          message: 'Erro durante o processamento do ML Kit: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (_ownsRecognizer) {
      try {
        await _recognizer.close();
      } catch (_) {
        // Ignore platform exception if native channel is unavailable on host
      }
    }
  }
}
