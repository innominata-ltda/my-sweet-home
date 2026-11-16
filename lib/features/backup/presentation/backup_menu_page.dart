import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

/// Backup and Export menu screen.
class BackupMenuPage extends StatelessWidget {
  const BackupMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(AppIcons.export),
            title: Text(l10n.backupMenuExportTitle),
            subtitle: Text(l10n.backupMenuExportSubtitle),
            onTap: () => context.push('/settings/backup/exportar'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.backup),
            title: Text(l10n.backupMenuImportTitle),
            subtitle: Text(l10n.backupMenuImportSubtitle),
            onTap: () => context.push('/settings/backup/importar'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.delete),
            title: Text(
              l10n.backupClearAllSection,
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(l10n.backupMenuWipeSubtitle),
            onTap: () => context.push('/settings/backup/apagar-tudo'),
          ),
        ],
      ),
    );
  }
}
