import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Standard list item for the design system.
///
/// Wrapper around [ListTile] with standard border radius ([Radius.sm]),
/// standardized spacing ([Spacing.md] horizontal, [Spacing.xs] vertical), and
/// accessible minimum touch area.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.contentPadding,
    this.dense,
    this.shape,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      selected: selected,
      dense: dense,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
      minVerticalPadding: Spacing.sm,
      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radius.sm),
          ),
    );
  }
}
