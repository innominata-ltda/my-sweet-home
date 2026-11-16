import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Dialog for manual generation and sharing of update bundle (.mshsync) (RF-123, RN-331).
class BundleShareDialog extends StatefulWidget {
  final Future<Uint8List?> Function() onGenerateBundle;
  final Future<bool> Function(Uint8List bytes)? onApplyBundle;

  const BundleShareDialog({
    super.key,
    required this.onGenerateBundle,
    this.onApplyBundle,
  });

  @override
  State<BundleShareDialog> createState() => _BundleShareDialogState();
}

class _BundleShareDialogState extends State<BundleShareDialog> {
  bool _isGenerating = false;
  Uint8List? _generatedBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.householdBundleShareTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.householdBundleShareDescription),
          const SizedBox(height: Spacing.md),
          if (_generatedBytes != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(Radius.card),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.check, size: 24),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.householdBundleGeneratedSuccess(
                        _generatedBytes!.lengthInBytes,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
        AppButton.primary(
          key: const Key('action_generate_bundle_button'),
          label: _generatedBytes == null
              ? l10n.householdGenerateBundleButton
              : l10n.householdBundleShareAction,
          icon: const Icon(AppIcons.fileExport),
          isLoading: _isGenerating,
          onPressed: () async {
            setState(() => _isGenerating = true);
            try {
              final bytes = await widget.onGenerateBundle();
              if (mounted) {
                setState(() {
                  _generatedBytes = bytes;
                  _isGenerating = false;
                });
              }
            } catch (_) {
              if (mounted) setState(() => _isGenerating = false);
            }
          },
        ),
      ],
    );
  }
}
