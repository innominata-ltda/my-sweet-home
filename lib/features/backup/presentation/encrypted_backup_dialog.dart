import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

/// Dialog for creating encrypted backup with explicit warning about password (RF-007, RN-234, RN-237).
class EncryptedBackupExportDialog extends StatefulWidget {
  const EncryptedBackupExportDialog({
    super.key,
    required this.onExportRequested,
    this.estimatedPhotosSizeBytes,
    this.stageNotifier,
  });

  /// Callback triggered when user confirms password and export options.
  final Future<void> Function(String password, {bool includePhotos})
  onExportRequested;

  /// Tamanho estimado das fotos em bytes (RN-237).
  final int? estimatedPhotosSizeBytes;

  /// Reactive notifier for export process stages (RN-424, CA-5.1).
  final ValueNotifier<BackupStage?>? stageNotifier;

  @override
  State<EncryptedBackupExportDialog> createState() =>
      _EncryptedBackupExportDialogState();
}

class _EncryptedBackupExportDialogState
    extends State<EncryptedBackupExportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _includePhotos = false;
  bool _isLoading = false;
  BackupStage? _stage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.stageNotifier?.addListener(_onStageChanged);
  }

  @override
  void dispose() {
    widget.stageNotifier?.removeListener(_onStageChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onStageChanged() {
    if (mounted) {
      setState(() {
        _stage = widget.stageNotifier?.value;
      });
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1).replaceAll('.', ',');
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2).replaceAll('.', ',');
    return '$mb MB';
  }

  String _stageLabel(AppLocalizations l10n, BackupStage stage) {
    switch (stage) {
      case BackupStage.collecting:
        return l10n.backupStageCollecting;
      case BackupStage.encrypting:
        return l10n.backupStageEncrypting;
      case BackupStage.writing:
        return l10n.backupStageWriting;
      case BackupStage.done:
        return l10n.backupStageDone;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _stage = widget.stageNotifier?.value ?? BackupStage.collecting;
      _errorMessage = null;
    });

    try {
      await widget.onExportRequested(
        _passwordController.text,
        includePhotos: _includePhotos,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _stage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return AlertDialog(
      title: Row(
        children: [
          const Icon(AppIcons.lockBackup),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backupEncryptedTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.warning,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.backupWarningTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.backupWarningLostPassword,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.backupWarningNoRecovery,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPasswordLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(AppIcons.lockBackup),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.backupPasswordRequired;
                  }
                  if (val.length < 4) {
                    return l10n.backupPasswordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.backupConfirmPasswordLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(AppIcons.lockBackup),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return l10n.backupPasswordsMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _includePhotos,
                onChanged: _isLoading
                    ? null
                    : (val) {
                        setState(() {
                          _includePhotos = val ?? false;
                        });
                      },
                title: Text(l10n.backupIncludePhotosTitle),
                subtitle: Text(
                  widget.estimatedPhotosSizeBytes != null
                      ? l10n.backupIncludePhotosWithSize(
                          _formatBytes(widget.estimatedPhotosSizeBytes!),
                        )
                      : l10n.backupIncludePhotosDefault,
                  style: const TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_isLoading && _stage != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        _stageLabel(l10n, _stage!),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.backupExportEncryptedButton),
        ),
      ],
    );
  }
}

/// Dialog for restoring encrypted backup with password verification (CA-3.1).
class EncryptedBackupImportDialog extends StatefulWidget {
  const EncryptedBackupImportDialog({
    super.key,
    required this.onImportRequested,
  });

  /// Callback triggered when user provides password to decrypt.
  final Future<void> Function(String password) onImportRequested;

  @override
  State<EncryptedBackupImportDialog> createState() =>
      _EncryptedBackupImportDialogState();
}

class _EncryptedBackupImportDialogState
    extends State<EncryptedBackupImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onImportRequested(_passwordController.text);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Senha incorreta ou falha ao descriptografar: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return AlertDialog(
      title: Row(
        children: [
          const Icon(AppIcons.lockBackup),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backupRestoreEncryptedTitle)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.backupRestoreEncryptedBody),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.backupPasswordLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(AppIcons.lockBackup),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.backupRestorePasswordRequired;
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.backupRestoreEncryptedButton),
        ),
      ],
    );
  }
}
