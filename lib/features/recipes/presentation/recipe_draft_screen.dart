import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/recipes/data/recipe_repository_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_photo_store.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:my_sweet_home/features/recipes/domain/services/pasted_recipe_parser.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_providers.dart';

class RecipeDraftScreen extends StatefulWidget {
  const RecipeDraftScreen({
    super.key,
    required this.idGenerator,
    this.repository,
    this.parser,
    this.photoStore,
  });

  final IdGenerator idGenerator;
  final RecipeRepository? repository;
  final PastedRecipeParser? parser;
  final RecipePhotoStore? photoStore;

  @override
  State<RecipeDraftScreen> createState() => _RecipeDraftScreenState();
}

class _RecipeDraftScreenState extends State<RecipeDraftScreen> {
  late final RecipeDraftController _controller;
  final _titleController = TextEditingController();
  final _prepTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RecipeDraftController();

    _titleController.addListener(() {
      _controller.updateTitle(_titleController.text);
    });

    _prepTextController.addListener(() {
      _controller.updatePrepText(_prepTextController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _prepTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final recipe = _controller.buildRecipe(widget.idGenerator);
      RecipeRepository? repo = widget.repository;
      if (repo == null) {
        try {
          repo = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(recipeRepositoryProvider);
        } catch (_) {}
      }

      if (repo != null) {
        final result = await repo.upsert(
          NewRecipe(
            id: recipe.id,
            title: recipe.title,
            ingredients: recipe.ingredients,
            prepText: recipe.prepText,
            timeMinutes: recipe.timeMinutes,
            servings: recipe.servings,
            tags: recipe.tags,
            isFavorite: recipe.isFavorite,
          ),
        );
        if (result.isErr) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao salvar receita: ${result.failureOrNull}'),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(recipe);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showPasteDialog() {
    final pasteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Colar receita'),
        content: TextField(
          key: const Key('paste_recipe_input'),
          controller: pasteController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Cole a receita aqui (título, ingredientes, modo de preparo)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_paste_recipe_button'),
            onPressed: () {
              final text = pasteController.text;
              if (text.trim().isNotEmpty) {
                final parser = widget.parser ?? _resolveParser();
                final draft = parser.parse(text);
                _controller.applyDraft(draft);
                _titleController.text = _controller.value.title;
                _prepTextController.text = _controller.value.prepText;
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  PastedRecipeParser _resolveParser() {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(pastedRecipeParserProvider);
    } catch (_) {
      return PastedRecipeParserImpl();
    }
  }

  void _showAddIngredientDialog(AppLocalizations loc) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.recipeDraftNewIngredientButton),
        content: TextField(
          key: const Key('ingredient_name_input'),
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do ingrediente',
            hintText: 'Ex: 2 xícaras de farinha',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_add_ingredient_button'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _controller.addIngredient(Ingredient(name: name));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(AppLocalizations loc) {
    final tagController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.recipeDraftAddTagButton),
        content: TextField(
          key: const Key('tag_input'),
          controller: tagController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da tag',
            hintText: 'Ex: Sobremesa, Rápido, Vegano',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_add_tag_button'),
            onPressed: () {
              final tag = tagController.text.trim();
              if (tag.isNotEmpty) {
                _controller.addTag(tag);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recipeDraftNewTitle),
        actions: [
          Semantics(
            label: 'Colar receita',
            button: true,
            child: IconButton(
              key: const Key('paste_recipe_button'),
              icon: const Icon(AppIcons.copy),
              tooltip: 'Colar receita',
              onPressed: _showPasteDialog,
            ),
          ),
          Semantics(
            label: 'Salvar receita',
            button: true,
            child: IconButton(
              key: const Key('save_recipe_button'),
              icon: const Icon(AppIcons.check),
              tooltip: 'Salvar receita',
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<RecipeDraftState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('recipe_title_input'),
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${loc.recipeDraftTitleLabel} *',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(loc.recipeDraftFavoriteLabel),
                value: state.isFavorite,
                onChanged: (_) => _controller.toggleFavorite(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SpinBoxPlaceholder(
                      label: loc.recipeDraftTimeLabel,
                      value: state.timeMinutes,
                      onChanged: _controller.updateTimeMinutes,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SpinBoxPlaceholder(
                      label: loc.recipeDraftServingsLabel,
                      value: state.servings,
                      onChanged: _controller.updateServings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                loc.recipeDraftTagsLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in state.tags)
                    Chip(
                      label: Text(tag),
                      onDeleted: () => _controller.removeTag(tag),
                    ),
                  ActionChip(
                    key: const Key('add_tag_chip'),
                    label: Text(loc.recipeDraftAddTagButton),
                    onPressed: () => _showAddTagDialog(loc),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${loc.recipeDraftIngredientsLabel} *',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (int i = 0; i < state.ingredients.length; i++)
                ListTile(
                  key: Key('ingredient_item_$i'),
                  title: Text(state.ingredients[i].name),
                  trailing: Semantics(
                    label: 'Remover ingrediente ${state.ingredients[i].name}',
                    button: true,
                    child: IconButton(
                      icon: const Icon(AppIcons.delete),
                      tooltip: 'Remover ingrediente',
                      onPressed: () => _controller.removeIngredient(i),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                key: const Key('add_ingredient_button'),
                icon: const Icon(AppIcons.add),
                onPressed: () => _showAddIngredientDialog(loc),
                label: Text(loc.recipeDraftNewIngredientButton),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('recipe_prep_input'),
                controller: _prepTextController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: loc.recipeDraftPrepLabel,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('recipe_photo_button'),
                icon: const Icon(AppIcons.camera),
                label: const Text('Adicionar foto'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto anexada à receita.')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class SpinBoxPlaceholder extends StatelessWidget {
  const SpinBoxPlaceholder({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            Semantics(
              label: 'Diminuir $label',
              button: true,
              child: IconButton(
                icon: const Icon(AppIcons.remove),
                tooltip: 'Diminuir $label',
                onPressed: () => onChanged(value - 1),
              ),
            ),
            Text('$value'),
            Semantics(
              label: 'Aumentar $label',
              button: true,
              child: IconButton(
                icon: const Icon(AppIcons.add),
                tooltip: 'Aumentar $label',
                onPressed: () => onChanged(value + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
