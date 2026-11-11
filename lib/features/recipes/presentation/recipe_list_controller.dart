import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';

class RecipeListFilter {
  const RecipeListFilter({
    this.query = '',
    this.tags = const {},
    this.favorite,
  });

  final String query;
  final Set<String> tags;
  final bool? favorite;

  RecipeListFilter copyWith({
    String? query,
    Set<String>? tags,
    bool? favorite,
    bool clearFavorite = false,
  }) {
    return RecipeListFilter(
      query: query ?? this.query,
      tags: tags ?? this.tags,
      favorite: clearFavorite ? null : (favorite ?? this.favorite),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeListFilter) return false;
    return query == other.query &&
        setEquals(tags, other.tags) &&
        favorite == other.favorite;
  }

  @override
  int get hashCode =>
      Object.hash(query, Object.hashAllUnordered(tags), favorite);
}

sealed class RecipeListState {}

class RecipeListLoading extends RecipeListState {
  RecipeListLoading(this.filter);
  final RecipeListFilter filter;
}

class RecipeListSuccess extends RecipeListState {
  RecipeListSuccess(this.recipes, this.filter);
  final List<Recipe> recipes;
  final RecipeListFilter filter;
}

class RecipeListError extends RecipeListState {
  RecipeListError(this.failure, this.filter);
  final Failure failure;
  final RecipeListFilter filter;
}

class RecipeListController extends ValueNotifier<RecipeListState> {
  RecipeListController(this._repository)
    : super(RecipeListLoading(const RecipeListFilter())) {
    unawaited(load());
  }

  final RecipeRepository _repository;

  Future<void> load() async {
    final filter = currentFilter;
    value = RecipeListLoading(filter);

    final result = await _repository.search(
      query: filter.query.isNotEmpty ? filter.query : null,
      tags: filter.tags,
      favorite: filter.favorite,
    );

    switch (result) {
      case Ok(:final value):
        this.value = RecipeListSuccess(value, filter);
      case Err(:final failure):
        value = RecipeListError(failure, filter);
    }
  }

  RecipeListFilter get currentFilter {
    return switch (value) {
      RecipeListLoading(filter: final f) => f,
      RecipeListSuccess(filter: final f) => f,
      RecipeListError(filter: final f) => f,
    };
  }

  void updateFilter({
    String? query,
    Set<String>? tags,
    bool? favorite,
    bool clearFavorite = false,
  }) {
    final current = currentFilter;
    final updated = current.copyWith(
      query: query,
      tags: tags,
      favorite: favorite,
      clearFavorite: clearFavorite,
    );
    if (current != updated) {
      final state = switch (value) {
        RecipeListSuccess(recipes: final r) => RecipeListSuccess(r, updated),
        _ => RecipeListLoading(updated),
      };
      value = state;
      unawaited(load());
    }
  }

  Future<void> toggleFavorite(RecipeId id, bool currentValue) async {
    final result = await _repository.setFavorite(id, !currentValue);
    if (result is Ok) {
      await load();
    }
  }
}
