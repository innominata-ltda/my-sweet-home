import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_controller.dart';

/// Month balance widget for home screen / dashboard (RF-102, RN-253, CA-3.2, CA-110.6, RN-284, RN-293).
class MonthBalanceWidget extends StatelessWidget {
  const MonthBalanceWidget({
    super.key,
    required this.controller,
    this.title,
    this.mascot,
    this.onTapViewDetails,
  });

  final MonthBalanceWidgetController controller;
  final String? title;
  final Widget? mascot;
  final VoidCallback? onTapViewDetails;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MonthBalanceWidgetState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state is MonthBalanceWidgetLoading) {
          return const AppCard(
            child: SizedBox(height: 100, child: Center(child: AppLoading())),
          );
        }

        if (state is MonthBalanceWidgetError) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Erro ao carregar saldo do mês: ${state.failure}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final successState = state as MonthBalanceWidgetSuccess;
        final summary = successState.summary;
        final theme = Theme.of(context);

        final String actualText = successState.hideValues
            ? 'R\$ ***'
            : summary.actual.formatPtBr();

        final String budgetText = summary.budget != null
            ? (successState.hideValues
                  ? 'R\$ ***'
                  : summary.budget!.formatPtBr())
            : 'Não definido';

        final String remainingText = summary.remaining != null
            ? (successState.hideValues
                  ? 'R\$ ***'
                  : summary.remaining!.formatPtBr())
            : 'N/A';

        final double? progress =
            (summary.budget != null && summary.budget!.cents > 0)
            ? (summary.actual.cents / summary.budget!.cents).clamp(0.0, 1.0)
            : null;

        return Semantics(
          container: true,
          label:
              'Widget de saldo do mês, ${successState.hideValues ? "valor oculto" : "gasto $actualText de $budgetText"}',
          child: AppCard(
            key: const Key('month_balance_widget_card'),
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
                            AppIcons.budget,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title ??
                                  Localizations.of<AppLocalizations>(
                                    context,
                                    AppLocalizations,
                                  )?.dashboardMonthBalanceTitle ??
                                  'Saldo do mês',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mascot != null) ...[
                      const SizedBox(width: 8),
                      KeyedSubtree(
                        key: const Key('month_balance_mascot'),
                        child: mascot!,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gasto no mês',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          actualText,
                          key: const Key('month_balance_actual_text'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (summary.budget != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restante',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remainingText,
                            key: const Key('month_balance_remaining_text'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  (summary.remaining != null &&
                                      summary.remaining!.cents < 0)
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    color: progress >= 0.9
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Orçado: $budgetText',
                        key: const Key('month_balance_budget_text'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                if (onTapViewDetails != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTapViewDetails,
                      child: const Text('Ver resumo financeiro'),
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
