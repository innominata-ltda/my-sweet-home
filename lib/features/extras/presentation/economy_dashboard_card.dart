import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_providers.dart';

/// Card do Dashboard para o Modo Economia (RF-103, RF-102, RF-105, RN-370, RN-254, CA-3.5).
class EconomyDashboardCard extends ConsumerWidget {
  const EconomyDashboardCard({super.key, this.controller, this.onTap});

  final EconomyController? controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EconomyController effectiveController =
        controller ?? ref.watch(economyControllerProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final title = l10n?.dashboardCardEconomyGoal ?? 'Modo Economia';

    return ValueListenableBuilder<EconomyState>(
      valueListenable: effectiveController,
      builder: (context, state, child) {
        final goal = state.goal;
        final hasGoal = goal != null && goal.target.cents > 0;
        final goalText = hasGoal
            ? goal.target.formatPtBr()
            : 'Definir meta de economia';
        final message = state.assessment?.statusMessage;

        return Semantics(
          container: true,
          button: true,
          label: '$title, $goalText, toque para ver detalhes',
          child: AppCard(
            key: const Key('economy_dashboard_card'),
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
                        AppIcons.economy,
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
                  if (state.isLoading && state.assessment == null)
                    const Center(child: AppLoading())
                  else ...[
                    Text(
                      hasGoal ? 'Meta: $goalText' : goalText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (message != null && message.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
