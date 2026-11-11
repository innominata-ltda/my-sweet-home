/// Tipos de problemas de qualidade detectados na imagem do cupom/nota fiscal (RN-204).
enum QualityIssue {
  /// Imagem desfocada ou borrada (foco ruim).
  blur,

  /// Insufficient lighting (too dark).
  tooDark,

  /// Excessive lighting (blown out/glare).
  tooBright,

  /// Poor framing (too small dimensions or atypical aspect ratio).
  badFraming,

  /// Invalid or corrupted image.
  invalidImage,
}

/// Image quality assessment report for OCR (RN-204).
final class QualityReport {
  /// Indicates whether image has acceptable quality for OCR processing.
  final bool isAcceptable;

  /// Lista de problemas detectados na imagem.
  final List<QualityIssue> issues;

  /// Sharpness/focus score (gradient variance).
  final double sharpnessScore;

  /// Lighting score (normalized average brightness between 0.0 and 1.0).
  final double brightnessScore;

  /// Framing score (0.0 to 1.0).
  final double framingScore;

  const QualityReport({
    required this.isAcceptable,
    required this.issues,
    this.sharpnessScore = 1.0,
    this.brightnessScore = 0.5,
    this.framingScore = 1.0,
  });

  /// Retorna verdadeiro se houver qualquer problema de qualidade apontado.
  bool get hasIssues => issues.isNotEmpty;

  /// Retorna verdadeiro se a imagem for considerada boa.
  bool get isGood => isAcceptable && issues.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityReport &&
          runtimeType == other.runtimeType &&
          isAcceptable == other.isAcceptable &&
          _listEquals(issues, other.issues) &&
          sharpnessScore == other.sharpnessScore &&
          brightnessScore == other.brightnessScore &&
          framingScore == other.framingScore;

  @override
  int get hashCode => Object.hash(
    isAcceptable,
    Object.hashAll(issues),
    sharpnessScore,
    brightnessScore,
    framingScore,
  );

  @override
  String toString() =>
      'QualityReport(isAcceptable: $isAcceptable, issues: $issues, sharpness: ${sharpnessScore.toStringAsFixed(2)}, brightness: ${brightnessScore.toStringAsFixed(2)})';
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
