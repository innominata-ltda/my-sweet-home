import 'package:my_sweet_home/core/result/result.dart';

/// Stores recipe photos in the application.
abstract interface class RecipePhotoStore {
  /// Salva a foto localizada em [sourcePath] para o armazenamento persistente,
  /// ensuring image max side is <= 1280, and returns the saved file path.
  Future<Result<String, Failure>> savePhoto({
    required String sourcePath,
    required String recipeId,
  });

  /// Removes stored photo in application, located at [photoPath].
  Future<Result<void, Failure>> deletePhoto(String photoPath);
}
