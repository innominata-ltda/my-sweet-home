import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/domain/services/recipe_cost_policy.dart';

sealed class RecipeDetailState {}

class RecipeDetailLoading extends RecipeDetailState {}

class RecipeDetailSuccess extends RecipeDetailState {
  RecipeDetailSuccess(this.recipe, this.servings, {this.cost});
  final Recipe recipe;
  final int servings;

  /// Estimated recipe cost for [servings] servings, or null while
  /// still being calculated (e.g. price repository not available).
  final RecipeCost? cost;
}

class RecipeDetailError extends RecipeDetailState {
  RecipeDetailError(this.failure);
  final Failure failure;
}

class RecipeDetailController extends ValueNotifier<RecipeDetailState> {
  RecipeDetailController(
    this._repository,
    this.id, {
    this.priceRepository,
    this.costPolicy = const StandardRecipeCostPolicy(),
    this.scaler = const StandardIngredientScaler(),
  }) : super(RecipeDetailLoading()) {
    unawaited(load());
  }

  final RecipeRepository _repository;
  final RecipeId id;

  /// Price repository; if null, cost is never calculated.
  final PricePointRepository? priceRepository;

  /// Cost calculation policy (pure, injectable for tests).
  final RecipeCostPolicy costPolicy;

  /// Ingredient scaler (injectable for tests).
  final IngredientScaler scaler;

  Future<void> load() async {
    value = RecipeDetailLoading();

    final result = await _repository.getById(id);

    switch (result) {
      case Ok(:final value):
        this.value = RecipeDetailSuccess(value, value.servings);
        unawaited(_computeCost(value, value.servings));
      case Err(:final failure):
        value = RecipeDetailError(failure);
    }
  }

  void updateServings(int servings) {
    if (servings < 1) return;
    if (value case RecipeDetailSuccess(recipe: final r)) {
      value = RecipeDetailSuccess(r, servings);
      unawaited(_computeCost(r, servings));
    }
  }

  Future<void> toggleFavorite() async {
    if (value case RecipeDetailSuccess(
      recipe: final r,
      servings: final s,
      cost: final c,
    )) {
      final result = await _repository.setFavorite(id, !r.isFavorite);
      if (result is Ok) {
        value = RecipeDetailSuccess(
          r.copyWith(isFavorite: !r.isFavorite),
          s,
          cost: c,
        );
      }
    }
  }

  /// Calculates estimated cost for recipe scaled to [servings] servings.
  ///
  /// Queries price repository once for all ingredients
  /// with productId (RN-175, performance budget of plan.md).
  Future<void> _computeCost(Recipe recipe, int servings) async {
    final priceRepo = priceRepository;
    if (priceRepo == null) return;

    // Scales ingredients to current servings.
    final scaled = scaler.scale(
      recipe.ingredients,
      from: recipe.servings,
      to: servings,
    );

    // Collects candidate productIds (scalable with product link).
    final productIds = scaled
        .where((i) => i.isScalable && i.source.productId != null)
        .map((i) => i.source.productId!)
        .toSet();

    // Fetches latest price for each product (one query per product).
    final Map<ProductId, KnownPrice> lastPrices = {};
    final since = DateTime.utc(
      2000,
    ); // wide window — we want the most recent price
    for (final pid in productIds) {
      final res = await priceRepo.getByProduct(pid, since: since);
      if (res case Ok(:final value) when value.isNotEmpty) {
        // Ordena decrescente por data e pega o mais recente.
        final sorted = value.toList()..sort((a, b) => b.date.compareTo(a.date));
        final latest = sorted.first;
        lastPrices[pid] = KnownPrice(
          normalizedPrice: latest.normalizedPrice,
          normalizedUnit: latest.unit,
          date: latest.date,
        );
      }
    }

    final cost = costPolicy.estimate(
      ingredients: scaled,
      lastPrices: lastPrices,
    );

    // Only update state if recipe and servings are still the same.
    if (value case RecipeDetailSuccess(recipe: final r, servings: final s)
        when r.id == recipe.id && s == servings) {
      value = RecipeDetailSuccess(r, s, cost: cost);
    }
  }
}
