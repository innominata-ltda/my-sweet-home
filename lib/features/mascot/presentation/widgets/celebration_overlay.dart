import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

/// Celebration overlay with Momo and confetti upon completing tasks or purchases
/// (SPEC-012, RF-112, CA-112.1, CA-112.2, CA-112.3, RN-279, RN-288, RN-290).
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    this.title = 'Parabéns!',
    this.message = 'Você concluiu tudo com sucesso! 💕',
    this.duration = const Duration(milliseconds: 2800),
    this.onDismiss,
    this.disableAnimations,
    this.config,
    this.lottieAsset,
  });

  /// Celebration message title.
  final String title;

  /// Caring celebration message.
  final String message;

  /// Maximum duration before auto-dismiss (<= 3 seconds per CA-112.1).
  final Duration duration;

  /// Callback invoked when celebration dismisses (by timeout or tap).
  final VoidCallback? onDismiss;

  /// Explicit animation control (if null, queries [MediaQuery.disableAnimationsOf(context)]).
  final bool? disableAnimations;

  /// Optional mascot Momo configuration.
  final MascotConfig? config;

  /// Caminho opcional do arquivo Lottie de confetes (RN-288).
  final String? lottieAsset;

  static OverlayEntry? _activeEntry;

  /// Displays celebration overlay by inserting an [OverlayEntry] into given context.
  /// If an active overlay is already showing, discards previous to avoid overlap.
  static OverlayEntry show(
    BuildContext context, {
    String title = 'Parabéns!',
    String message = 'Você concluiu tudo com sucesso! 💕',
    Duration duration = const Duration(milliseconds: 2800),
    VoidCallback? onDismiss,
    bool? disableAnimations,
    MascotConfig? config,
    String? lottieAsset,
  }) {
    if (_activeEntry != null && _activeEntry!.mounted) {
      _activeEntry!.remove();
      _activeEntry = null;
    }

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);
    late OverlayEntry entry;
    var isDismissed = false;

    void dismiss() {
      if (isDismissed) return;
      isDismissed = true;
      if (_activeEntry == entry) {
        _activeEntry = null;
      }
      if (entry.mounted) {
        entry.remove();
      }
      onDismiss?.call();
    }

    entry = OverlayEntry(
      builder: (ctx) => CelebrationOverlay(
        title: title,
        message: message,
        duration: duration,
        onDismiss: dismiss,
        disableAnimations: disableAnimations,
        config: config,
        lottieAsset: lottieAsset,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    return entry;
  }

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  Timer? _dismissTimer;
  bool _dismissed = false;

  /// Animation controller for confetti.
  AnimationController get animationController => _confettiController;

  /// Evaluates whether animations should run per accessibility (CA-112.3, RN-290, RN-388).
  bool get shouldAnimate {
    bool visualEffects = true;
    try {
      visualEffects = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(visualEffectsEnabledProvider);
    } catch (_) {}
    if (!visualEffects) return false;
    final disableSystem =
        widget.disableAnimations ??
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return !disableSystem;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.duration > Duration.zero) {
      _dismissTimer = Timer(widget.duration, dismiss);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (shouldAnimate) {
      if (!_confettiController.isAnimating) {
        _confettiController.repeat();
      }
    } else {
      if (_confettiController.isAnimating) {
        _confettiController.stop();
        _confettiController.value = 0.0;
      }
    }
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disableAnimations != widget.disableAnimations) {
      if (!shouldAnimate) {
        _confettiController.stop();
        _confettiController.value = 0.0;
      } else if (!_confettiController.isAnimating) {
        _confettiController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  /// Dismisses celebration manually or on timeout.
  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissTimer?.cancel();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldAnimate) {
      if (_confettiController.isAnimating) {
        _confettiController.stop();
        _confettiController.value = 0.0;
      }
    } else if (!_confettiController.isAnimating) {
      _confettiController.repeat();
    }
    final theme = Theme.of(context);
    final animate = shouldAnimate;

    final contentCard = Semantics(
      container: true,
      liveRegion: true,
      label: '${widget.title}. ${widget.message}',
      child: AppCard(
        key: const Key('celebration_overlay_card'),
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MascotWidget(
                  config: widget.config,
                  expression: MascotExpression.happy,
                  size: 96,
                  disableAnimations: !animate,
                  semanticLabel: 'Momo alegre celebrando sua conquista',
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        key: const Key('celebration_overlay_barrier'),
        behavior: HitTestBehavior.opaque,
        onTap: dismiss,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fundo semitransparente escurecido
            Container(color: Colors.black.withValues(alpha: 0.35)),

            // Decorative animated confetti (only if animations active per CA-112.3)
            if (animate) ...[
              if (widget.lottieAsset != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Lottie.asset(
                      widget.lottieAsset!,
                      repeat: true,
                      errorBuilder: (ctx, err, stack) => AnimatedBuilder(
                        animation: _confettiController,
                        builder: (ctx, _) => CustomPaint(
                          painter: _ConfettiPainter(
                            progress: _confettiController.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (ctx, _) => CustomPaint(
                        key: const Key('celebration_confetti_painter'),
                        painter: _ConfettiPainter(
                          progress: _confettiController.value,
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Central celebration card
            Center(child: contentCard),
          ],
        ),
      ),
    );
  }
}

/// Deterministic custom confetti painter for fallback when Lottie unavailable
/// (RN-288, CA-112.1, Artigo III — sem uso de Random()).
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _palette = [
    Color(0xFFE8A0BF), // Rose
    Color(0xFF7EC8A3), // Mint
    Color(0xFFB8A9E8), // Lavender
    Color(0xFFFFD166), // Gold
    Color(0xFF64B5F6), // Blue
    Color(0xFFFF8A80), // Coral
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    const count = 48;

    for (var i = 0; i < count; i++) {
      paint.color = _palette[(i * 7) % _palette.length];

      // X position uniformly distributed
      final xFraction = ((i * 0.173 + 0.04) % 1.0);
      final x = xFraction * size.width;

      // Velocidade e deslocamento de queda vertical
      final speedFactor = 0.6 + ((i * 13) % 10) * 0.08;
      final yOffset = ((progress * speedFactor + (i * 0.061)) % 1.0);
      final y = yOffset * (size.height + 40) - 20;

      // Sinusoidal horizontal oscillation
      final sway = math.sin((progress * 2 * math.pi) + i) * 16.0;

      // Individual rotation
      final rotation = (progress * 4 * math.pi) + (i * 0.5);

      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(rotation);

      if (i % 3 == 0) {
        // Circle
        canvas.drawCircle(Offset.zero, 4.0, paint);
      } else if (i % 3 == 1) {
        // Rectangle / ribbon
        canvas.drawRect(const Rect.fromLTWH(-5.0, -3.0, 10.0, 6.0), paint);
      } else {
        // Losango / fita fina
        final path = Path()
          ..moveTo(0, -6)
          ..lineTo(4, 0)
          ..lineTo(0, 6)
          ..lineTo(-4, 0)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
