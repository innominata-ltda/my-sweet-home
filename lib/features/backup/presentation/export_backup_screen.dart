// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/backup/data/backup_service_provider.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';
import 'package:my_sweet_home/features/backup/presentation/encrypted_backup_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareBackupFile = Future<void> Function(String content, String name);

class ExportBackupScreen extends ConsumerWidget {
  const ExportBackupScreen({super.key, this.backupService, this.shareBackup});

  final BackupService? backupService;
  final ShareBackupFile? shareBackup;

  Future<void> _defaultShareBackup(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Backup criptografado My Sweet Home',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar Dados')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.lockBackup, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Exportar Dados Criptografados',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gere um arquivo de backup seguro de todos os seus dados e fotos para salvar localmente ou compartilhar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('export_backup_button'),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final BackupService service =
                      backupService ?? ref.read(backupServiceProvider);
                  final share = shareBackup ?? _defaultShareBackup;

                  showDialog<void>(
                    context: context,
                    builder: (ctx) => EncryptedBackupExportDialog(
                      onExportRequested:
                          (password, {includePhotos = false}) async {
                            final result = await service.exportEncryptedBackup(
                              password,
                              includePhotos: includePhotos,
                            );
                            switch (result) {
                              case Err(:final failure):
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao gerar backup: $failure',
                                    ),
                                  ),
                                );
                              case Ok(:final value):
                                await share(
                                  value,
                                  'my_sweet_home_backup.mshbackup',
                                );
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Backup gerado e exportado com sucesso!',
                                    ),
                                  ),
                                );
                            }
                          },
                    ),
                  );
                },
                icon: const Icon(AppIcons.fileExport),
                label: const Text('Criar e Exportar Backup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
