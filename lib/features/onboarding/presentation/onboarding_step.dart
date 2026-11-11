import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

/// Entrance animation widget with scale + fade for mascot (RN-278).
///
/// Respects reduced motion preference [MediaQuery.disableAnimations]
/// and displays static mascot when active (RN-290, CA-290.1, A11Y-7).
class MascotEntrance extends StatefulWidget {
  const MascotEntrance({
    required this.child,
    this.disableAnimations,
    super.key,
  });

  /// Widget filho a ser animado.
  final Widget child;

  /// Optional manual control to disable animations.
  final bool? disableAnimations;

  @override
  State<MascotEntrance> createState() => MascotEntranceState();
}

class MascotEntranceState extends State<MascotEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  /// Animation controller exposed for inspection and testing.
  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaDisabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final disabled = widget.disableAnimations ?? mediaDisabled;
    if (disabled) {
      _controller.value = 1.0;
    } else if (!_controller.isCompleted && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaDisabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final disabled = widget.disableAnimations ?? mediaDisabled;

    if (disabled) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Um passo individual do fluxo de onboarding interativo (RF-009, RN-273).
///
/// Displays mascot Momo with contextual expression (or legacy fallback icon),
/// caring title and explanatory subtitle centered with safe scrolling.
/// Contains no data input fields (RN-012, RN-275).
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    required this.title,
    required this.subtitle,
    this.icon,
    this.expression,
    this.mascotWidget,
    this.extraContent,
    this.disableAnimations,
    this.animateIdle = false,
    super.key,
  });

  /// Illustrative icon (legacy or fallback).
  final IconData? icon;

  /// Contextual expression of Momo for this step (RN-260, RN-273).
  final MascotExpression? expression;

  /// Widget customizado para a mascote (se fornecido).
  final Widget? mascotWidget;

  /// Optional extra content positioned after subtitle.
  final Widget? extraContent;

  /// Optional manual control to disable animations (CA-290.1).
  final bool? disableAnimations;

  /// If true, enables continuous idle animation (RN-282).
  final bool animateIdle;

  /// Step title in Momo's 1st person (RN-273).
  final String title;

  /// Explanatory description of step.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final mascotSize = textScale >= 1.5 ? 90.0 : 140.0;
    final topSpacing = textScale >= 1.5 ? Spacing.sm : Spacing.xl;
    final titleSpacing = textScale >= 1.5 ? Spacing.xs : Spacing.md;

    Widget headerVisual;
    if (mascotWidget != null) {
      headerVisual = mascotWidget!;
    } else if (expression != null) {
      headerVisual = MascotEntrance(
        disableAnimations: disableAnimations,
        child: MascotWidget(
          expression: expression!,
          size: mascotSize,
          animateIdle: animateIdle,
          disableAnimations: disableAnimations,
        ),
      );
    } else if (icon != null) {
      headerVisual = Icon(
        icon,
        size: textScale >= 1.5 ? Spacing.xxl : Spacing.xxl + Spacing.lg,
        color: theme.colorScheme.primary,
      );
    } else {
      headerVisual = const SizedBox.shrink();
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: Spacing.xl,
          right: Spacing.xl,
          top: topSpacing,
          bottom: textScale >= 1.5 ? Spacing.xl : Spacing.md,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            headerVisual,
            SizedBox(height: topSpacing),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: titleSpacing),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (extraContent != null) ...[
              SizedBox(height: topSpacing),
              extraContent!,
            ],
          ],
        ),
      ),
    );
  }
}
