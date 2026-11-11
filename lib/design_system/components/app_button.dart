import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Available variants for [AppButton].
enum AppButtonVariant { primary, secondary, text, danger }

/// Standard button for the design system with accessible touch target (minimum 48dp).
///
/// Supports 4 variants: [AppButtonVariant.primary], [AppButtonVariant.secondary],
/// [AppButtonVariant.text] and [AppButtonVariant.danger].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minSize = Size(
      fullWidth ? double.infinity : Spacing.touchTarget,
      Spacing.touchTarget,
    );
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(Radius.button);

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    Widget content;
    if (isLoading) {
      final progressColor = _progressIndicatorColor(theme);
      content = SizedBox(
        width: Spacing.lg,
        height: Spacing.lg,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: Spacing.sm),
          Text(label),
        ],
      );
    } else {
      content = Text(label);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
            elevation: 2,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          child: content,
        );

      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            elevation: 0,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: effectiveBorderRadius,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          child: content,
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          child: content,
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
          child: content,
        );
    }
  }

  Color _progressIndicatorColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case AppButtonVariant.secondary:
        return theme.colorScheme.onSecondaryContainer;
      case AppButtonVariant.text:
        return theme.colorScheme.primary;
      case AppButtonVariant.danger:
        return theme.colorScheme.onError;
    }
  }
}
