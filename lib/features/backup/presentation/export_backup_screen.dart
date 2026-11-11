import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/backup/presentation/encrypted_backup_dialog.dart';

class ExportBackupScreen extends StatelessWidget {
  const ExportBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => EncryptedBackupExportDialog(
                      onExportRequested:
                          (password, {includePhotos = false}) async {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Backup gerado e exportado com sucesso!',
                                ),
                              ),
                            );
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
