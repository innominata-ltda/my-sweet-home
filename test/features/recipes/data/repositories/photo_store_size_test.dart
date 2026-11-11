import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:my_sweet_home/features/recipes/data/repositories/local_recipe_photo_store.dart';

void main() {
  late LocalRecipePhotoStore store;
  late Directory tempDir;
  late String oversizedSourcePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'recipe_photo_store_size_test',
    );

    store = LocalRecipePhotoStore(getPhotosDir: () async => tempDir.path);

    // CA-5.1: Dada uma foto de 4000x3000
    final largeImage = img.Image(width: 4000, height: 3000);

    // Fill to avoid extremely slow test execution, but add some variation
    // to prevent unrealistic 100% compression size
    img.fill(largeImage, color: img.ColorRgb8(100, 150, 200));

    // Draw some rectangles to add noise
    for (int i = 0; i < 50; i++) {
      img.fillRect(
        largeImage,
        x1: i * 80,
        y1: i * 60,
        x2: (i * 80) + 400,
        y2: (i * 60) + 300,
        color: img.ColorRgb8(i * 5, 255 - (i * 5), 128),
      );
    }

    final largeBytes = img.encodeJpg(largeImage, quality: 100);
    oversizedSourcePath = p.join(tempDir.path, 'large_source_4000x3000.jpg');
    File(oversizedSourcePath).writeAsBytesSync(largeBytes);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('T-V2: CA-5.1 e RNF-004 - Impacto de fotos no tamanho do app', () {
    test('Given a 4000x3000 photo, when attached, is stored with max 1280px and reduced size', () async {
      final originalFile = File(oversizedSourcePath);
      final originalSize = originalFile.lengthSync();

      // Act
      final result = await store.savePhoto(
        sourcePath: oversizedSourcePath,
        recipeId: 'ca51_size_test',
      );
      expect(result.isOk, isTrue);

      final outPath = result.valueOrNull!;
      final savedFile = File(outPath);

      expect(savedFile.existsSync(), isTrue);

      final savedSize = savedFile.lengthSync();
      final savedBytes = savedFile.readAsBytesSync();
      final savedImage = img.decodeImage(savedBytes)!;

      // Assert CA-5.1: at most 1280px on longest side
      expect(savedImage.width, 1280);
      expect(savedImage.height, 960);

      // Assert RNF-004: impacto no app (tamanho reduzido)
      expect(savedSize, lessThan(originalSize));
    });
  });
}
