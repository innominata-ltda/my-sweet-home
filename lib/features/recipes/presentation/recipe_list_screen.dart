import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';
import 'package:go_router/go_router.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key, required this.controller});

  final RecipeListController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recipesTitle),
        actions: [
          ValueListenableBuilder<RecipeListState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final filter = controller.currentFilter;
              final isFav = filter.favorite == true;
              final favLabel = isFav
                  ? 'Mostrar todas as receitas'
                  : loc.recipeListFavoriteFilter;
              return Semantics(
                label: favLabel,
                button: true,
                child: IconButton(
                  icon: Icon(
                    isFav ? AppIcons.favoriteActive : AppIcons.favorite,
                  ),
                  tooltip: favLabel,
                  onPressed: () {
                    controller.updateFilter(
                      favorite: isFav ? null : true,
                      clearFavorite: isFav,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<RecipeListState>(
        valueListenable: controller,
        builder: (context, state, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: loc.recipeListSearchHint,
                    hintText: loc.recipeListSearchHint,
                    prefixIcon: const Icon(AppIcons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => controller.updateFilter(query: value),
                ),
              ),
              Expanded(child: _buildContent(context, state, loc)),
            ],
          );
        },
      ),
      floatingActionButton: Semantics(
        label: loc.recipeListCreate,
        button: true,
        child: FloatingActionButton(
          key: const Key('create_recipe_fab'),
          tooltip: loc.recipeListCreate,
          onPressed: () async {
            await context.push('/receitas/nova');
            await controller.load();
          },
          child: const Icon(AppIcons.add),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RecipeListState state,
    AppLocalizations loc,
  ) {
    return switch (state) {
      RecipeListLoading() => const Center(child: CircularProgressIndicator()),
      RecipeListError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(loc.recipeListError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.load,
              child: Text(loc.recipeListRetry),
            ),
          ],
        ),
      ),
      RecipeListSuccess(:final recipes) =>
        recipes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    loc.recipeListEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(
                      '${recipe.timeMinutes} min • ${recipe.servings} porções',
                    ),
                    trailing: Semantics(
                      label: recipe.isFavorite
                          ? 'Desmarcar favorito'
                          : 'Marcar como favorito',
                      button: true,
                      child: IconButton(
                        icon: Icon(
                          recipe.isFavorite
                              ? AppIcons.favoriteActive
                              : AppIcons.favorite,
                          color: recipe.isFavorite ? Colors.red : null,
                        ),
                        tooltip: recipe.isFavorite
                            ? 'Desmarcar favorito'
                            : 'Marcar como favorito',
                        onPressed: () => controller.toggleFavorite(
                          recipe.id,
                          recipe.isFavorite,
                        ),
                      ),
                    ),
                    onTap: () {
                      context.push('/receitas/${recipe.id}');
                    },
                  );
                },
              ),
    };
  }
}
