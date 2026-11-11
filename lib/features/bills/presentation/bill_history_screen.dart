import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

import 'package:my_sweet_home/features/bills/presentation/bill_history_controller.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key, required this.controller});

  final BillHistoryController controller;

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.value;
    final l10n = AppLocalizations.of(context);

    String title = l10n.billHistoryTitle;
    if (state is BillHistorySuccess) {
      title = state.bill.title;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BillHistoryState state,
    AppLocalizations l10n,
  ) {
    if (state is BillHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is BillHistoryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.billHistoryError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.controller.load,
              child: Text(l10n.billHistoryRetry),
            ),
          ],
        ),
      );
    }

    if (state is BillHistorySuccess) {
      if (state.isEmpty) {
        return Center(
          child: Text(l10n.billHistoryEmpty, textAlign: TextAlign.center),
        );
      }

      return ListView.builder(
        itemCount: state.payments.length,
        itemBuilder: (context, index) {
          final payment = state.payments[index];
          return _buildItem(context, payment, l10n);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildItem(
    BuildContext context,
    BillPayment payment,
    AppLocalizations l10n,
  ) {
    final isPaid = payment.paidOn != null;
    final amountStr = payment.paidAmount?.formatPtBr() ?? '--';

    // Simplistic date format, since no specific requirement
    final dueStr =
        '${payment.dueOn.day.toString().padLeft(2, '0')}/${payment.dueOn.month.toString().padLeft(2, '0')}/${payment.dueOn.year}';
    final paidStr = isPaid
        ? '${payment.paidOn!.day.toString().padLeft(2, '0')}/${payment.paidOn!.month.toString().padLeft(2, '0')}/${payment.paidOn!.year}'
        : '--';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPaid ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(
          isPaid ? AppIcons.check : AppIcons.pending,
          color: isPaid ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(l10n.billHistoryDueOn(dueStr)),
      subtitle: Text(
        isPaid ? l10n.billHistoryPaidOn(paidStr) : l10n.billsStatusPending,
      ),
      trailing: Text(
        amountStr,
        style: TextStyle(
          fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
          color: isPaid ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}
