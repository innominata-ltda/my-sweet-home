import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';

export 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart'
    show MascotAnimal;
export 'package:my_sweet_home/features/mascot/presentation/widgets/celebration_overlay.dart';

/// Visual shape of [CuteCheckbox] (SPEC-012, RN-280, CA-112.4).
enum CuteCheckboxShape {
  /// Heart icon (used by bunny).
  heart,

  /// Paw icon (used by cat and dog or fallback).
  paw;

  /// Resolves the appropriate shape from the mascot animal (cat/paw default per CA-110.1).
  static CuteCheckboxShape fromAnimal(MascotAnimal? animal) {
    final effectiveAnimal = animal ?? MascotConfig.defaultMomo.animal;
    return switch (effectiveAnimal) {
      MascotAnimal.cat || MascotAnimal.dog => CuteCheckboxShape.paw,
      MascotAnimal.bunny => CuteCheckboxShape.heart,
    };
  }
}

/// Affective checkbox of the Design System with heart or paw icon (SPEC-012, RF-112, RN-280, CA-112.4).
///
/// Characteristics:
/// - Displays heart or paw icon according to active Momo mascot animal (or fallback).
/// - Elastic bounce animation when checked.
/// - Supports static dry cut when [MediaQuery.disableAnimations] is true (CA-112.4, RN-290).
/// - Minimum accessible touch target of 48dp (A11Y-2).
/// - Semantic label and checkbox state for TalkBack accessibility (A11Y-3).
class CuteCheckbox extends ConsumerStatefulWidget {
  const CuteCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.animal,
    this.shape,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.activeColor,
    this.inactiveColor,
    this.size = 24.0,
    this.disableAnimations,
    this.fallbackShape = CuteCheckboxShape.paw,
  });

  /// Whether the checkbox is checked.
  final bool value;

  /// Callback triggered when user taps the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Mascot animal for icon resolution (overrides global configuration).
  final MascotAnimal? animal;

  /// Forced shape (heart or paw). If null, resolves from [animal] or global mascot.
  final CuteCheckboxShape? shape;

  /// Explicit semantic label for screen readers.
  final String? semanticLabel;

  /// If true, omits internal semantic node (useful when parent widget already provides complete semantics).
  final bool excludeSemantics;

  /// Icon color when checked (default: `ColorScheme.primary`).
  final Color? activeColor;

  /// Icon color when unchecked (default: `ColorScheme.outline`).
  final Color? inactiveColor;

  /// Icon size (touch target maintains 48dp minimum).
  final double size;

  /// Forces animations off (if null, queries [MediaQuery.disableAnimationsOf(context)]).
  final bool? disableAnimations;

  /// Fallback shape when no animal is identified.
  final CuteCheckboxShape fallbackShape;

  @override
  ConsumerState<CuteCheckbox> createState() => CuteCheckboxState();
}

class CuteCheckboxState extends ConsumerState<CuteCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  /// Animation controller exposed for inspection in tests.
  AnimationController get animationController => _bounceController;

  /// Indicates whether animations should be executed.
  bool get shouldAnimate {
    final disableSystem =
        widget.disableAnimations ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return !disableSystem;
  }

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant CuteCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.value && widget.value) {
      if (shouldAnimate) {
        _bounceController.forward(from: 0.0);
      } else {
        _bounceController.value = 1.0;
      }
    } else if (oldWidget.value && !widget.value) {
      _bounceController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// Resolves effective checkbox shape (heart or paw).
  CuteCheckboxShape resolveShape() {
    if (widget.shape != null) {
      return widget.shape!;
    }
    if (widget.animal != null) {
      return CuteCheckboxShape.fromAnimal(widget.animal);
    }
    try {
      final config = ref
          .watch(mascotConfigStreamProvider)
          .maybeWhen(data: (c) => c, orElse: () => null);
      if (config != null) {
        return CuteCheckboxShape.fromAnimal(config.animal);
      }
    } catch (_) {
      // No ProviderScope or repository unavailable
    }
    return widget.fallbackShape;
  }

  IconData _resolveIcon(CuteCheckboxShape shape, bool isChecked) {
    return switch (shape) {
      CuteCheckboxShape.heart =>
        isChecked ? AppIcons.favoriteActive : AppIcons.favorite,
      CuteCheckboxShape.paw => isChecked ? Icons.pets : AppIcons.catPets,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = resolveShape();
    final iconData = _resolveIcon(shape, widget.value);

    final effectiveActiveColor =
        widget.activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor =
        widget.inactiveColor ?? theme.colorScheme.outline;

    final boxSize = widget.size.clamp(20.0, 32.0);
    final iconSize = (boxSize * 0.70).clamp(12.0, 22.0);

    final boxDecoration = BoxDecoration(
      color: widget.value
          ? effectiveActiveColor
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(Radius.sm),
      border: Border.all(
        color: widget.value ? effectiveActiveColor : effectiveInactiveColor,
        width: 1.8,
      ),
      boxShadow: widget.value
          ? [
              BoxShadow(
                color: effectiveActiveColor.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );

    Widget boxWidget = Container(
      width: boxSize,
      height: boxSize,
      decoration: boxDecoration,
      alignment: Alignment.center,
      child: Icon(
        iconData,
        key: ValueKey('cute_checkbox_icon_${shape.name}_${widget.value}'),
        size: iconSize,
        color: widget.value
            ? theme.colorScheme.onPrimary
            : effectiveInactiveColor.withValues(alpha: 0.7),
      ),
    );

    if (shouldAnimate) {
      boxWidget = ScaleTransition(scale: _scaleAnimation, child: boxWidget);
    }

    final interactiveWidget = SizedBox(
      width: Spacing.touchTarget,
      height: Spacing.touchTarget,
      child: InkResponse(
        onTap: widget.onChanged != null
            ? () => widget.onChanged!(!widget.value)
            : null,
        radius: Spacing.touchTarget / 2,
        splashFactory: InkRipple.splashFactory,
        child: Center(child: boxWidget),
      ),
    );

    if (widget.excludeSemantics) {
      return ExcludeSemantics(child: interactiveWidget);
    }

    final defaultLabel = widget.value
        ? 'Desmarcar (${shape == CuteCheckboxShape.paw ? "pata" : "coração"})'
        : 'Marcar (${shape == CuteCheckboxShape.paw ? "pata" : "coração"})';

    return Semantics(
      label: widget.semanticLabel ?? defaultLabel,
      checked: widget.value,
      enabled: widget.onChanged != null,
      child: interactiveWidget,
    );
  }
}
