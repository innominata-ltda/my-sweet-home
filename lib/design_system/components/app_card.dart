import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Standard card for the design system with 20dp rounded corners and subtle glow shadow (RN-292, CA-003.4).
///
/// Wrapper around [Card] with standard radius ([Radius.card] = 20dp) and standard internal
/// padding ([Spacing.md]). Supports [onTap] with tactile touch feedback (InkWell).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.margin = const EdgeInsets.only(bottom: Spacing.sm),
    this.onTap,
    this.color,
    this.elevation = 0,
    this.borderColor,
    this.borderRadius,
    this.hasGlow = true,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final bool hasGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(Radius.card);
    final glowColor = hasGlow
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : null;
    final effectiveElevation = elevation > 0
        ? elevation
        : (hasGlow ? 1.0 : 0.0);

    final shape = RoundedRectangleBorder(
      borderRadius: effectiveRadius,
      side: BorderSide(color: borderColor ?? theme.colorScheme.outlineVariant),
    );

    Widget content = child ?? const SizedBox.shrink();
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (onTap != null) {
      content = InkWell(
        borderRadius: effectiveRadius,
        onTap: onTap,
        child: content,
      );
    }

    return Card(
      elevation: effectiveElevation,
      shadowColor: glowColor,
      surfaceTintColor: Colors.transparent,
      color: color ?? theme.colorScheme.surface,
      shape: shape,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
