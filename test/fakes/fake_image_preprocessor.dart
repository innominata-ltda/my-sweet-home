import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_preprocessor_port.dart';

/// Fake para testes de [ImagePreprocessorPort].
class FakeImagePreprocessor implements ImagePreprocessorPort {
  Result<Uint8List, OcrFailure>? resultToReturn;
  Uint8List? lastPreparedRaw;
  int prepareCallCount = 0;

  FakeImagePreprocessor({this.resultToReturn});

  @override
  Future<Result<Uint8List, OcrFailure>> prepare(Uint8List raw) async {
    prepareCallCount++;
    lastPreparedRaw = raw;
    if (resultToReturn != null) {
      return resultToReturn!;
    }
    return Ok(raw);
  }
}
