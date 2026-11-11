import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/text_recognizer_port.dart';

/// Deterministic fake of [TextRecognizerPort] for unit and widget tests.
///
/// Allows simulating [OcrDocument] returns, [OcrFailure] failures, and inspecting
/// calls made without depending on native ML Kit engine or device.
class FakeTextRecognizerAdapter implements TextRecognizerPort {
  /// Document that will be returned in calls to [recognize] and [recognizeFile].
  OcrDocument? documentToReturn;

  /// Failure that will be returned if not null (takes precedence over [documentToReturn]).
  OcrFailure? failureToReturn;

  /// Number of times [recognize] was called.
  int recognizeCallCount = 0;

  /// Number of times [recognizeFile] was called.
  int recognizeFileCallCount = 0;

  /// History of bytes received in [recognize] calls.
  final List<Uint8List> recognizeBytesHistory = [];

  /// History of file paths received in [recognizeFile] calls.
  final List<String> recognizeFileHistory = [];

  /// Indicates whether [close] method was called.
  bool isClosed = false;

  FakeTextRecognizerAdapter({this.documentToReturn, this.failureToReturn});

  @override
  Future<Result<OcrDocument, OcrFailure>> recognize(Uint8List bytes) async {
    recognizeCallCount++;
    recognizeBytesHistory.add(bytes);

    if (bytes.isEmpty) {
      return const Err(OcrFailure(message: 'Image bytes are empty.'));
    }

    if (failureToReturn != null) {
      return Err(failureToReturn!);
    }

    return Ok(documentToReturn ?? OcrDocument());
  }

  @override
  Future<Result<OcrDocument, OcrFailure>> recognizeFile(String filePath) async {
    recognizeFileCallCount++;
    recognizeFileHistory.add(filePath);

    if (filePath.isEmpty) {
      return const Err(OcrFailure(message: 'File path is empty.'));
    }

    if (failureToReturn != null) {
      return Err(failureToReturn!);
    }

    return Ok(documentToReturn ?? OcrDocument());
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}
