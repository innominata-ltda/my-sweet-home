import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';

/// Componente visual principal da mascote Momo (SPEC-012, RF-110, CA-110.5, CA-289.1, CA-290.1).
///
/// Displays current animal and emotional expression with smooth idle animation support,
/// graceful placeholder fallback and semantic labels for accessibility (TalkBack).
class MascotWidget extends ConsumerStatefulWidget {
  const MascotWidget({
    super.key,
    this.config,
    this.animal,
    this.palette,
    this.accessory,
    this.name,
    this.expression = MascotExpression.neutral,
    this.width,
    this.height,
    this.size,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.isDecorative = false,
    this.animateIdle = false,
    this.disableAnimations,
    this.resolver,
    this.placeholderBuilder,
    this.onTap,
  });

  /// Convenience constructor with idle animation enabled by default (RN-282).
  const MascotWidget.animated({
    super.key,
    this.config,
    this.animal,
    this.palette,
    this.accessory,
    this.name,
    this.expression = MascotExpression.neutral,
    this.width,
    this.height,
    this.size,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.isDecorative = false,
    this.animateIdle = true,
    this.disableAnimations,
    this.resolver,
    this.placeholderBuilder,
    this.onTap,
  });

  /// Mascot configuration. If omitted, observes [mascotConfigStreamProvider].
  final MascotConfig? config;

  /// Specific animal for display (overrides [config]).
  final MascotAnimal? animal;

  /// Specific palette for display (overrides [config]).
  final MascotPalette? palette;

  /// Specific accessory for display (overrides [config]).
  final MascotAccessory? accessory;

  /// Nome personalizado da mascote (sobrescreve [config]).
  final String? name;

  /// Mascot emotional expression (default: [MascotExpression.neutral]).
  final MascotExpression expression;

  /// Largura do componente.
  final double? width;

  /// Altura do componente.
  final double? height;

  /// Define simultaneamente [width] e [height] como um quadrado.
  final double? size;

  /// Ajuste da imagem ou placeholder dentro do container.
  final BoxFit fit;

  /// Custom semantic label for screen readers such as TalkBack (CA-289.1, RN-289).
  /// Se nulo, utiliza [MascotExpression.defaultSemanticDescription].
  final String? semanticLabel;

  /// If true, hides mascot from accessibility tree (purely decorative).
  final bool isDecorative;

  /// If true, enables subtle idle animation when animations are enabled (RN-282).
  final bool animateIdle;

  /// Strict manual control to turn off animations (CA-290.1, RN-290).
  /// Se nulo, respeita [MediaQuery.disableAnimationsOf(context)].
  final bool? disableAnimations;

  /// Custom asset resolver for dependency injection / testing.
  final MascotAssetResolver? resolver;

  /// Construtor customizado de placeholder em caso de falha de carregamento do asset (CA-110.5).
  final Widget Function(
    BuildContext context,
    MascotConfig config,
    MascotExpression expression,
  )?
  placeholderBuilder;

  /// Callback opcional de toque na mascote.
  final VoidCallback? onTap;

  @override
  ConsumerState<MascotWidget> createState() => MascotWidgetState();
}

/// [MascotWidget] state exposing getters and animation lifecycle for tests.
class MascotWidgetState extends ConsumerState<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late final Animation<double> _bobAnimation;
  late final Animation<double> _scaleAnimation;

  /// Returns `true` if idle animation is actively running.
  bool get isAnimating => _idleController.isAnimating;

  /// Internal animation controller (for verification in tests).
  AnimationController get animationController => _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _bobAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateIdle != widget.animateIdle ||
        oldWidget.disableAnimations != widget.disableAnimations) {
      _updateAnimationState();
    }
  }

  /// Evaluates whether animation should run per config and accessibility (RN-290, CA-290.1, RN-388).
  bool get shouldAnimate {
    if (!widget.animateIdle) return false;
    bool visualEffects = true;
    try {
      visualEffects = ref.read(visualEffectsEnabledProvider);
    } catch (_) {}
    if (!visualEffects) return false;
    final disableSystem =
        widget.disableAnimations ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return !disableSystem;
  }

  void _updateAnimationState() {
    if (shouldAnimate) {
      if (!_idleController.isAnimating) {
        _idleController.repeat(reverse: true);
      }
    } else {
      if (_idleController.isAnimating) {
        _idleController.stop();
      }
      if (_idleController.value != 0.0) {
        _idleController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  /// Resolves effective mascot configuration.
  MascotConfig resolveConfig() {
    final explicit = widget.config;
    if (explicit != null) {
      return explicit.copyWith(
        animal: widget.animal,
        palette: widget.palette,
        accessory: widget.accessory,
        name: widget.name,
      );
    }
    try {
      final base = ref
          .watch(mascotConfigStreamProvider)
          .maybeWhen(data: (c) => c, orElse: () => MascotConfig.defaultMomo);
      return base.copyWith(
        animal: widget.animal,
        palette: widget.palette,
        accessory: widget.accessory,
        name: widget.name,
      );
    } catch (_) {
      return MascotConfig.defaultMomo.copyWith(
        animal: widget.animal,
        palette: widget.palette,
        accessory: widget.accessory,
        name: widget.name,
      );
    }
  }

  /// Resolve a porta de assets da mascote.
  MascotAssetResolver resolveResolver() {
    if (widget.resolver != null) return widget.resolver!;
    try {
      return ref.watch(mascotAssetResolverProvider);
    } catch (_) {
      return const _DefaultAssetResolver();
    }
  }

  /// Resolves accessible semantic description in pt-BR (RN-289, CA-289.1).
  String resolveSemanticLabel(MascotConfig config) {
    if (widget.semanticLabel != null &&
        widget.semanticLabel!.trim().isNotEmpty) {
      return widget.semanticLabel!.trim();
    }
    return widget.expression.defaultSemanticDescription(config.displayName);
  }

  Widget _buildPlaceholder(
    BuildContext context,
    MascotConfig config,
    double? width,
    double? height,
  ) {
    if (widget.placeholderBuilder != null) {
      return widget.placeholderBuilder!(context, config, widget.expression);
    }
    return MascotPlaceholder(
      config: config,
      expression: widget.expression,
      width: width,
      height: height,
      fit: widget.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      ref.watch(visualEffectsEnabledProvider);
    } catch (_) {}
    _updateAnimationState();
    final config = resolveConfig();
    final resolver = resolveResolver();

    final effectiveWidth = widget.size ?? widget.width;
    final effectiveHeight = widget.size ?? widget.height;

    Widget visual;
    if (!resolver.hasExpressionAsset(config.animal, widget.expression)) {
      visual = _buildPlaceholder(
        context,
        config,
        effectiveWidth,
        effectiveHeight,
      );
    } else {
      final assetPath = resolver.resolveExpressionPath(
        config.animal,
        widget.expression,
      );
      if (assetPath == resolver.fallbackPlaceholderPath) {
        visual = _buildPlaceholder(
          context,
          config,
          effectiveWidth,
          effectiveHeight,
        );
      } else {
        visual = Image.asset(
          assetPath,
          width: effectiveWidth,
          height: effectiveHeight,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(
              context,
              config,
              effectiveWidth,
              effectiveHeight,
            );
          },
        );
      }
    }

    if (widget.onTap != null) {
      visual = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(Radius.card),
          child: visual,
        ),
      );
    }

    final semanticText = resolveSemanticLabel(config);
    final accessibleWidget = widget.isDecorative
        ? (widget.onTap != null
              ? Semantics(button: true, onTap: widget.onTap, child: visual)
              : ExcludeSemantics(child: visual))
        : Semantics(
            label: semanticText,
            image: true,
            button: widget.onTap != null,
            onTap: widget.onTap,
            child: ExcludeSemantics(child: visual),
          );

    if (shouldAnimate) {
      return AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bobAnimation.value),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: accessibleWidget,
      );
    }

    return accessibleWidget;
  }
}

/// Elegant visual fallback with silhouette/icon and palette color when WebP image
/// is missing from bundle (CA-110.5, RN-292, CA-003.4).
class MascotPlaceholder extends StatelessWidget {
  const MascotPlaceholder({
    super.key = const Key('mascot_placeholder'),
    required this.config,
    this.expression = MascotExpression.neutral,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final MascotConfig config;
  final MascotExpression expression;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final appPalette = AppPalette.fromId(config.palette.name);
    final paletteColor = appPalette.seedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? paletteColor.withValues(alpha: 0.22)
        : paletteColor.withValues(alpha: 0.14);
    final borderColor = paletteColor.withValues(alpha: 0.45);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final resolvedHeight =
            height ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        final resolvedDimension = resolvedHeight ?? resolvedWidth ?? 64.0;

        final isTiny = resolvedDimension < 24.0;
        final iconSize = (resolvedDimension * 0.45).clamp(8.0, 56.0);
        final showAccessory =
            config.accessory != MascotAccessory.none &&
            resolvedDimension >= 48.0;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(Radius.card),
            border: Border.all(color: borderColor, width: isTiny ? 1.0 : 1.5),
            boxShadow: isTiny ? null : AppShadows.softGlow(paletteColor),
          ),
          child: Center(
            child: FittedBox(
              fit: fit,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.catPets, size: iconSize, color: paletteColor),
                    if (showAccessory) ...[
                      const SizedBox(height: Spacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xs,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: paletteColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(Radius.chip),
                        ),
                        child: Text(
                          config.accessory.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: paletteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Standalone default asset resolver for fallbacks outside ProviderScope (no data/ dependency).
class _DefaultAssetResolver implements MascotAssetResolver {
  const _DefaultAssetResolver();

  @override
  String get fallbackPlaceholderPath => 'assets/mascots/placeholder.webp';

  @override
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  ) => 'assets/mascots/${animal.name}/${expression.name}.webp';

  @override
  String resolveAnimationPath(String animationName) {
    final sanitized = animationName.trim();
    if (sanitized.isEmpty) return '';
    if (sanitized.startsWith('assets/')) {
      return sanitized.endsWith('.json') ? sanitized : '$sanitized.json';
    }
    final fileName = sanitized.endsWith('.json')
        ? sanitized
        : '$sanitized.json';
    return 'assets/lottie/$fileName';
  }

  @override
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression) =>
      true;

  @override
  bool hasAnimationAsset(String animationName) =>
      animationName.trim().isNotEmpty;
}
