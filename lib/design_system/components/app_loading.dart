import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Skeleton loading state component.
///
/// **Rule:** Does NOT use centralized spinner; uses surface color containers
/// simulating approximate shape of final content.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.size,
  }) : width = size,
       height = size,
       borderRadius = Radius.md,
       _mode = size != null ? _LoadingMode.spinner : _LoadingMode.list;

  const AppLoading.spinner({super.key, this.size = 20.0})
    : width = size,
      height = size,
      itemCount = 1,
      borderRadius = Radius.md,
      padding = EdgeInsets.zero,
      _mode = _LoadingMode.spinner;

  const AppLoading.box({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius = Radius.sm,
  }) : size = null,
       itemCount = 1,
       padding = EdgeInsets.zero,
       _mode = _LoadingMode.box;

  const AppLoading.card({
    super.key,
    this.height = 80.0,
    this.borderRadius = Radius.md,
    this.padding = const EdgeInsets.only(bottom: Spacing.sm),
  }) : size = null,
       itemCount = 1,
       width = double.infinity,
       _mode = _LoadingMode.card;

  final int itemCount;
  final double? width;
  final double? height;
  final double? size;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final _LoadingMode _mode;

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _LoadingMode.box:
        return _buildSkeletonBox(
          context,
          w: width,
          h: height ?? 16.0,
          radius: borderRadius,
        );

      case _LoadingMode.card:
        return Padding(
          padding: padding,
          child: _buildSkeletonBox(
            context,
            w: width ?? double.infinity,
            h: height ?? 80.0,
            radius: borderRadius,
          ),
        );

      case _LoadingMode.spinner:
        return SizedBox(
          width: size ?? 20.0,
          height: size ?? 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );

      case _LoadingMode.list:
        return ListView.separated(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
          itemBuilder: (context, _) => Row(
            children: [
              _buildSkeletonBox(
                context,
                w: Spacing.xxl,
                h: Spacing.xxl,
                radius: Radius.sm,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonBox(
                      context,
                      w: double.infinity,
                      h: 16.0,
                      radius: Radius.sm,
                    ),
                    const SizedBox(height: Spacing.sm),
                    _buildSkeletonBox(
                      context,
                      w: 120.0,
                      h: 12.0,
                      radius: Radius.sm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSkeletonBox(
    BuildContext context, {
    double? w,
    required double h,
    required double radius,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

enum _LoadingMode { list, box, card, spinner }
