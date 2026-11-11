import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Smooth progress bar with rounded corners and subtle primary color glow (RN-292, CA-003.4).
///
/// Respects [MediaQuery.disableAnimations] (immediate transition if active, no interpolation animation).
/// Includes full semantic support for screen readers and TalkBack.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({
    super.key,
    required this.value,
    this.height = Spacing.sm,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.hasGlow = true,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// Progress value between 0.0 (0%) and 1.0 (100%).
  /// Values outside this range are clamped via [clamp].
  final double value;

  /// Height of the bar in dp. Default: 8 dp ([Spacing.sm]).
  final double height;

  /// Fill color of the bar. Default: [ColorScheme.primary].
  final Color? color;

  /// Track background color. Default: [ColorScheme.surfaceContainerHighest].
  final Color? backgroundColor;

  /// Border radius. Default: [Radius.full] (pill).
  final BorderRadius? borderRadius;

  /// If true, projects a subtle glow in primary color (RN-292, CA-003.4).
  final bool hasGlow;

  /// Label for accessibility/TalkBack.
  final String? semanticsLabel;

  /// Announced value for accessibility/TalkBack (e.g., "75%").
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeValue = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveBgColor =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(Radius.full);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final percentInt = (safeValue * 100).round();

    final glowShadows = hasGlow
        ? AppShadows.softGlow(effectiveColor, opacity: 0.25)
        : const <BoxShadow>[];

    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '$percentInt%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          color: effectiveBgColor,
          boxShadow: glowShadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final filledWidth = constraints.maxWidth * safeValue;

            if (disableAnimations) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: filledWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    borderRadius: effectiveRadius,
                  ),
                ),
              );
            }

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: filledWidth),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, currentWidth, child) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: currentWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      borderRadius: effectiveRadius,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
