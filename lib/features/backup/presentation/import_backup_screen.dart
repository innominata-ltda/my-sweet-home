// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/backup/data/backup_service_provider.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';
import 'package:my_sweet_home/features/backup/presentation/import_backup_controller.dart';

/// Reads backup file content from a [PlatformFile] using [path] or [readAsBytes].
@visibleForTesting
Future<String?> readPickedPlatformFile(PlatformFile file) async {
  final path = file.path;
  if (path != null && path.isNotEmpty) {
    return File(path).readAsString();
  }
  final bytes = await file.readAsBytes();
  if (bytes.isNotEmpty) {
    return utf8.decode(bytes);
  }
  return null;
}

typedef PickBackupContent = Future<String?> Function();

/// Backup import screen with preview and mode selection (RN-232).
///
/// Allows user to preview how many records will be affected and choose
/// entre "Substituir tudo" ou "Mesclar" dados.
class ImportBackupScreen extends ConsumerStatefulWidget {
  const ImportBackupScreen({
    super.key,
    this.jsonContent,
    this.backupService,
    this.controller,
    this.pickBackupContent,
  });

  final String? jsonContent;
  final BackupService? backupService;
  final ImportBackupController? controller;
  final PickBackupContent? pickBackupContent;

  @override
  ConsumerState<ImportBackupScreen> createState() => _ImportBackupScreenState();
}

class _ImportBackupScreenState extends ConsumerState<ImportBackupScreen> {
  late final ImportBackupController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final BackupService service =
          widget.backupService ?? ref.read(backupServiceProvider);
      _controller = ImportBackupController(backupService: service);
    }

    if (widget.jsonContent != null && widget.jsonContent!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.loadPreview(widget.jsonContent!);
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Dados')),
      body: ValueListenableBuilder<ImportBackupState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          if (state is ImportBackupLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando backup...'),
                ],
              ),
            );
          }

          if (state is ImportBackupSuccess) {
            final isReplace = state.importedMode == ImportMode.replace;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.check,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isReplace
                          ? 'Backup restaurado com sucesso!'
                          : 'Dados mesclados com sucesso!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReplace
                          ? 'Os dados do aplicativo foram totalmente substituídos pelos do backup.'
                          : 'Os registros do backup foram mesclados aos dados existentes.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Concluído'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ImportBackupError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.error,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Falha na importação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.jsonContent != null)
                      ElevatedButton(
                        onPressed: () =>
                            _controller.loadPreview(widget.jsonContent!),
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                ),
              ),
            );
          }

          if (state is ImportBackupPreviewReady) {
            final preview = state.preview;
            final selectedMode = state.selectedMode;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(AppIcons.info),
                              const SizedBox(width: 8),
                              Text(
                                'Pré-visualização do Backup',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            '${preview.totalRecords} registros afetados',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Versão do schema: v${preview.schemaVersion}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (preview.exportedAt.isNotEmpty)
                            Text(
                              'Data da exportação: ${preview.exportedAt}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: preview.tableRecordCounts.entries.map((
                              e,
                            ) {
                              return Chip(
                                label: Text('${e.key}: ${e.value}'),
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Escolha a forma de importação:',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: selectedMode == ImportMode.replace ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selectedMode == ImportMode.replace
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<ImportMode>(
                      value: ImportMode.replace,
                      groupValue: selectedMode,
                      onChanged: (mode) {
                        if (mode != null) _controller.selectMode(mode);
                      },
                      title: const Text(
                        'Substituir tudo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(BackupPreview.replaceDescription),
                      ),
                      secondary: const Icon(AppIcons.restore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: selectedMode == ImportMode.merge ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selectedMode == ImportMode.merge
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<ImportMode>(
                      value: ImportMode.merge,
                      groupValue: selectedMode,
                      onChanged: (mode) {
                        if (mode != null) _controller.selectMode(mode);
                      },
                      title: const Text(
                        'Mesclar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(BackupPreview.mergeDescription),
                      ),
                      secondary: const Icon(AppIcons.merge),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _controller.confirmImport(),
                    icon: Icon(
                      selectedMode == ImportMode.replace
                          ? AppIcons.restore
                          : AppIcons.merge,
                    ),
                    label: Text(
                      selectedMode == ImportMode.replace
                          ? 'Substituir e restaurar backup'
                          : 'Mesclar dados do backup',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.restore, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum backup selecionado para pré-visualização.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    key: const Key('import_backup_pick_file_button'),
                    onPressed: _pickAndLoadBackup,
                    icon: const Icon(AppIcons.fileExport),
                    label: const Text('Selecionar arquivo de backup'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _defaultPickBackupContent() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return null;
    return readPickedPlatformFile(files.single);
  }

  bool _isEncryptedEnvelope(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> &&
          decoded.containsKey('salt') &&
          decoded.containsKey('ciphertext');
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickAndLoadBackup() async {
    final picker = widget.pickBackupContent ?? _defaultPickBackupContent;
    final content = await picker();
    if (content == null || content.isEmpty || !mounted) return;

    if (!_isEncryptedEnvelope(content)) {
      await _controller.loadPreview(content);
      return;
    }

    var passwordInput = '';
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Criptografado'),
        content: TextField(
          key: const Key('import_encrypted_password_field'),
          onChanged: (v) => passwordInput = v,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha do backup'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('import_encrypted_confirm_button'),
            onPressed: () => Navigator.of(ctx).pop(passwordInput),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    final res = await _controller.backupService.importEncryptedBackup(
      content,
      password,
    );
    if (!mounted) return;
    final message = switch (res) {
      Ok() => 'Backup restaurado com sucesso!',
      Err(:final failure) => 'Falha ao restaurar backup: $failure',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
