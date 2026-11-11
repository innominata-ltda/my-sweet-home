import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/result/result.dart';
import '../providers/household_providers.dart';

/// Dialog for manual import of a .mshsync bundle (RF-123, RN-409, CA-2.7).
class BundleImportDialog extends ConsumerStatefulWidget {
  const BundleImportDialog({super.key});

  @override
  ConsumerState<BundleImportDialog> createState() => _BundleImportDialogState();
}

class _BundleImportDialogState extends ConsumerState<BundleImportDialog> {
  final _controller = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final transport = ref.read(bundleSyncTransportProvider);
      final result = await transport.applyBundle(utf8.encode(text));
      ref.invalidate(householdPendingChangesProvider);

      if (mounted) {
        nav.pop();
        if (result case Ok(:final value)) {
          if (value.alreadyApplied) {
            messenger.showSnackBar(
              const SnackBar(
                key: Key('bundle_already_applied_snack'),
                content: Text('Este pacote já foi aplicado'),
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                key: Key('bundle_applied_snack'),
                content: Text('Pacote aplicado com sucesso!'),
              ),
            );
          }
        } else if (result case Err(:final failure)) {
          messenger.showSnackBar(
            SnackBar(
              key: const Key('bundle_error_snack'),
              content: Text(userMessageFor(failure)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        nav.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('import_bundle_dialog'),
      title: const Text('Importar pacote .mshsync'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('bundle_input_field'),
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Conteúdo ou caminho do pacote',
              hintText: 'Cole os dados do arquivo .mshsync',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm_import_button'),
          onPressed: _isImporting ? null : _handleImport,
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Importar'),
        ),
      ],
    );
  }
}
