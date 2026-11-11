import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/data/repositories/local_recipe_photo_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late LocalRecipePhotoStore store;
  late Directory tempDir;
  late String sourcePath;
  late String oversizedSourcePath;
  late String invalidSourcePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recipe_photo_store_test');

    store = LocalRecipePhotoStore(getPhotosDir: () async => tempDir.path);

    // Create a 500x500 image
    final image = img.Image(width: 500, height: 500);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final bytes = img.encodeJpg(image);
    sourcePath = p.join(tempDir.path, 'source.jpg');
    File(sourcePath).writeAsBytesSync(bytes);

    // Create a 2000x1000 image
    final largeImage = img.Image(width: 2000, height: 1000);
    img.fill(largeImage, color: img.ColorRgb8(0, 255, 0));
    final largeBytes = img.encodeJpg(largeImage);
    oversizedSourcePath = p.join(tempDir.path, 'large_source.jpg');
    File(oversizedSourcePath).writeAsBytesSync(largeBytes);

    // Create an invalid file
    invalidSourcePath = p.join(tempDir.path, 'invalid.txt');
    File(invalidSourcePath).writeAsStringSync('not an image');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalRecipePhotoStore', () {
    test('savePhoto resizes image with width > 1280 and saves it', () async {
      final result = await store.savePhoto(
        sourcePath: oversizedSourcePath,
        recipeId: '123',
      );
      expect(result.isOk, isTrue);

      final outPath = result.valueOrNull!;
      expect(File(outPath).existsSync(), isTrue);
      expect(p.basename(outPath), 'recipe_123.jpg');

      final savedBytes = File(outPath).readAsBytesSync();
      final savedImage = img.decodeImage(savedBytes);
      expect(savedImage, isNotNull);
      expect(savedImage!.width, 1280);
      expect(savedImage.height, 640);
    });

    test('savePhoto does not resize image if max side <= 1280', () async {
      final result = await store.savePhoto(
        sourcePath: sourcePath,
        recipeId: '456',
      );
      expect(result.isOk, isTrue);

      final outPath = result.valueOrNull!;
      final savedBytes = File(outPath).readAsBytesSync();
      final savedImage = img.decodeImage(savedBytes);

      expect(savedImage!.width, 500);
      expect(savedImage.height, 500);
    });

    test('savePhoto fails if source file does not exist', () async {
      final result = await store.savePhoto(
        sourcePath: 'nonexistent.jpg',
        recipeId: '789',
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('savePhoto fails if file is not an image', () async {
      final result = await store.savePhoto(
        sourcePath: invalidSourcePath,
        recipeId: '999',
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('deletePhoto removes the file if it exists', () async {
      final saveResult = await store.savePhoto(
        sourcePath: sourcePath,
        recipeId: '111',
      );
      final outPath = saveResult.valueOrNull!;
      expect(File(outPath).existsSync(), isTrue);

      final deleteResult = await store.deletePhoto(outPath);
      expect(deleteResult.isOk, isTrue);
      expect(File(outPath).existsSync(), isFalse);
    });

    test('deletePhoto does not fail if file does not exist', () async {
      final deleteResult = await store.deletePhoto(
        p.join(tempDir.path, 'nonexistent.jpg'),
      );
      expect(deleteResult.isOk, isTrue);
    });
  });
}
