import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_error_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_controller.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({
    super.key,
    required this.controller,
    required this.onPayBill,
    this.onUnpayBill,
    required this.onCreateBill,
    required this.onTapBill,
    this.onPauseBill,
    this.onDeleteBill,
    this.highlightedBillId,
  });

  final BillsListController controller;
  final void Function(BillListItem) onPayBill;
  final void Function(BillListItem)? onUnpayBill;
  final VoidCallback onCreateBill;
  final void Function(BillListItem) onTapBill;
  final void Function(BillListItem)? onPauseBill;
  final void Function(BillListItem)? onDeleteBill;
  final String? highlightedBillId;

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  String? get _effectiveHighlightedBillId {
    if (widget.highlightedBillId != null &&
        widget.highlightedBillId!.isNotEmpty) {
      return widget.highlightedBillId;
    }
    try {
      final state = GoRouterState.of(context);
      if (state.extra is String && (state.extra as String).isNotEmpty) {
        return state.extra as String;
      }
      final idParam = state.uri.queryParameters['id'];
      if (idParam != null && idParam.isNotEmpty) {
        return idParam;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.value;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.billsTitle),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            onPressed: widget.onCreateBill,
            tooltip: l10n.billsCreate,
          ),
        ],
      ),
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BillsListState state,
    AppLocalizations l10n,
  ) {
    if (state is BillsListLoading) {
      return const AppLoading();
    }

    if (state is BillsListError) {
      return AppErrorState(
        message: l10n.billsError,
        retryLabel: l10n.billsRetry,
        onRetry: widget.controller.load,
      );
    }

    if (state is BillsListSuccess) {
      if (state.isEmpty) {
        return AppEmptyState.mascot(
          title: l10n.billsEmpty,
          actionLabel: l10n.billsCreate,
          onAction: widget.onCreateBill,
          mascotExpression: MascotExpression.happy,
        );
      }

      return ListView(
        children: [
          if (state.lacksPermission)
            ListTile(
              tileColor: Colors.amber.shade100,
              leading: const Icon(AppIcons.warning, color: Colors.amber),
              title: Text(l10n.billsNotificationPermissionDeniedWarning),
              subtitle: TextButton(
                onPressed: widget.controller.requestNotificationPermission,
                child: Text(l10n.billsNotificationPermissionDeniedSettings),
              ),
              trailing: IconButton(
                icon: const Icon(AppIcons.close),
                tooltip: l10n.billsNotificationPermissionDeniedDismiss,
                onPressed: widget.controller.dismissNotificationWarning,
              ),
            ),
          if (state.showBatteryOptimizationHint)
            ListTile(
              tileColor: Colors.blue.shade50,
              leading: const Icon(AppIcons.batteryWarning, color: Colors.blue),
              title: Text(l10n.billsNotificationWarning),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(l10n.billsNotificationWarningExplanation),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: widget.controller.openBatterySettings,
                    child: Text(l10n.billsNotificationAllow),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          if (state.isAllPaid)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.paid, color: Colors.green.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.billsAllPaid,
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final item in state.items) _buildItem(context, item, l10n),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _monthName(int month) {
    const months = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  Widget _buildItem(
    BuildContext context,
    BillListItem item,
    AppLocalizations l10n,
  ) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (item.status) {
      case BillStatus.paid:
        statusIcon = AppIcons.paid;
        statusColor = Colors.green;
        statusText = l10n.billsStatusPaid;
        break;
      case BillStatus.late:
        statusIcon = AppIcons.error;
        statusColor = Colors.red;
        statusText = l10n.billsStatusOverdue;
        break;
      case BillStatus.pending:
      case BillStatus.skipped:
        statusIcon = AppIcons.pending;
        statusColor = Colors.orange;
        statusText = l10n.billsStatusPending;
        break;
    }

    final isHighlighted =
        _effectiveHighlightedBillId != null &&
        (item.bill.id == _effectiveHighlightedBillId ||
            item.payment.id == _effectiveHighlightedBillId);

    final tile = ListTile(
      key: Key('bill_item_${item.bill.id}'),
      onTap: () => widget.onTapBill(item),
      selected: isHighlighted,
      leading: CircleAvatar(child: Icon(statusIcon, color: statusColor)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.bill.title,
              style: isHighlighted
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Destaque',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusText, style: TextStyle(color: statusColor)),
                ],
              ),
              Text(
                '• Vence dia ${item.payment.dueOn.day} de ${_monthName(item.payment.dueOn.month)}',
              ),
            ],
          ),
          if (item.bill.amount != null) ...[
            const SizedBox(height: 2),
            Text(
              'R\$ ${(item.bill.amount!.cents / 100).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.status != BillStatus.paid)
            IconButton(
              icon: const Icon(AppIcons.money),
              tooltip: l10n.billsMarkAsPaid(item.bill.title),
              onPressed: () => widget.onPayBill(item),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ), // A11Y-5
            )
          else
            IconButton(
              icon: const Icon(AppIcons.undo),
              tooltip: 'Desmarcar pagamento de ${item.bill.title}',
              onPressed: () {
                if (widget.onUnpayBill != null) {
                  widget.onUnpayBill!(item);
                } else {
                  widget.controller.unpayBill(item.payment.id);
                }
              },
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          PopupMenuButton<String>(
            tooltip: 'Opções da conta',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (action) async {
              if (action == 'unpay') {
                if (widget.onUnpayBill != null) {
                  widget.onUnpayBill!(item);
                } else {
                  await widget.controller.unpayBill(item.payment.id);
                }
              } else if (action == 'pause') {
                if (widget.onPauseBill != null) {
                  widget.onPauseBill!(item);
                } else {
                  await widget.controller.pauseBill(item.bill.id);
                }
              } else if (action == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Excluir conta?'),
                    content: Text(
                      'Tem certeza de que deseja excluir a conta "${item.bill.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (widget.onDeleteBill != null) {
                    widget.onDeleteBill!(item);
                  } else {
                    await widget.controller.deleteBill(item.bill.id);
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              if (item.status == BillStatus.paid)
                const PopupMenuItem(
                  value: 'unpay',
                  child: Text('Marcar como não pago'),
                ),
              const PopupMenuItem(value: 'pause', child: Text('Pausar conta')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Excluir conta'),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        key: Key('bill_container_${item.bill.id}'),
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.3)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isHighlighted
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: tile,
      ),
    );
  }
}
