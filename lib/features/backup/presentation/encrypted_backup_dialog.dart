import 'package:flutter/material.dart';
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

  String _stageLabel(BackupStage stage) {
    switch (stage) {
      case BackupStage.collecting:
        return 'Coletando dados do aplicativo...';
      case BackupStage.encrypting:
        return 'Criptografando com AES-256 e Argon2id...';
      case BackupStage.writing:
        return 'Finalizando arquivo de backup...';
      case BackupStage.done:
        return 'Concluído!';
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(AppIcons.lockBackup),
          SizedBox(width: 8),
          Expanded(child: Text('Backup Criptografado')),
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
                            'Aviso Importante (RN-234)',
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
                        'Se você perder a senha, o backup é perdido.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O aplicativo não salva sua senha nem consegue ler o backup sem ela. Não há opção de recuperação.',
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
                decoration: const InputDecoration(
                  labelText: 'Senha do Backup *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.lockBackup),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe uma senha para proteger o backup';
                  }
                  if (val.length < 4) {
                    return 'A senha deve ter pelo menos 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Senha *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.lockBackup),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return 'As senhas não coincidem';
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
                title: const Text('Incluir fotos no backup (RN-237)'),
                subtitle: Text(
                  widget.estimatedPhotosSizeBytes != null
                      ? 'Fotos de cupons e receitas (Tamanho estimado: ${_formatBytes(widget.estimatedPhotosSizeBytes!)})'
                      : 'Fotos de cupons e receitas ficam fora do backup por padrão',
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
                        _stageLabel(_stage!),
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
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Exportar Criptografado'),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(AppIcons.lockBackup),
          SizedBox(width: 8),
          Expanded(child: Text('Restaurar Backup Criptografado')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Este arquivo de backup está protegido por senha. Informe a senha definida durante a exportação para continuar.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha do Backup *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AppIcons.lockBackup),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Digite a senha do backup';
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
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Descriptografar e Restaurar'),
        ),
      ],
    );
  }
}
