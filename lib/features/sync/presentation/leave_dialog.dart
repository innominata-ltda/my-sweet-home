// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Confirmation dialog for leaving shared household (RF-126, CA-7.2, CA-7.3, T-15).
class LeaveHouseholdDialog extends StatefulWidget {
  final Future<void> Function({required bool keepCopy}) onConfirm;

  const LeaveHouseholdDialog({super.key, required this.onConfirm});

  @override
  State<LeaveHouseholdDialog> createState() => _LeaveHouseholdDialogState();
}

class _LeaveHouseholdDialogState extends State<LeaveHouseholdDialog> {
  bool _keepCopy = true;
  bool _secondConfirm = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_secondConfirm) {
      return AlertDialog(
        title: Text(l10n.householdLeaveDeleteConfirmTitle),
        content: Text(l10n.householdLeaveDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() => _secondConfirm = false),
            child: Text(l10n.commonBack),
          ),
          AppButton.danger(
            key: const Key('confirm_wipe_leave_button'),
            label: l10n.householdLeaveDeleteAndExit,
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _isLoading = true);
              await widget.onConfirm(keepCopy: false);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(l10n.householdLeaveDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.householdLeaveDialogBody),
          const SizedBox(height: Spacing.md),
          RadioListTile<bool>(
            key: const Key('leave_keep_copy_radio'),
            title: Text(l10n.householdLeaveKeepLocalTitle),
            subtitle: Text(l10n.householdLeaveKeepLocalSubtitle),
            value: true,
            groupValue: _keepCopy,
            onChanged: (val) => setState(() => _keepCopy = val ?? true),
          ),
          RadioListTile<bool>(
            key: const Key('leave_wipe_radio'),
            title: Text(l10n.householdLeaveWipeData),
            subtitle: Text(l10n.householdLeaveWipeSubtitle),
            value: false,
            groupValue: _keepCopy,
            onChanged: (val) => setState(() => _keepCopy = val ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('confirm_leave_button'),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_keepCopy) {
                    setState(() => _secondConfirm = true);
                    return;
                  }
                  setState(() => _isLoading = true);
                  await widget.onConfirm(keepCopy: true);
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
