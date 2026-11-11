import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/ocr/domain/cloud_ocr_consent_evaluator.dart';

/// Consent / suggestion dialog for cloud OCR (RF-043, RN-190, RN-207, CA-1.2, CA-1.3).
///
/// Displayed when local OCR reading results in low confidence (mean confidence < 0.6).
///
/// - If prior consent is granted in `SettingsRepository` ([CloudOcrConsentAction.requestOperationConfirmation]):
///   asks **in that operation** whether user wishes to use cloud OCR to improve reading (RN-190, CA-1.2).
///
/// - If prior consent is NOT granted ([CloudOcrConsentAction.suggestNewPhoto]):
///   suggests taking a new photo and **MUST NOT** offer option to enable or use cloud OCR (RN-207, CA-1.3).
class CloudOcrConsentDialog extends StatelessWidget {
  final CloudOcrConsentAction action;
  final VoidCallback onRetake;
  final VoidCallback onContinueLocal;
  final VoidCallback? onConfirmCloud;

  const CloudOcrConsentDialog({
    super.key,
    required this.action,
    required this.onRetake,
    required this.onContinueLocal,
    this.onConfirmCloud,
  });

  /// Displays modal dialog corresponding to [CloudOcrConsentAction].
  static Future<void> show({
    required BuildContext context,
    required CloudOcrConsentAction action,
    required VoidCallback onRetake,
    required VoidCallback onContinueLocal,
    VoidCallback? onConfirmCloud,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CloudOcrConsentDialog(
        action: action,
        onRetake: () {
          Navigator.of(ctx).pop();
          onRetake();
        },
        onContinueLocal: () {
          Navigator.of(ctx).pop();
          onContinueLocal();
        },
        onConfirmCloud: onConfirmCloud != null
            ? () {
                Navigator.of(ctx).pop();
                onConfirmCloud();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (action == CloudOcrConsentAction.requestOperationConfirmation) {
      return _buildOperationConfirmationDialog(context);
    } else {
      return _buildSuggestNewPhotoDialog(context);
    }
  }

  Widget _buildOperationConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(AppIcons.info, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Melhorar leitura na nuvem?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          'A leitura no aparelho teve baixa precisão. Como você permitiu o OCR na nuvem nas configurações, deseja tentar melhorar a leitura enviando esta nota para o serviço em nuvem nesta operação?',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
      actions: [
        AppButton.text(label: 'Tirar outra foto', onPressed: onRetake),
        AppButton.secondary(
          label: 'Continuar sem nuvem',
          onPressed: onContinueLocal,
        ),
        AppButton.primary(
          label: 'Usar OCR na nuvem',
          icon: const Icon(AppIcons.check, size: 18),
          onPressed: onConfirmCloud,
        ),
      ],
    );
  }

  Widget _buildSuggestNewPhotoDialog(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(AppIcons.warning, color: theme.colorScheme.error),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Leitura com baixa precisão',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          'A leitura da nota fiscal no aparelho teve baixa precisão. Recomendamos tirar uma nova foto com melhor iluminação e enquadramento.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
      actions: [
        AppButton.secondary(
          label: 'Continuar com estes dados',
          onPressed: onContinueLocal,
        ),
        AppButton.primary(
          label: 'Tirar outra foto',
          icon: const Icon(AppIcons.camera, size: 18),
          onPressed: onRetake,
        ),
      ],
    );
  }
}
