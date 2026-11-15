// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
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

  Future<void> _defaultShareBackup(
    String content,
    String fileName,
    String shareText,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupExportSection)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.lockBackup, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                l10n.backupExportEncryptedTitle,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.backupExportEncryptedSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('export_backup_button'),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final BackupService service =
                      backupService ?? ref.read(backupServiceProvider);
                  final share =
                      shareBackup ??
                      (content, name) => _defaultShareBackup(
                        content,
                        name,
                        l10n.backupExportShareText,
                      );

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
                                      l10n.backupExportError('$failure'),
                                    ),
                                  ),
                                );
                              case Ok(:final value):
                                await share(
                                  value,
                                  'my_sweet_home_backup.mshbackup',
                                );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.backupExportSuccess),
                                  ),
                                );
                            }
                          },
                    ),
                  );
                },
                icon: const Icon(AppIcons.fileExport),
                label: Text(l10n.backupExportCreateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
