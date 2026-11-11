import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/features/recipes/data/recipe_repository_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_providers.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';

class RecipeListContainer extends ConsumerStatefulWidget {
  const RecipeListContainer({super.key});

  @override
  ConsumerState<RecipeListContainer> createState() =>
      _RecipeListContainerState();
}

class _RecipeListContainerState extends ConsumerState<RecipeListContainer> {
  late final RecipeListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecipeListController(ref.read(recipeRepositoryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecipeListScreen(controller: _controller);
  }
}

class RecipeDetailContainer extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailContainer({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailContainer> createState() =>
      _RecipeDetailContainerState();
}

class _RecipeDetailContainerState extends ConsumerState<RecipeDetailContainer> {
  late final RecipeDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecipeDetailController(
      ref.read(recipeRepositoryProvider),
      widget.recipeId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecipeDetailScreen(
      controller: _controller,
      scaler: const StandardIngredientScaler(),
      sendIngredientsUseCase: ref.watch(
        sendIngredientsToShoppingListUseCaseProvider,
      ),
      shoppingListRepository: ref.watch(shoppingListRepositoryProvider),
    );
  }
}
