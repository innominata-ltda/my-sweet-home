import 'package:my_sweet_home/core/settings/settings_repository.dart';

/// Recommended action regarding consent and cloud OCR processing.
enum CloudOcrConsentAction {
  /// Sufficient confidence in local OCR: proceed normally without cloud.
  proceedLocal,

  /// Low confidence with prior consent granted in settings:
  /// MUST request explicit confirmation **in that operation** (RN-190, CA-1.2).
  requestOperationConfirmation,

  /// Low confidence WITHOUT prior consent granted in settings:
  /// MUST suggest new photo and MUST NOT offer to enable or use cloud OCR (RN-207, CA-1.3).
  suggestNewPhoto,
}

/// Avaliador de regras de consentimento para OCR na nuvem (RN-190, RN-207, CA-1.2, CA-1.3).
///
/// Responsible for deciding appropriate action combining mean reading confidence
/// com o estado de consentimento armazenado no [SettingsRepository].
class CloudOcrConsentEvaluator {
  /// Default confidence threshold (0.6 / 60%) per RN-195 and CA-1.3.
  static const double defaultConfidenceThreshold = 0.6;

  final SettingsRepository settingsRepository;
  final double confidenceThreshold;

  const CloudOcrConsentEvaluator({
    required this.settingsRepository,
    this.confidenceThreshold = defaultConfidenceThreshold,
  });

  /// Evaluates recommended action for document read based on mean confidence
  /// and user prior permission registered in [SettingsRepository].
  Future<CloudOcrConsentAction> evaluate({
    required double averageConfidence,
  }) async {
    if (averageConfidence >= confidenceThreshold) {
      return CloudOcrConsentAction.proceedLocal;
    }

    final isCloudAllowed = await settingsRepository.isCloudOcrAllowed();
    if (isCloudAllowed) {
      return CloudOcrConsentAction.requestOperationConfirmation;
    } else {
      return CloudOcrConsentAction.suggestNewPhoto;
    }
  }
}
