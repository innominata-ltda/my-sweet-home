import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/services/pasted_recipe_parser.dart';

/// Estado do rascunho da receita.
class RecipeDraftState {
  const RecipeDraftState({
    required this.title,
    required this.ingredients,
    required this.prepText,
    required this.timeMinutes,
    required this.servings,
    this.tags = const {},
    this.isFavorite = false,
  });

  final String title;
  final List<Ingredient> ingredients;
  final String prepText;
  final int timeMinutes;
  final int servings;
  final Set<String> tags;
  final bool isFavorite;

  RecipeDraftState copyWith({
    String? title,
    List<Ingredient>? ingredients,
    String? prepText,
    int? timeMinutes,
    int? servings,
    Set<String>? tags,
    bool? isFavorite,
  }) {
    return RecipeDraftState(
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

/// Controller responsible for managing recipe editing and creation.
class RecipeDraftController extends ValueNotifier<RecipeDraftState> {
  RecipeDraftController({RecipeDraftState? initialState})
    : super(
        initialState ??
            const RecipeDraftState(
              title: '',
              ingredients: [],
              prepText: '',
              timeMinutes: 0,
              servings: 1,
            ),
      );

  void updateTitle(String title) {
    value = value.copyWith(title: title);
  }

  void updatePrepText(String text) {
    value = value.copyWith(prepText: text);
  }

  void updateTimeMinutes(int minutes) {
    if (minutes >= 0) {
      value = value.copyWith(timeMinutes: minutes);
    }
  }

  void updateServings(int servings) {
    if (servings > 0) {
      value = value.copyWith(servings: servings);
    }
  }

  void applyDraft(RecipeDraft draft) {
    final parsedIngredients = draft.ingredients
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => Ingredient(name: s))
        .toList();

    value = value.copyWith(
      title: draft.title.isNotEmpty ? draft.title : value.title,
      prepText: draft.prepText.isNotEmpty ? draft.prepText : value.prepText,
      ingredients: parsedIngredients.isNotEmpty
          ? parsedIngredients
          : value.ingredients,
    );
  }

  void addIngredient(Ingredient ingredient) {
    final updatedList = List<Ingredient>.from(value.ingredients)
      ..add(ingredient);
    value = value.copyWith(ingredients: updatedList);
  }

  void removeIngredient(int index) {
    final updatedList = List<Ingredient>.from(value.ingredients)
      ..removeAt(index);
    value = value.copyWith(ingredients: updatedList);
  }

  void toggleFavorite() {
    value = value.copyWith(isFavorite: !value.isFavorite);
  }

  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty) {
      final updatedTags = Set<String>.from(value.tags)..add(trimmed);
      value = value.copyWith(tags: updatedTags);
    }
  }

  void removeTag(String tag) {
    final updatedTags = Set<String>.from(value.tags)..remove(tag);
    value = value.copyWith(tags: updatedTags);
  }

  Recipe buildRecipe(IdGenerator idGenerator) {
    if (value.title.trim().isEmpty) {
      throw StateError('O título é obrigatório.');
    }
    if (value.ingredients.isEmpty) {
      throw StateError('Adicione pelo menos um ingrediente.');
    }

    return Recipe(
      id: idGenerator.newId(),
      title: value.title.trim(),
      ingredients: value.ingredients,
      prepText: value.prepText.trim(),
      timeMinutes: value.timeMinutes,
      servings: value.servings,
      tags: value.tags,
      isFavorite: value.isFavorite,
    );
  }
}
