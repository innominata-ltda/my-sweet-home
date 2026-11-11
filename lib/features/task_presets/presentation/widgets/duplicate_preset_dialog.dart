import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

/// Confirmation dialog for adding preset already in routine (RN-357, CA-3.1).
class DuplicatePresetDialog extends StatelessWidget {
  const DuplicatePresetDialog({super.key, required this.presetTitle});

  final String presetTitle;

  static Future<bool?> show(
    BuildContext context, {
    required String presetTitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DuplicatePresetDialog(presetTitle: presetTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.taskPresetsDuplicateTitle),
      content: Text(l10n.taskPresetsDuplicateMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.taskPresetsDuplicateCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.taskPresetsDuplicateConfirm),
        ),
      ],
    );
  }
}
