import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Dialog for manual generation and sharing of update bundle (.mshsync) (RF-123, RN-331).
class BundleShareDialog extends StatefulWidget {
  final Future<Uint8List?> Function() onGenerateBundle;
  final Future<bool> Function(Uint8List bytes)? onApplyBundle;

  const BundleShareDialog({
    super.key,
    required this.onGenerateBundle,
    this.onApplyBundle,
  });

  @override
  State<BundleShareDialog> createState() => _BundleShareDialogState();
}

class _BundleShareDialogState extends State<BundleShareDialog> {
  bool _isGenerating = false;
  Uint8List? _generatedBytes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pacote de sincronização'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gere um arquivo criptografado com as alterações deste aparelho para enviar por '
            'WhatsApp ou outro aplicativo para pessoas da sua casa.',
          ),
          const SizedBox(height: Spacing.md),
          if (_generatedBytes != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(Radius.card),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.check, size: 24),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Pacote gerado com sucesso! (${_generatedBytes!.lengthInBytes} bytes)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        AppButton.primary(
          key: const Key('action_generate_bundle_button'),
          label: _generatedBytes == null ? 'Gerar pacote' : 'Compartilhar',
          icon: const Icon(AppIcons.fileExport),
          isLoading: _isGenerating,
          onPressed: () async {
            setState(() => _isGenerating = true);
            try {
              final bytes = await widget.onGenerateBundle();
              if (mounted) {
                setState(() {
                  _generatedBytes = bytes;
                  _isGenerating = false;
                });
              }
            } catch (_) {
              if (mounted) setState(() => _isGenerating = false);
            }
          },
        ),
      ],
    );
  }
}
