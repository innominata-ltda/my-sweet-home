import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_photo_store.dart';

class LocalRecipePhotoStore implements RecipePhotoStore {
  const LocalRecipePhotoStore({Future<String> Function()? getPhotosDir})
    : _getPhotosDir = getPhotosDir ?? _defaultGetPhotosDir;

  final Future<String> Function() _getPhotosDir;

  static Future<String> _defaultGetPhotosDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'recipes', 'photos');
  }

  Future<String> _ensureDir() async {
    final path = await _getPhotosDir();
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<Result<String, Failure>> savePhoto({
    required String sourcePath,
    required String recipeId,
  }) async {
    try {
      final file = File(sourcePath);
      if (!file.existsSync()) {
        return Err(
          StorageFailure(detail: 'Source file does not exist: $sourcePath'),
        );
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return const Err(
          ValidationFailure(fields: {'photo': 'Invalid image format'}),
        );
      }

      img.Image processed = image;

      // Redimensionar para maior lado <= 1280 (T-07)
      if (image.width > 1280 || image.height > 1280) {
        if (image.width >= image.height) {
          processed = img.copyResize(image, width: 1280);
        } else {
          processed = img.copyResize(image, height: 1280);
        }
      }

      final outBytes = img.encodeJpg(processed, quality: 85);
      final outDir = await _ensureDir();
      final outFileName = 'recipe_$recipeId.jpg';
      final outPath = p.join(outDir, outFileName);

      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);

      return Ok(outPath);
    } catch (e) {
      return Err(StorageFailure(detail: 'Error saving photo: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Error deleting photo: $e', cause: e));
    }
  }
}
