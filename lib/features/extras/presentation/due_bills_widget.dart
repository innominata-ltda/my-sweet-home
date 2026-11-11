import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_controller.dart';

/// Widget de contas a vencer para a tela inicial / dashboard (RF-102, RN-253, CA-3.1, CA-3.2, CA-110.6, RN-284).
class DueBillsWidget extends StatelessWidget {
  const DueBillsWidget({
    super.key,
    required this.controller,
    this.title,
    this.onTapBill,
    this.onTapViewAll,
  });

  final DueBillsWidgetController controller;
  final String? title;
  final void Function(Bill bill)? onTapBill;
  final VoidCallback? onTapViewAll;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DueBillsWidgetState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state is DueBillsWidgetLoading) {
          return const AppCard(
            child: SizedBox(height: 100, child: Center(child: AppLoading())),
          );
        }

        if (state is DueBillsWidgetError) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Erro ao carregar contas a vencer: ${state.failure}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final successState = state as DueBillsWidgetSuccess;
        final theme = Theme.of(context);

        return Semantics(
          container: true,
          label: 'Widget de contas a vencer',
          child: AppCard(
            key: const Key('due_bills_widget_card'),
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
                            AppIcons.bill,
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
                                  )?.dashboardDueBillsTitle ??
                                  'Contas a vencer',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (successState.items.isNotEmpty)
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
                          '${successState.items.length}',
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
                      title: 'Nenhuma conta a vencer',
                      description:
                          'Todas as suas contas deste mês estão em dia.',
                      mascotExpression: MascotExpression.relaxed,
                      mascotSemanticLabel:
                          Localizations.of<AppLocalizations>(
                            context,
                            AppLocalizations,
                          )?.mascotSemanticsRelaxed ??
                          'Momo está relaxada e tranquila',
                    ),
                  )
                else
                  Column(
                    children: successState.items.map((item) {
                      final isLate = item.status == BillStatus.late;
                      final isDueToday = item.dueLabel == 'Vence hoje';

                      Color statusColor;
                      if (isLate) {
                        statusColor = theme.colorScheme.error;
                      } else if (isDueToday) {
                        statusColor = theme.colorScheme.tertiary;
                      } else {
                        statusColor = theme.colorScheme.secondary;
                      }

                      final String amountText;
                      if (successState.hideValues) {
                        amountText = 'R\$ ***';
                      } else if (item.amount != null) {
                        amountText = item.amount!.formatPtBr();
                      } else {
                        amountText = 'Variável';
                      }

                      return Semantics(
                        container: true,
                        label:
                            '${item.bill.title}, ${item.dueLabel}, ${successState.hideValues ? "valor oculto" : "valor $amountText"}',
                        button: onTapBill != null,
                        child: Container(
                          key: Key('due_bill_item_${item.bill.id}'),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLate
                                  ? theme.colorScheme.error.withValues(
                                      alpha: 0.5,
                                    )
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                          ),
                          child: InkWell(
                            onTap: onTapBill != null
                                ? () => onTapBill!(item.bill)
                                : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.bill.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.dueLabel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: statusColor,
                                              fontWeight: isLate || isDueToday
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  amountText,
                                  key: Key('due_bill_amount_${item.bill.id}'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      child: const Text('Ver todas as contas'),
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
