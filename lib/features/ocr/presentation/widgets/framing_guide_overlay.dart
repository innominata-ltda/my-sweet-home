import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

/// Guia visual de enquadramento para captura de notas fiscais (RF-040, A11Y-10).
///
/// Draws semi-transparent mask over camera viewfinder with an area
/// retangular central destacada para alinhar o cupom fiscal na vertical.
class FramingGuideOverlay extends StatelessWidget {
  final String instructionText;

  const FramingGuideOverlay({
    super.key,
    this.instructionText = 'Posicione a nota fiscal na vertical dentro do guia',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Guia de enquadramento de nota fiscal. $instructionText',
      container: true,
      excludeSemantics: true,
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _FramingPainter()),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.framingGuide,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          instructionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FramingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Framing rectangle dimensions (ideal for long receipts)
    final width = size.width * 0.82;
    final height = size.height * 0.68;
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    final rect = Rect.fromLTWH(left, top, width, height);

    // Desenha fundo escuro com recorte transparente no meio
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, backgroundPaint);

    // Smooth continuous border around cutout
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );

    // Cantoneiras destacadas
    final cornerPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 12.0;

    // Canto superior esquerdo
    final topLeftPath = Path()
      ..moveTo(rect.left, rect.top + cornerLength)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + cornerLength, rect.top);
    canvas.drawPath(topLeftPath, cornerPaint);

    // Canto superior direito
    final topRightPath = Path()
      ..moveTo(rect.right - cornerLength, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.top + cornerLength);
    canvas.drawPath(topRightPath, cornerPaint);

    // Canto inferior esquerdo
    final bottomLeftPath = Path()
      ..moveTo(rect.left, rect.bottom - cornerLength)
      ..lineTo(rect.left, rect.bottom - radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.bottom),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + cornerLength, rect.bottom);
    canvas.drawPath(bottomLeftPath, cornerPaint);

    // Canto inferior direito
    final bottomRightPath = Path()
      ..moveTo(rect.right - cornerLength, rect.bottom)
      ..lineTo(rect.right - radius, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.bottom - cornerLength);
    canvas.drawPath(bottomRightPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
