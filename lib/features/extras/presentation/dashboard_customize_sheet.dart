import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart' hide Radius;
import 'package:my_sweet_home/design_system/theme/spacing.dart'
    as app_spacing
    show Radius;
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_controller.dart';

/// Modal bottom sheet for customizing order and visibility of Dashboard
/// (RF-105, RN-372, RN-374, RN-376, A11Y-10, CA-3.3, CA-3.4, CA-3.6, CA-3.7).
class DashboardCustomizeSheet extends StatelessWidget {
  const DashboardCustomizeSheet({super.key, required this.controller});

  final DashboardLayoutController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);

    return ValueListenableBuilder<DashboardLayoutState>(
      valueListenable: controller,
      builder: (context, state, child) {
        final visibleItems = state is DashboardLayoutLoaded
            ? state.visibleItems
            : DashboardLayoutConfig.defaultOrder;
        final hiddenItems = state is DashboardLayoutLoaded
            ? state.hiddenItems
            : <DashboardItemKind>[];

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(app_spacing.Radius.lg),
                ),
              ),
              child: Column(
                children: [
                  // Handle superior
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: Spacing.sm),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(
                          app_spacing.Radius.full,
                        ),
                      ),
                    ),
                  ),

                  // Sheet header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n?.customizeDashboardTitle ??
                                'Personalizar início',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          key: const Key('restore_default_button'),
                          icon: const Icon(AppIcons.restore, size: 20),
                          label: Text(
                            l10n?.customizeDashboardRestoreDefault ??
                                'Restaurar padrão',
                          ),
                          onPressed: controller.resetToDefault,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(Spacing.md),
                      children: [
                        // Section 1: Visible items
                        Text(
                          'Cards exibidos (${visibleItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Arraste para reordenar ou utilize os botões acessíveis.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),

                        if (visibleItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            child: Text(
                              'Nenhum card visível no momento.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: visibleItems.length,
                            // ignore: deprecated_member_use
                            onReorder: controller.reorder,
                            itemBuilder: (context, index) {
                              final kind = visibleItems[index];
                              final isFirst = index == 0;
                              final isLast = index == visibleItems.length - 1;
                              final title = _getCardTitle(kind, l10n);

                              return _buildVisibleItemTile(
                                context: context,
                                key: ValueKey('visible_${kind.name}'),
                                kind: kind,
                                title: title,
                                index: index,
                                isFirst: isFirst,
                                isLast: isLast,
                                l10n: l10n,
                                theme: theme,
                              );
                            },
                          ),

                        const SizedBox(height: Spacing.lg),

                        // Section 2: Hidden items available in catalog
                        Text(
                          l10n?.customizeDashboardAddCards ??
                              'Adicionar ao painel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Módulos disponíveis para inclusão na sua tela inicial.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),

                        if (hiddenItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            child: Text(
                              'Todos os cards já estão visíveis no painel.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...hiddenItems.map((kind) {
                            final title = _getCardTitle(kind, l10n);
                            return _buildHiddenItemTile(
                              context: context,
                              key: ValueKey('hidden_${kind.name}'),
                              kind: kind,
                              title: title,
                              l10n: l10n,
                              theme: theme,
                            );
                          }),

                        const SizedBox(height: Spacing.xl),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisibleItemTile({
    required BuildContext context,
    required Key key,
    required DashboardItemKind kind,
    required String title,
    required int index,
    required bool isFirst,
    required bool isLast,
    required AppLocalizations? l10n,
    required ThemeData theme,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Row(
          children: [
            // Drag handle for drag-and-drop
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: 'Arrastar $title para reordenar',
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.sm),
                  child: Icon(
                    AppIcons.dragHandle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.xs),
            Icon(
              _getCardIcon(kind),
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Accessible button: Move up (target >= 48dp)
            Semantics(
              label: 'Mover $title para cima',
              button: true,
              excludeSemantics: true,
              child: IconButton(
                key: Key('move_up_${kind.name}'),
                icon: const Icon(AppIcons.moveUp, size: 20),
                tooltip: l10n?.customizeDashboardMoveUp ?? 'Mover para cima',
                constraints: const BoxConstraints(
                  minWidth: Spacing.touchTarget,
                  minHeight: Spacing.touchTarget,
                ),
                onPressed: isFirst ? null : () => controller.moveUp(kind),
              ),
            ),

            // Accessible button: Move down (target >= 48dp)
            Semantics(
              label: 'Mover $title para baixo',
              button: true,
              excludeSemantics: true,
              child: IconButton(
                key: Key('move_down_${kind.name}'),
                icon: const Icon(AppIcons.moveDown, size: 20),
                tooltip: l10n?.customizeDashboardMoveDown ?? 'Mover para baixo',
                constraints: const BoxConstraints(
                  minWidth: Spacing.touchTarget,
                  minHeight: Spacing.touchTarget,
                ),
                onPressed: isLast ? null : () => controller.moveDown(kind),
              ),
            ),

            // Accessible button: Hide (target >= 48dp)
            Semantics(
              label: 'Ocultar $title',
              button: true,
              excludeSemantics: true,
              child: IconButton(
                key: Key('hide_${kind.name}'),
                icon: const Icon(AppIcons.removeCircle, size: 20),
                tooltip: l10n?.customizeDashboardHide ?? 'Ocultar',
                color: theme.colorScheme.error,
                constraints: const BoxConstraints(
                  minWidth: Spacing.touchTarget,
                  minHeight: Spacing.touchTarget,
                ),
                onPressed: () => controller.hide(kind),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenItemTile({
    required BuildContext context,
    required Key key,
    required DashboardItemKind kind,
    required String title,
    required AppLocalizations? l10n,
    required ThemeData theme,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              _getCardIcon(kind),
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Accessible button: Add (target >= 48dp)
            Semantics(
              label: 'Adicionar $title ao painel',
              button: true,
              excludeSemantics: true,
              child: TextButton.icon(
                key: Key('add_${kind.name}'),
                icon: const Icon(AppIcons.add, size: 20),
                label: Text(l10n?.customizeDashboardAdd ?? 'Adicionar'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    Spacing.touchTarget,
                    Spacing.touchTarget,
                  ),
                ),
                onPressed: () => controller.show(kind),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getCardTitle(DashboardItemKind kind, AppLocalizations? l10n) {
    switch (kind) {
      case DashboardItemKind.mascotGreeting:
        return l10n?.dashboardCardMascotGreeting ?? 'Saudação da Momo';
      case DashboardItemKind.monthBalance:
        return l10n?.dashboardCardMonthBalance ?? 'Saldo do Mês';
      case DashboardItemKind.dueBills:
        return l10n?.dashboardCardDueBills ?? 'Contas a Vencer';
      case DashboardItemKind.todayTasks:
        return l10n?.dashboardCardTodayTasks ?? 'Tarefas de Hoje';
      case DashboardItemKind.shoppingList:
        return l10n?.dashboardCardShoppingList ?? 'Lista de Compras';
      case DashboardItemKind.stockAlert:
        return l10n?.dashboardCardStockAlert ?? 'Estoque Doméstico';
      case DashboardItemKind.firstHomeChecklist:
        return l10n?.dashboardCardFirstHomeChecklist ??
            'Checklist da Primeira Casa';
      case DashboardItemKind.economyGoal:
        return l10n?.dashboardCardEconomyGoal ?? 'Modo Economia';
      case DashboardItemKind.favoriteRecipes:
        return l10n?.dashboardCardFavoriteRecipes ?? 'Receitas Favoritas';
    }
  }

  static IconData _getCardIcon(DashboardItemKind kind) {
    switch (kind) {
      case DashboardItemKind.mascotGreeting:
        return AppIcons.catPets;
      case DashboardItemKind.monthBalance:
        return AppIcons.budget;
      case DashboardItemKind.dueBills:
        return AppIcons.calendar;
      case DashboardItemKind.todayTasks:
        return AppIcons.tasks;
      case DashboardItemKind.shoppingList:
        return AppIcons.shopping;
      case DashboardItemKind.stockAlert:
        return AppIcons.stock;
      case DashboardItemKind.firstHomeChecklist:
        return AppIcons.checklist;
      case DashboardItemKind.economyGoal:
        return AppIcons.economy;
      case DashboardItemKind.favoriteRecipes:
        return AppIcons.recipes;
    }
  }
}
