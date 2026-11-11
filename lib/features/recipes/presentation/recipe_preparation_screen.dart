import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/recipes/data/recipe_repository_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';

import '../data/adapters/keep_screen_on_provider.dart';
import '../domain/ports/keep_screen_on_port.dart';

class RecipePreparationScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final RecipeRepository? repository;

  const RecipePreparationScreen({
    super.key,
    required this.recipeId,
    this.repository,
  });

  @override
  ConsumerState<RecipePreparationScreen> createState() =>
      _RecipePreparationScreenState();
}

class _RecipePreparationScreenState
    extends ConsumerState<RecipePreparationScreen> {
  KeepScreenOnPort? _keepScreenOn;
  Recipe? _recipe;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      _keepScreenOn = ref.read(keepScreenOnProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _keepScreenOn?.enable();
      });
    } catch (_) {}
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    RecipeRepository? repo = widget.repository;
    if (repo == null) {
      try {
        repo = ref.read(recipeRepositoryProvider);
      } catch (_) {}
    }

    if (repo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Repositório de receitas não disponível';
      });
      return;
    }

    final result = await repo.getById(widget.recipeId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isOk && result.valueOrNull != null) {
        _recipe = result.valueOrNull;
      } else {
        _errorMessage = 'Receita não encontrada';
      }
    });
  }

  @override
  void dispose() {
    _keepScreenOn?.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipePreparationTitle)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipe!.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.recipePreparationBody,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recipe!.prepText.isNotEmpty
                          ? _recipe!.prepText
                          : 'Sem instruções cadastradas.',
                      key: const Key('recipe_prep_text'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
