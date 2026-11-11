/// Port interface for receipt image selection and capture (RF-040, A11Y-10).
///
/// Allows capturing photo via camera or selecting image from device gallery,
/// isolating platform plugin dependencies.
abstract interface class ImagePickerPort {
  /// Seleciona uma imagem de nota fiscal a partir da galeria do dispositivo.
  ///
  /// Returns selected image file path or `null` if user cancels.
  Future<String?> pickFromGallery();

  /// Captures receipt photo from device camera.
  ///
  /// Returns captured image file path or `null` if user cancels.
  Future<String?> captureFromCamera();
}
