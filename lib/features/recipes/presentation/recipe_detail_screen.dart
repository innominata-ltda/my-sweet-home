import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/domain/usecases/send_ingredients_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_controller.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.controller,
    required this.scaler,
    this.sendIngredientsUseCase,
    this.shoppingListRepository,
  });

  final RecipeDetailController controller;
  final IngredientScaler scaler;
  final SendIngredientsToShoppingListUseCase? sendIngredientsUseCase;
  final ShoppingListRepository? shoppingListRepository;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recipeDetailTitle),
        actions: [
          ValueListenableBuilder<RecipeDetailState>(
            valueListenable: controller,
            builder: (context, state, _) {
              if (state is RecipeDetailSuccess) {
                final recipe = state.recipe;
                final favLabel = recipe.isFavorite
                    ? 'Desmarcar favorito'
                    : 'Marcar como favorito';
                return Semantics(
                  label: favLabel,
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      recipe.isFavorite
                          ? AppIcons.favoriteActive
                          : AppIcons.favorite,
                      color: recipe.isFavorite ? Colors.red : null,
                    ),
                    tooltip: favLabel,
                    onPressed: controller.toggleFavorite,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<RecipeDetailState>(
        valueListenable: controller,
        builder: (context, state, _) {
          return switch (state) {
            RecipeDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            RecipeDetailError() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(loc.recipeDetailError),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.load,
                    child: Text(loc.recipeDetailRetry),
                  ),
                ],
              ),
            ),
            RecipeDetailSuccess(:final recipe, :final servings) => _buildDetail(
              context,
              recipe,
              servings,
              loc,
            ),
          };
        },
      ),
    );
  }

  Future<void> _sendIngredientsToShopping(
    BuildContext context,
    Recipe recipe,
    int servings,
  ) async {
    final useCase = sendIngredientsUseCase;
    final repo = shoppingListRepository;

    if (useCase == null || repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço de listas não disponível')),
      );
      return;
    }

    final listsResult = await repo.getAll();
    if (!context.mounted) return;
    final lists = listsResult.valueOrNull ?? [];

    String? targetListId;
    if (lists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma lista de compras ativa encontrada.'),
        ),
      );
      return;
    } else if (lists.length == 1) {
      targetListId = lists.first.id;
    } else {
      targetListId = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Selecione a lista de compras'),
          children: lists
              .map(
                (l) => SimpleDialogOption(
                  child: Text(l.name),
                  onPressed: () => Navigator.of(ctx).pop(l.id),
                ),
              )
              .toList(),
        ),
      );
    }

    if (targetListId == null || !context.mounted) return;

    final res = await useCase(
      listId: targetListId,
      recipe: recipe,
      targetServings: servings,
    );

    if (!context.mounted) return;
    if (res.isOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredientes enviados para a lista de compras!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar ingredientes: ${res.failureOrNull}'),
        ),
      );
    }
  }

  Widget _buildDetail(
    BuildContext context,
    Recipe recipe,
    int servings,
    AppLocalizations loc,
  ) {
    final scaledIngredients = scaler.scale(
      recipe.ingredients,
      from: recipe.servings,
      to: servings,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(recipe.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(AppIcons.timer, size: 16),
            const SizedBox(width: 4),
            Text(loc.recipeDetailTime(recipe.timeMinutes)),
            const Spacer(),
            Semantics(
              label: 'Diminuir porções',
              button: true,
              child: IconButton(
                key: const Key('decrease_servings_button'),
                icon: const Icon(AppIcons.removeCircle),
                tooltip: 'Diminuir porções',
                onPressed: servings > 1
                    ? () => controller.updateServings(servings - 1)
                    : null,
              ),
            ),
            Text(
              loc.recipeDetailServings(servings),
              key: const Key('portions_servings_text'),
            ),
            Semantics(
              label: 'Aumentar porções',
              button: true,
              child: IconButton(
                key: const Key('increase_servings_button'),
                icon: const Icon(AppIcons.addCircle),
                tooltip: 'Aumentar porções',
                onPressed: () => controller.updateServings(servings + 1),
              ),
            ),
          ],
        ),
        if (recipe.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              children: recipe.tags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          loc.recipeDetailIngredients,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...scaledIngredients.map(
          (ing) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ing.display),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('send_ingredients_to_shopping_button'),
          icon: const Icon(AppIcons.sendToList),
          label: const Text('Enviar ingredientes para lista de compras'),
          onPressed: () =>
              _sendIngredientsToShopping(context, recipe, servings),
        ),
        const SizedBox(height: 24),
        Text(
          loc.recipeDetailPreparation,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(recipe.prepText, key: const Key('recipe_detail_prep_text')),
        const SizedBox(height: 24),
        Card(
          color: Colors.amber.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.recipeDetailNoCost,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(loc.recipeDetailCostExplain),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('register_prices_button'),
                  onPressed: () => context.push('/compras/nova'),
                  child: Text(loc.recipeDetailRegisterPrices),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          key: const Key('recipe_preparation_button'),
          onPressed: () => context.push('/receitas/${recipe.id}/preparo'),
          icon: const Icon(AppIcons.play),
          label: Text(loc.recipePreparationTitle),
        ),
      ],
    );
  }
}
