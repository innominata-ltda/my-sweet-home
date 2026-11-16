import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';

/// Warning dialog displayed to user before processing low-quality image (RN-204).
///
/// Presents diagnosis of problems (focus, lighting, framing)
/// and offers option to take new photo or proceed anyway.
class QualityWarningDialog extends StatelessWidget {
  final QualityReport report;
  final VoidCallback onRetake;
  final VoidCallback onContinue;

  const QualityWarningDialog({
    super.key,
    required this.report,
    required this.onRetake,
    required this.onContinue,
  });

  /// Displays [QualityWarningDialog] as dialog modal in current context.
  static Future<void> show({
    required BuildContext context,
    required QualityReport report,
    required VoidCallback onRetake,
    required VoidCallback onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QualityWarningDialog(
        report: report,
        onRetake: () {
          Navigator.of(ctx).pop();
          onRetake();
        },
        onContinue: () {
          Navigator.of(ctx).pop();
          onContinue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(AppIcons.qualityWarning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Foto com baixa qualidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identificamos problemas na foto que podem dificultar a leitura dos dados da nota fiscal:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...report.issues.map((i) => _buildIssueTile(context, i)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: Text(
            (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                    lookupAppLocalizations(const Locale('pt')))
                .ocrQualityContinueAnyway,
          ),
        ),
        ElevatedButton.icon(
          onPressed: onRetake,
          icon: const Icon(AppIcons.camera),
          label: Text(
            (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                    lookupAppLocalizations(const Locale('pt')))
                .ocrRetakePhotoButton,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueTile(BuildContext context, QualityIssue issue) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final (icon, text) = switch (issue) {
      QualityIssue.blur => (AppIcons.qualityBlur, l10n.ocrQualityBlur),
      QualityIssue.tooDark => (AppIcons.qualityDark, l10n.ocrQualityTooDark),
      QualityIssue.tooBright => (
        AppIcons.qualityBright,
        l10n.ocrQualityTooBright,
      ),
      QualityIssue.badFraming => (
        AppIcons.qualityFraming,
        l10n.ocrQualityBadFraming,
      ),
      QualityIssue.invalidImage => (
        AppIcons.qualityInvalid,
        l10n.ocrQualityInvalidImage,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
