import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

/// Tela de abertura (Splash Screen) acolhedora com a mascote Momo
/// (SPEC-012, RF-111, CA-111.1, CA-111.2, CA-111.3, RN-270..272).
///
/// Displays Momo with caring expression (`happy` or `waving`), legible "My Sweet Home",
/// background in active palette color and subtle 2-3 frame animation cycle
/// (blink/ear twitch) with fallback when splash Lottie asset is absent.
/// Respects reduced motion preferences (A11Y) and transitions immediately
/// and smoothly after bootstrap completion, without artificial delay (RN-272, RNF-001).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.onInitialize,
    this.onError,
    this.onTransition,
    this.destination = '/',
    this.autoTransition = false,
    this.repeatAnimation = false,
    this.disableAnimations,
    this.resolver,
    this.config,
    this.semanticLabel,
  });

  /// If true, repeats frame animation in continuous loop (default: `false`).
  final bool repeatAnimation;

  /// Optional async bootstrap/initialization routine to await (CA-111.2).
  final Future<void> Function()? onInitialize;

  /// Optional error callback if [onInitialize] throws an exception.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Transition callback triggered after bootstrap completion (CA-111.2).
  /// Se omitido e [autoTransition] for `true`, navega via `context.go(destination)`.
  final void Function(BuildContext context, String destination)? onTransition;

  /// Destination route after splash (default: `'/'` — Dashboard/Home).
  final String destination;

  /// If true, automatically transitions as soon as bootstrap finishes.
  final bool autoTransition;

  /// Strict manual disabling of animations for accessibility or tests (CA-111.3, RN-290).
  /// Se nulo, respeita [MediaQuery.disableAnimationsOf(context)].
  final bool? disableAnimations;

  /// Custom asset resolver for test injection (CA-110.5).
  final MascotAssetResolver? resolver;

  /// Optional mascot configuration (overrides repository persisted one).
  final MascotConfig? config;

  /// Custom semantic label for TalkBack accessibility (RN-289, A11Y-3).
  final String? semanticLabel;

  @override
  ConsumerState<SplashScreen> createState() => SplashScreenState();
}

/// [SplashScreen] state exposing getters and lifecycle for test verification (CA-111.1..111.3).
class SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _frameController;
  int _currentFrame = 0;
  bool _isInitialized = false;
  Object? _error;

  /// Mascot frame animation controller.
  AnimationController get animationController => _frameController;

  /// Indicates if Momo frame animation is running.
  bool get isAnimating => _frameController.isAnimating;

  /// Current frame index (0, 1 or 2) in subtle animation (RN-271).
  int get currentFrame => _currentFrame;

  /// Indicates whether bootstrap routine has completed.
  bool get isInitialized => _isInitialized;

  /// Any error occurred during bootstrap/initialization.
  Object? get error => _error;

  /// Current Momo expression in splash frame cycle (CA-111.1).
  MascotExpression get currentExpression {
    if (_error != null) {
      return MascotExpression.worried;
    }
    if (!shouldAnimate) {
      return MascotExpression.happy;
    }
    switch (_currentFrame) {
      case 0:
        return MascotExpression.waving;
      case 1:
        return MascotExpression.happy;
      case 2:
      default:
        return MascotExpression.waving;
    }
  }

  /// Subtle tilt angle of head/ear in radians for frame animation (RN-271).
  double get currentTilt {
    if (!shouldAnimate || _error != null) return 0.0;
    switch (_currentFrame) {
      case 0:
        return 0.0;
      case 1:
        return -0.035;
      case 2:
      default:
        return 0.035;
    }
  }

  /// Evaluates whether animations should run per config and A11Y (CA-111.3, RN-290, RN-388).
  bool get shouldAnimate {
    final visualEffects = ref.read(visualEffectsEnabledProvider);
    if (!visualEffects) return false;
    final disableSystem =
        widget.disableAnimations ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return !disableSystem;
  }

  @override
  void initState() {
    super.initState();
    _frameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _frameController.addListener(_onFrameTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartAnimation();
      _initializeAndTransition();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndStartAnimation();
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disableAnimations != widget.disableAnimations) {
      _checkAndStartAnimation();
    }
  }

  void _onFrameTick() {
    if (!mounted) return;
    final value = _frameController.value;
    final frame = (value * 3).floor().clamp(0, 2);
    if (frame != _currentFrame) {
      setState(() {
        _currentFrame = frame;
      });
    }
  }

  void _checkAndStartAnimation() {
    if (shouldAnimate) {
      if (!_frameController.isAnimating && !_frameController.isCompleted) {
        if (widget.repeatAnimation) {
          _frameController.repeat();
        } else {
          _frameController.forward();
        }
      }
    } else {
      if (_frameController.isAnimating) {
        _frameController.stop();
      }
      if (_frameController.value != 0.0) {
        _frameController.value = 0.0;
      }
    }
  }

  Future<void> _initializeAndTransition() async {
    try {
      if (widget.onInitialize != null) {
        await widget.onInitialize!();
      }
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });

      if (widget.autoTransition || widget.onInitialize != null) {
        _performTransition();
      }
    } catch (err, stack) {
      if (!mounted) return;
      setState(() {
        _error = err;
      });
      widget.onError?.call(err, stack);
    }
  }

  void _performTransition() {
    if (!mounted) return;
    if (widget.onTransition != null) {
      widget.onTransition!(context, widget.destination);
      return;
    }
    try {
      context.go(widget.destination);
    } catch (_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _frameController.removeListener(_onFrameTick);
    _frameController.dispose();
    super.dispose();
  }

  MascotAssetResolver? _resolveResolver() {
    if (widget.resolver != null) return widget.resolver;
    try {
      return ref.watch(mascotAssetResolverProvider);
    } catch (_) {
      return null;
    }
  }

  MascotConfig _resolveConfig() {
    if (widget.config != null) return widget.config!;
    try {
      return ref
          .watch(mascotConfigStreamProvider)
          .maybeWhen(data: (c) => c, orElse: () => MascotConfig.defaultMomo);
    } catch (_) {
      return MascotConfig.defaultMomo;
    }
  }

  String _resolveSemanticLabel(MascotConfig config) {
    if (widget.semanticLabel != null &&
        widget.semanticLabel!.trim().isNotEmpty) {
      return widget.semanticLabel!.trim();
    }
    final name = config.displayName.isNotEmpty ? config.displayName : 'Momo';
    return '$name, mascote acolhedora do My Sweet Home';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(visualEffectsEnabledProvider);
    _checkAndStartAnimation();
    final theme = Theme.of(context);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final appName = l10n?.appName ?? 'My Sweet Home';
    final resolver = _resolveResolver();
    final config = _resolveConfig();
    final semanticLabel = _resolveSemanticLabel(config);
    final hasLottie =
        resolver != null &&
        resolver.hasAnimationAsset('splash') &&
        shouldAnimate &&
        _error == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Text identifier in tree for route test backward compatibility
            // Isolates from semantic tree to avoid cluttering screen readers like TalkBack (A11Y)
            const ExcludeSemantics(
              child: SizedBox(
                width: 0,
                height: 0,
                child: Text('Splash', style: TextStyle(fontSize: 0)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    hasLottie
                        ? Semantics(
                            container: true,
                            label: semanticLabel,
                            child: Lottie.asset(
                              resolver.resolveAnimationPath('splash'),
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              repeat: widget.repeatAnimation,
                              animate: shouldAnimate,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFrameFallback(
                                    resolver: resolver,
                                    config: config,
                                    semanticLabel: semanticLabel,
                                  ),
                            ),
                          )
                        : _buildFrameFallback(
                            resolver: resolver,
                            config: config,
                            semanticLabel: semanticLabel,
                          ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Ops! Ocorreu uma instabilidade na inicialização.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextButton(
                        onPressed: _initializeAndTransition,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameFallback({
    MascotAssetResolver? resolver,
    MascotConfig? config,
    required String semanticLabel,
  }) {
    return Transform.rotate(
      angle: currentTilt,
      child: MascotWidget(
        config: config ?? widget.config,
        expression: currentExpression,
        semanticLabel: semanticLabel,
        size: 180,
        disableAnimations: !shouldAnimate,
        resolver: resolver ?? widget.resolver,
      ),
    );
  }
}
