import 'package:flutter/material.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';
import 'package:my_sweet_home/core/update/app_update_service.dart';

/// Displays non-blocking update confirmation dialog (RN-042, CA-12.1, CA-12.2).
Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppUpdateInfo updateInfo,
  required AppUpdateService service,
}) async {
  final versionText =
      updateInfo.availableVersionLabel != null &&
          updateInfo.availableVersionLabel!.isNotEmpty
      ? ' (${updateInfo.availableVersionLabel})'
      : '';

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Atualização disponível'),
        content: Text(
          'Uma nova versão$versionText do My Sweet Home está disponível na loja. Gostaria de atualizar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await service.recordDismissedFor24Hours();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () async {
              await service.startUpdate();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Atualizar agora'),
          ),
        ],
      );
    },
  );
}
