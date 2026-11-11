import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_providers.dart';

/// Dashboard card for Household Stock module (RF-102, RF-105, RN-370, CA-3.5).
class StockDashboardCard extends ConsumerWidget {
  const StockDashboardCard({super.key, this.controller, this.onTap});

  final StockController? controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StockController effectiveController =
        controller ?? ref.watch(stockControllerProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final title = l10n?.dashboardCardStockAlert ?? 'Estoque Doméstico';

    return ValueListenableBuilder<StockState>(
      valueListenable: effectiveController,
      builder: (context, state, child) {
        return Semantics(
          container: true,
          button: true,
          label: '$title, toque para ver detalhes',
          child: AppCard(
            key: const Key('stock_dashboard_card'),
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
                        AppIcons.stock,
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
                  if (state.isLoading && state.items.isEmpty)
                    const Center(child: AppLoading())
                  else if (state.items.isEmpty)
                    Text(
                      'Nenhum produto monitorado no estoque.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Text(
                      '${state.items.length} produto(s) no estoque doméstico',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
