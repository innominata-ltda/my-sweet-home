import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:uuid/uuid.dart';

class DriftRecipeRepository implements RecipeRepository {
  const DriftRecipeRepository(this._db, this._clock);

  final db.AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<Recipe, Failure>> upsert(NewRecipe r) async {
    try {
      final now = _clock.nowUtc().toIso8601String();
      final id = r.id ?? const Uuid().v7();

      await _db.transaction(() async {
        await _db
            .into(_db.recipes)
            .insertOnConflictUpdate(
              db.RecipesCompanion(
                id: Value(id),
                title: Value(r.title),
                instructions: Value(r.prepText),
                prepMinutes: Value(r.timeMinutes),
                servings: Value(r.servings),
                isFavorite: Value(r.isFavorite),
                createdAt: r.id == null ? Value(now) : const Value.absent(),
                updatedAt: Value(now),
              ),
            );

        // Update tags
        await (_db.delete(
          _db.recipeTags,
        )..where((t) => t.recipeId.equals(id))).go();
        if (r.tags.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(
              _db.recipeTags,
              r.tags.map(
                (tag) => db.RecipeTagsCompanion.insert(recipeId: id, tag: tag),
              ),
            );
          });
        }

        // Update ingredients
        await (_db.delete(
          _db.recipeIngredients,
        )..where((t) => t.recipeId.equals(id))).go();
        if (r.ingredients.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(_db.recipeIngredients, [
              for (var i = 0; i < r.ingredients.length; i++)
                db.RecipeIngredientsCompanion.insert(
                  id: const Uuid().v7(),
                  recipeId: Value(id),
                  productId: Value(r.ingredients[i].productId),
                  rawText: r.ingredients[i].name,
                  quantityMilli: Value(r.ingredients[i].quantity?.valueMilli),
                  unit: Value(r.ingredients[i].quantity?.unit.name),
                  position: i,
                ),
            ]);
          });
        }
      });

      return Ok(
        Recipe(
          id: id,
          title: r.title,
          ingredients: r.ingredients,
          prepText: r.prepText,
          timeMinutes: r.timeMinutes,
          servings: r.servings,
          tags: r.tags,
          isFavorite: r.isFavorite,
        ),
      );
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<List<Recipe>, Failure>> search({
    String? query,
    Set<String> tags = const {},
    bool? favorite,
  }) async {
    try {
      final recipesQuery = _db.select(_db.recipes);
      if (query != null && query.trim().isNotEmpty) {
        recipesQuery.where(
          (t) => t.title.lower().contains(query.trim().toLowerCase()),
        );
      }
      if (favorite != null) {
        recipesQuery.where((t) => t.isFavorite.equals(favorite));
      }

      final recipeRows = await recipesQuery.get();
      if (recipeRows.isEmpty) {
        return const Ok([]);
      }

      final recipeIds = recipeRows.map((e) => e.id).toList();

      final ingredientsByRecipe = <String, List<db.RecipeIngredient>>{};
      final tagsByRecipe = <String, Set<String>>{};

      for (var i = 0; i < recipeIds.length; i += 500) {
        final end = (i + 500 > recipeIds.length) ? recipeIds.length : i + 500;
        final chunk = recipeIds.sublist(i, end);

        final ingredientsQuery = _db.select(_db.recipeIngredients)
          ..where((t) => t.recipeId.isIn(chunk))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]);
        final ingredientRows = await ingredientsQuery.get();
        for (final row in ingredientRows) {
          ingredientsByRecipe.putIfAbsent(row.recipeId!, () => []).add(row);
        }

        final tagsQuery = _db.select(_db.recipeTags)
          ..where((t) => t.recipeId.isIn(chunk));
        final tagRows = await tagsQuery.get();
        for (final row in tagRows) {
          tagsByRecipe.putIfAbsent(row.recipeId, () => {}).add(row.tag);
        }
      }

      var results = recipeRows.map((r) {
        final rTags = tagsByRecipe[r.id] ?? {};
        final rIngs = ingredientsByRecipe[r.id] ?? [];
        return _mapRecipe(r, rIngs, rTags);
      }).toList();

      if (tags.isNotEmpty) {
        results = results.where((r) => r.tags.containsAll(tags)).toList();
      }

      results.sort((a, b) => a.title.compareTo(b.title));
      return Ok(results);
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<Recipe, Failure>> getById(RecipeId id) async {
    try {
      final recipeQuery = _db.select(_db.recipes)
        ..where((t) => t.id.equals(id));
      final recipeRow = await recipeQuery.getSingleOrNull();

      if (recipeRow == null) {
        return Err(NotFoundFailure(what: 'Recipe $id not found'));
      }

      final ingredientsQuery = _db.select(_db.recipeIngredients)
        ..where((t) => t.recipeId.equals(id))
        ..orderBy([(t) => OrderingTerm(expression: t.position)]);
      final ingredientRows = await ingredientsQuery.get();

      final tagsQuery = _db.select(_db.recipeTags)
        ..where((t) => t.recipeId.equals(id));
      final tagRows = await tagsQuery.get();
      final tags = tagRows.map((e) => e.tag).toSet();

      return Ok(_mapRecipe(recipeRow, ingredientRows, tags));
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(RecipeId id) async {
    try {
      final result = await getById(id);
      if (result.isErr) {
        return Err(result.failureOrNull!);
      }

      final deletedAt = _clock.nowUtc();

      await _db.transaction(() async {
        await (_db.delete(_db.recipes)..where((t) => t.id.equals(id))).go();
      });

      return Ok(TrashTicket(table: 'recipes', id: id, deletedAt: deletedAt));
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> setFavorite(RecipeId id, bool value) async {
    try {
      final now = _clock.nowUtc().toIso8601String();
      final rowsUpdated =
          await (_db.update(_db.recipes)..where((t) => t.id.equals(id))).write(
            db.RecipesCompanion(
              isFavorite: Value(value),
              updatedAt: Value(now),
            ),
          );

      if (rowsUpdated == 0) {
        return Err(NotFoundFailure(what: 'Recipe $id not found'));
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  Recipe _mapRecipe(
    db.Recipe recipeRow,
    List<db.RecipeIngredient> ingredientRows,
    Set<String> tags,
  ) {
    final ingredients = ingredientRows.map((row) {
      Quantity? quantity;
      if (row.quantityMilli != null && row.unit != null) {
        final unit = Unit.values.firstWhere(
          (e) => e.name == row.unit,
          orElse: () => Unit.un,
        );
        quantity = Quantity(row.quantityMilli!, unit);
      }
      return Ingredient(
        name: row.rawText,
        quantity: quantity,
        productId: row.productId,
      );
    }).toList();

    return Recipe(
      id: recipeRow.id,
      title: recipeRow.title,
      ingredients: ingredients,
      prepText: recipeRow.instructions ?? '',
      timeMinutes: recipeRow.prepMinutes ?? 0,
      servings: recipeRow.servings,
      tags: tags,
      isFavorite: recipeRow.isFavorite,
    );
  }
}
