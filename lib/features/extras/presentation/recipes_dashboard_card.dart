import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/recipes/data/recipe_repository_provider.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/repositories/recipe_repository.dart';

/// Card do Dashboard para Receitas Favoritas (RF-102, RF-105, RN-370, CA-3.5).
class RecipesDashboardCard extends ConsumerStatefulWidget {
  const RecipesDashboardCard({
    super.key,
    this.repository,
    this.initialRecipes,
    this.onTap,
  });

  final RecipeRepository? repository;
  final List<Recipe>? initialRecipes;
  final VoidCallback? onTap;

  @override
  ConsumerState<RecipesDashboardCard> createState() =>
      _RecipesDashboardCardState();
}

class _RecipesDashboardCardState extends ConsumerState<RecipesDashboardCard> {
  List<Recipe>? _recipes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipes != null) {
      _recipes = widget.initialRecipes;
      _isLoading = false;
    } else {
      _loadRecipes();
    }
  }

  Future<void> _loadRecipes() async {
    final RecipeRepository repo =
        widget.repository ?? ref.read(recipeRepositoryProvider);
    final result = await repo.search(favorite: true);
    if (mounted) {
      setState(() {
        _recipes = result.valueOrNull ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final title = l10n?.dashboardCardFavoriteRecipes ?? 'Receitas Favoritas';
    final count = _recipes?.length ?? 0;

    return Semantics(
      container: true,
      button: true,
      label: '$title, $count receitas favoritas, toque para ver detalhes',
      child: AppCard(
        key: const Key('recipes_dashboard_card'),
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Spacing.touchTarget),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.recipes,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              if (_isLoading)
                const Center(child: AppLoading())
              else if (count == 0)
                Text(
                  'Nenhuma receita favoritada ainda.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  '$count receita(s) favorita(s) para o seu dia a dia',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
