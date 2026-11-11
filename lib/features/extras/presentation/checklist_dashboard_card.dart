import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_providers.dart';

/// Card do Dashboard para o Checklist da Primeira Casa (RF-100, RF-102, RF-105, RN-370, CA-3.5).
class ChecklistDashboardCard extends ConsumerWidget {
  const ChecklistDashboardCard({super.key, this.controller, this.onTap});

  final ChecklistController? controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChecklistController effectiveController =
        controller ?? ref.watch(checklistControllerProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final title =
        l10n?.dashboardCardFirstHomeChecklist ?? 'Checklist da Primeira Casa';

    return ValueListenableBuilder<ChecklistState>(
      valueListenable: effectiveController,
      builder: (context, state, child) {
        final percent = (state.progress * 100).toStringAsFixed(0);

        return Semantics(
          container: true,
          button: true,
          label: '$title, $percent% concluído, toque para ver detalhes',
          child: AppCard(
            key: const Key('checklist_dashboard_card'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Spacing.touchTarget),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.checklist,
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
                      Text(
                        '$percent%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Icon(
                        AppIcons.chevronRight,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  if (state.isLoading && state.items.isEmpty)
                    const Center(child: AppLoading())
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radius.sm),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${state.markedCount} de ${state.totalCount} itens prontos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
