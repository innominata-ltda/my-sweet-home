import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Official error state component for Design System (SPEC-005, RF-110, RNF-006).
///
/// Displays icon, user-friendly error message, and optional "try again" button.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.warning, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.lg),
              AppButton.primary(
                label: retryLabel ?? 'Tentar de novo',
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
