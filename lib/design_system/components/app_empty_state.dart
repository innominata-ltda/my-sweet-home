import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

export 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart'
    show MascotExpression;

/// Empty state component for the design system (RF-110, CA-110.6, CA-289.1).
///
/// Displays an icon, illustration, or the Momo mascot with contextual expression,
/// explanatory text, and a primary action button to guide the user on how to start.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = AppIcons.info,
    this.illustration,
    this.mascotConfig,
    this.mascotResolver,
    this.mascotExpression,
    this.mascotSemanticLabel,
    this.animateMascot = false,
    this.actionLabel,
    this.onAction,
    this.action,
  });

  /// Convenience constructor that renders the Momo mascot with contextual expression (CA-110.6, CA-289.1).
  const AppEmptyState.mascot({
    super.key,
    required this.title,
    this.description,
    this.mascotConfig,
    this.mascotResolver,
    this.mascotExpression = MascotExpression.thinking,
    this.mascotSemanticLabel,
    this.animateMascot = false,
    this.actionLabel,
    this.onAction,
    this.action,
  }) : icon = null,
       illustration = null;

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? illustration;
  final MascotConfig? mascotConfig;
  final MascotAssetResolver? mascotResolver;
  final MascotExpression? mascotExpression;
  final String? mascotSemanticLabel;
  final bool animateMascot;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? visual;
    if (illustration != null) {
      visual = illustration;
    } else if (mascotExpression != null) {
      visual = MascotWidget(
        config: mascotConfig,
        resolver: mascotResolver,
        expression: mascotExpression!,
        semanticLabel: mascotSemanticLabel,
        size: 96,
        animateIdle: animateMascot,
      );
    } else if (icon != null) {
      visual = Icon(icon, size: 64, color: theme.colorScheme.outline);
    }

    Widget? actionWidget = action;
    if (actionWidget == null && actionLabel != null && onAction != null) {
      actionWidget = AppButton.primary(
        label: actionLabel!,
        onPressed: onAction,
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (visual != null) ...[visual, const SizedBox(height: Spacing.md)],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionWidget != null) ...[
              const SizedBox(height: Spacing.lg),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}
