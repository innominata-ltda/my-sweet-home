import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';

class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository(this.clock);

  final Clock clock;
  final _recipes = <RecipeId, Recipe>{};
  final _deleted = <RecipeId>{};
  int _nextId = 1;

  @override
  Future<Result<Recipe, Failure>> upsert(NewRecipe r) async {
    final id = r.id ?? 'fake_recipe_${_nextId++}';
    final recipe = Recipe(
      id: id,
      title: r.title,
      ingredients: r.ingredients,
      prepText: r.prepText,
      timeMinutes: r.timeMinutes,
      servings: r.servings,
      tags: r.tags,
      isFavorite: r.isFavorite,
    );
    _recipes[id] = recipe;
    return Ok(recipe);
  }

  @override
  Future<Result<List<Recipe>, Failure>> search({
    String? query,
    Set<String> tags = const {},
    bool? favorite,
  }) async {
    final results = _recipes.values.where((r) {
      if (_deleted.contains(r.id)) return false;

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        if (!r.title.toLowerCase().contains(q)) {
          return false;
        }
      }

      if (tags.isNotEmpty) {
        if (!r.tags.containsAll(tags)) {
          return false;
        }
      }

      if (favorite != null) {
        if (r.isFavorite != favorite) {
          return false;
        }
      }

      return true;
    }).toList();

    results.sort((a, b) => a.title.compareTo(b.title));
    return Ok(results);
  }

  bool simulateDelay = false;

  @override
  Future<Result<Recipe, Failure>> getById(RecipeId id) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (_deleted.contains(id)) {
      return Err(NotFoundFailure(what: 'Recipe $id not found'));
    }
    final recipe = _recipes[id];
    if (recipe == null) {
      return Err(NotFoundFailure(what: 'Recipe $id not found'));
    }
    return Ok(recipe);
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(RecipeId id) async {
    if (!_recipes.containsKey(id)) {
      return Err(NotFoundFailure(what: 'Recipe $id not found'));
    }
    _deleted.add(id);
    return Ok(TrashTicket(table: 'recipes', id: id, deletedAt: clock.nowUtc()));
  }

  @override
  Future<Result<void, Failure>> setFavorite(RecipeId id, bool value) async {
    final existing = _recipes[id];
    if (existing == null || _deleted.contains(id)) {
      return Err(NotFoundFailure(what: 'Recipe $id not found'));
    }

    _recipes[id] = Recipe(
      id: existing.id,
      title: existing.title,
      ingredients: existing.ingredients,
      prepText: existing.prepText,
      timeMinutes: existing.timeMinutes,
      servings: existing.servings,
      tags: existing.tags,
      isFavorite: value,
    );

    return const Ok(null);
  }
}
