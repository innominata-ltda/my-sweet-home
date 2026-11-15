import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Dialog with camera QR code reader using `MobileScanner` (RF-120, RN-391, CA-4.1).
class QrScannerDialog extends StatefulWidget {
  final ValueChanged<String>? onScanned;

  const QrScannerDialog({super.key, this.onScanned});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _hasScanned = true;
        widget.onScanned?.call(raw);
        if (mounted) {
          Navigator.of(context).pop(raw);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      key: const Key('qr_scanner_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.qrScanner),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).householdQrScanTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close_qr_scanner_button'),
                    icon: const Icon(AppIcons.close),
                    tooltip: AppLocalizations.of(context)
                        .householdQrCloseTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                AppLocalizations.of(context).householdQrScanPrompt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  key: const Key('qr_scanner_viewport'),
                  width: 260,
                  height: 260,
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcode,
                    errorBuilder: (context, error) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.all(Spacing.md),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.camera,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              AppLocalizations.of(context)
                                  .householdQrCameraUnavailable,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              AppButton.secondary(
                key: const Key('cancel_qr_scanner_button'),
                label: AppLocalizations.of(context).householdQrManualEntry,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
