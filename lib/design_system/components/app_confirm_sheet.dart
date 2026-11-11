import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Modal bottom sheet for confirming critical or reversible actions.
///
/// Presents title, explanatory message, and standardized confirmation
/// and cancellation buttons.
class AppConfirmSheet extends StatelessWidget {
  const AppConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDanger = false,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Displays confirmation bottom sheet and returns `true` if confirmed,
  /// `false` if cancelled, or `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDanger = false,
    IconData? icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: ui.Radius.circular(Radius.lg)),
      ),
      builder: (sheetContext) => AppConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
        onCancel: () => Navigator.of(sheetContext).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final VoidCallback effectiveCancel =
        onCancel ?? () => Navigator.of(context).pop(false);
    final VoidCallback effectiveConfirm =
        onConfirm ?? () => Navigator.of(context).pop(true);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(Radius.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isDanger
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: cancelLabel,
                    onPressed: effectiveCancel,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: isDanger
                      ? AppButton.danger(
                          label: confirmLabel,
                          onPressed: effectiveConfirm,
                        )
                      : AppButton.primary(
                          label: confirmLabel,
                          onPressed: effectiveConfirm,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
