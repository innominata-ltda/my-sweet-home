import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

/// Backup and Export menu screen.
class BackupMenuPage extends StatelessWidget {
  const BackupMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e Exportação')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(AppIcons.export),
            title: const Text('Exportar Backup'),
            subtitle: const Text(
              'Gere um arquivo criptografado com seus dados',
            ),
            onTap: () => context.push('/settings/backup/exportar'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.backup),
            title: const Text('Importar Backup'),
            subtitle: const Text(
              'Restaurar ou mesclar dados de um arquivo de backup',
            ),
            onTap: () => context.push('/settings/backup/importar'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.delete),
            title: const Text(
              'Apagar Tudo',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Excluir permanentemente todos os dados armazenados',
            ),
            onTap: () => context.push('/settings/backup/apagar-tudo'),
          ),
        ],
      ),
    );
  }
}
