import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_providers.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchFieldController = TextEditingController();

  @override
  void dispose() {
    _searchFieldController.dispose();
    super.dispose();
  }

  String _typeTitle(GlobalSearchResultType type, AppLocalizations l10n) {
    switch (type) {
      case GlobalSearchResultType.product:
        return l10n.productsTitle;
      case GlobalSearchResultType.expense:
        return l10n.navExpenses;
      case GlobalSearchResultType.task:
        return l10n.navTasks;
      case GlobalSearchResultType.recipe:
        return l10n.recipesTitle;
      case GlobalSearchResultType.shoppingList:
        return l10n.shoppingListsTitle;
    }
  }

  IconData _typeIcon(GlobalSearchResultType type) {
    switch (type) {
      case GlobalSearchResultType.product:
        return AppIcons.product;
      case GlobalSearchResultType.expense:
        return AppIcons.money;
      case GlobalSearchResultType.task:
        return AppIcons.check;
      case GlobalSearchResultType.recipe:
        return AppIcons.recipes;
      case GlobalSearchResultType.shoppingList:
        return AppIcons.shopping;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final controller = ref.watch(globalSearchControllerProvider);

    return AppScaffold(
      title: l10n.searchGlobalScreenTitle,
      body: ValueListenableBuilder<GlobalSearchState>(
        valueListenable: controller,
        builder: (context, state, child) {
          final grouped = state.results.groupedByType;
          final hasQuery = state.query.trim().isNotEmpty;
          final totalResults = state.results.items.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextField(
                  label: l10n.searchGlobalLabel,
                  hint: l10n.searchGlobalInputHint,
                  controller: _searchFieldController,
                  prefixIcon: const Icon(AppIcons.search),
                  onChanged: controller.search,
                ),
              ),
              if (state.isLoading)
                const Expanded(child: AppLoading())
              else if (!hasQuery)
                Expanded(
                  child: AppEmptyState(
                    title: l10n.searchGlobalEmptyTitle,
                    description: l10n.searchGlobalEmptyDescription,
                    icon: AppIcons.search,
                  ),
                )
              else if (totalResults == 0)
                Expanded(
                  child: AppEmptyState(
                    title: l10n.searchGlobalNoResultsTitle,
                    description: l10n.searchGlobalNoResultsForQuery(
                      state.query,
                    ),
                    icon: AppIcons.search,
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final type in GlobalSearchResultType.values)
                        if ((grouped[type] ?? []).isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _typeIcon(type),
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _typeTitle(type, l10n),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${grouped[type]!.length})',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ...grouped[type]!.map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(item.title),
                                subtitle: item.subtitle != null
                                    ? Text(item.subtitle!)
                                    : null,
                                trailing: const Icon(AppIcons.info, size: 16),
                                onTap: () {
                                  switch (item.type) {
                                    case GlobalSearchResultType.product:
                                      context.push(
                                        '/produtos/${item.targetId}',
                                      );
                                      break;
                                    case GlobalSearchResultType.recipe:
                                      context.push(
                                        '/receitas/${item.targetId}',
                                      );
                                      break;
                                    case GlobalSearchResultType.shoppingList:
                                      context.push('/listas/${item.targetId}');
                                      break;
                                    case GlobalSearchResultType.task:
                                      context.push('/tarefas');
                                      break;
                                    case GlobalSearchResultType.expense:
                                      context.push('/despesas');
                                      break;
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
