import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';

typedef RecipeId = String;

/// Entidade que representa uma receita.
final class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.prepText,
    required this.timeMinutes,
    required this.servings,
    this.tags = const {},
    this.isFavorite = false,
  });

  final RecipeId id;
  final String title;
  final List<Ingredient> ingredients;
  final String prepText;
  final int timeMinutes;
  final int servings;
  final Set<String> tags;
  final bool isFavorite;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Recipe) return false;
    return id == other.id &&
        title == other.title &&
        prepText == other.prepText &&
        timeMinutes == other.timeMinutes &&
        servings == other.servings &&
        isFavorite == other.isFavorite;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, prepText, timeMinutes, servings, isFavorite);

  Recipe copyWith({
    String? title,
    List<Ingredient>? ingredients,
    String? prepText,
    int? timeMinutes,
    int? servings,
    Set<String>? tags,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      prepText: prepText ?? this.prepText,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      servings: servings ?? this.servings,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Data to create or update a recipe.
final class NewRecipe {
  const NewRecipe({
    this.id,
    required this.title,
    required this.ingredients,
    required this.prepText,
    required this.timeMinutes,
    required this.servings,
    this.tags = const {},
    this.isFavorite = false,
  });

  final RecipeId? id;
  final String title;
  final List<Ingredient> ingredients;
  final String prepText;
  final int timeMinutes;
  final int servings;
  final Set<String> tags;
  final bool isFavorite;
}
