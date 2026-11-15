import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/models/manual_purchase_args.dart';

/// Warning dialog / screen displayed on total OCR failure (RF-047, RN-203, CA-7.1).
///
/// Presents a friendly explanation without technical jargon and provides
/// button to open manual entry with attached photo.
class OcrTotalFailureDialog extends StatelessWidget {
  final ManualPurchaseArgs args;
  final VoidCallback onManualEntry;
  final VoidCallback? onRetake;

  const OcrTotalFailureDialog({
    super.key,
    required this.args,
    required this.onManualEntry,
    this.onRetake,
  });

  /// Displays [OcrTotalFailureDialog] as modal in current context.
  static Future<void> show({
    required BuildContext context,
    required ManualPurchaseArgs args,
    required VoidCallback onManualEntry,
    VoidCallback? onRetake,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OcrTotalFailureDialog(
        args: args,
        onManualEntry: () {
          Navigator.of(ctx).pop();
          onManualEntry();
        },
        onRetake: onRetake != null
            ? () {
                Navigator.of(ctx).pop();
                onRetake();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(AppIcons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                      lookupAppLocalizations(const Locale('pt')))
                  .ocrTotalFailureTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              args.userFriendlyMessage,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (args.attachedImagePath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(AppIcons.bill, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (Localizations.of<AppLocalizations>(
                                context,
                                AppLocalizations,
                              ) ??
                              lookupAppLocalizations(const Locale('pt')))
                          .ocrAttachedPhoto(args.attachedImagePath!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (onRetake != null)
          TextButton.icon(
            onPressed: onRetake,
            icon: const Icon(AppIcons.camera, size: 18),
            label: Text(
              (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                      lookupAppLocalizations(const Locale('pt')))
                  .ocrRetakePhotoButton,
            ),
          ),
        ElevatedButton.icon(
          onPressed: onManualEntry,
          icon: const Icon(AppIcons.edit, size: 18),
          label: Text(
            (Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                    lookupAppLocalizations(const Locale('pt')))
                .ocrManualEntryTooltip,
          ),
        ),
      ],
    );
  }
}
