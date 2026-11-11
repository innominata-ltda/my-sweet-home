import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/image_picker_adapter.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  group('ImagePickerAdapter (T-15, RF-040, A11Y-10)', () {
    late MockImagePicker mockPicker;
    late ImagePickerAdapter adapter;

    setUp(() {
      mockPicker = MockImagePicker();
      adapter = ImagePickerAdapter(picker: mockPicker);
    });

    test('pickFromGallery retorna caminho da imagem selecionada', () async {
      final mockFile = XFile('/path/to/gallery_receipt.jpg');
      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => mockFile);

      final result = await adapter.pickFromGallery();

      expect(result, equals('/path/to/gallery_receipt.jpg'));
      verify(() => mockPicker.pickImage(source: ImageSource.gallery)).called(1);
    });

    test('pickFromGallery returns null when user cancels selection', () async {
      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      final result = await adapter.pickFromGallery();

      expect(result, isNull);
    });

    test('pickFromGallery retorna null se excecao for lancada', () async {
      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenThrow(Exception('Permissao negada'));

      final result = await adapter.pickFromGallery();

      expect(result, isNull);
    });

    test('captureFromCamera retorna caminho da foto capturada', () async {
      final mockFile = XFile('/path/to/camera_receipt.jpg');
      when(() => mockPicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => mockFile);

      final result = await adapter.captureFromCamera();

      expect(result, equals('/path/to/camera_receipt.jpg'));
      verify(() => mockPicker.pickImage(source: ImageSource.camera)).called(1);
    });

    test('captureFromCamera returns null when user cancels capture', () async {
      when(() => mockPicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => null);

      final result = await adapter.captureFromCamera();

      expect(result, isNull);
    });

    test('captureFromCamera retorna null se excecao for lancada', () async {
      when(() => mockPicker.pickImage(source: ImageSource.camera))
          .thenThrow(Exception('Camera indisponivel'));

      final result = await adapter.captureFromCamera();

      expect(result, isNull);
    });
  });
}
