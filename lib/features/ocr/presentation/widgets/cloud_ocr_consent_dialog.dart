import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
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
          (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                  lookupAppLocalizations(const Locale('pt')))
              .ocrCloudConsentBody,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
      actions: [
        AppButton.text(
          label:
              (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                      lookupAppLocalizations(const Locale('pt')))
                  .ocrRetakePhotoButton,
          onPressed: onRetake,
        ),
        AppButton.secondary(
          label:
              (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                      lookupAppLocalizations(const Locale('pt')))
                  .ocrContinueWithoutCloud,
          onPressed: onContinueLocal,
        ),
        AppButton.primary(
          label:
              (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                      lookupAppLocalizations(const Locale('pt')))
                  .ocrUseCloudOcr,
          icon: const Icon(AppIcons.check, size: 18),
          onPressed: onConfirmCloud,
        ),
      ],
    );
  }

  Widget _buildSuggestNewPhotoDialog(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(AppIcons.warning, color: theme.colorScheme.error),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              l10n.ocrLowPrecisionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          l10n.ocrLowPrecisionBody,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
      actions: [
        AppButton.secondary(
          label: l10n.ocrContinueWithData,
          onPressed: onContinueLocal,
        ),
        AppButton.primary(
          label: l10n.ocrRetakePhotoButton,
          icon: const Icon(AppIcons.camera, size: 18),
          onPressed: onRetake,
        ),
      ],
    );
  }
}
