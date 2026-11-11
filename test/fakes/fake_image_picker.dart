import 'package:my_sweet_home/features/ocr/domain/ports/image_picker_port.dart';

/// Deterministic fake for [ImagePickerPort] used in automated tests.
class FakeImagePickerPort implements ImagePickerPort {
  /// Caminho simulado retornado ao selecionar da galeria.
  String? galleryResultPath;

  /// Simulated path returned when capturing from camera.
  String? cameraResultPath;

  /// Flag to simulate failure/exception in operations.
  bool shouldFail = false;

  /// Contador de chamadas para [pickFromGallery].
  int galleryCallCount = 0;

  /// Contador de chamadas para [captureFromCamera].
  int cameraCallCount = 0;

  @override
  Future<String?> pickFromGallery() async {
    galleryCallCount++;
    if (shouldFail) {
      throw Exception('Erro simulado na galeria');
    }
    return galleryResultPath;
  }

  @override
  Future<String?> captureFromCamera() async {
    cameraCallCount++;
    if (shouldFail) {
      throw Exception('Simulated camera error');
    }
    return cameraResultPath;
  }
}
