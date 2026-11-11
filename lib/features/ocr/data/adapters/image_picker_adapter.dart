import 'package:image_picker/image_picker.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_picker_port.dart';

/// Adapter real para [ImagePickerPort] usando o pacote `image_picker` (RF-040, A11Y-10).
class ImagePickerAdapter implements ImagePickerPort {
  final ImagePicker _picker;

  ImagePickerAdapter({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image?.path;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image?.path;
    } catch (e) {
      return null;
    }
  }
}
