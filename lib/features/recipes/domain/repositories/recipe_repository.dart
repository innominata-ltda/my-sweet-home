import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';

abstract interface class RecipeRepository {
  Future<Result<Recipe, Failure>> upsert(NewRecipe r);
  Future<Result<List<Recipe>, Failure>> search({
    String? query,
    Set<String> tags = const {},
    bool? favorite,
  });
  Future<Result<Recipe, Failure>> getById(RecipeId id);
  Future<Result<TrashTicket, Failure>> remove(RecipeId id);
  Future<Result<void, Failure>> setFavorite(RecipeId id, bool value);
}
