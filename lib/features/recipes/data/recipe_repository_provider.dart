import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/recipes/data/repositories/drift_recipe_repository.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return DriftRecipeRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});
