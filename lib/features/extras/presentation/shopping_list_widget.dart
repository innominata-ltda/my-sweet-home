import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_controller.dart';

/// Widget de listas de compras para a tela inicial / dashboard (RF-102).
class ShoppingListWidget extends StatelessWidget {
  const ShoppingListWidget({
    super.key,
    required this.controller,
    this.onTapList,
    this.onTapViewAll,
  });

  final ShoppingListWidgetController controller;
  final void Function(ShoppingList list)? onTapList;
  final VoidCallback? onTapViewAll;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShoppingListWidgetState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state is ShoppingListWidgetLoading) {
          return const AppCard(
            child: SizedBox(height: 100, child: Center(child: AppLoading())),
          );
        }

        if (state is ShoppingListWidgetError) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Erro ao carregar listas de compras: ${state.failure}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final successState = state as ShoppingListWidgetSuccess;
        final theme = Theme.of(context);

        return Semantics(
          container: true,
          label: 'Widget de listas de compras',
          child: AppCard(
            key: const Key('shopping_list_widget_card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.shopping,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Listas de compras',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (successState.lists.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${successState.lists.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (successState.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AppEmptyState.mascot(
                      title: 'Nenhuma lista de compras',
                      description:
                          'Crie uma lista para acompanhar suas compras.',
                      mascotExpression: MascotExpression.shopping,
                      mascotSemanticLabel:
                          Localizations.of<AppLocalizations>(
                            context,
                            AppLocalizations,
                          )?.momoEmptyShoppingList ??
                          'Momo pronta para as compras — nenhuma listinha criada ainda',
                    ),
                  )
                else
                  Column(
                    children: successState.lists.map((item) {
                      final list = item.list;
                      final pendingText = item.pendingItems == 1
                          ? '1 item pendente'
                          : '${item.pendingItems} de ${item.totalItems} itens pendentes';

                      return Semantics(
                        container: true,
                        label: '${list.name}, $pendingText',
                        button: onTapList != null,
                        child: Container(
                          key: Key('shopping_list_item_${list.id}'),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: InkWell(
                            onTap: onTapList != null
                                ? () => onTapList!(list)
                                : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        list.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pendingText,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  AppIcons.shopping,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (onTapViewAll != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTapViewAll,
                      child: const Text('Ver todas as listas'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
