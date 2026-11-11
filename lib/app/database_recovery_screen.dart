import 'package:flutter/material.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

/// Database integrity recovery and diagnostics screen (RN-416, RN-417, CA-3.4, CA-3.5).
class DatabaseRecoveryScreen extends StatefulWidget {
  const DatabaseRecoveryScreen({
    super.key,
    required this.opening,
    required this.vault,
    this.onImportBackup,
    this.onRestartComplete,
    this.onExportBackup,
    this.onContinueWithPlaintext,
  });

  final VaultOpening opening;
  final DatabaseVaultPort vault;
  final Future<void> Function()? onImportBackup;
  final Future<void> Function()? onRestartComplete;
  final Future<void> Function()? onExportBackup;
  final VoidCallback? onContinueWithPlaintext;

  @override
  State<DatabaseRecoveryScreen> createState() => _DatabaseRecoveryScreenState();
}

class _DatabaseRecoveryScreenState extends State<DatabaseRecoveryScreen> {
  bool _isProcessing = false;

  Future<void> _handleResetAndRestart() async {
    // First confirmation
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recomeçar do zero?'),
        content: const Text(
          'Todos os dados locais existentes serão permanentemente apagados.',
        ),
        actions: [
          TextButton(
            key: const Key('recovery_confirm_cancel_1'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('recovery_confirm_proceed_1'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !mounted) return;

    // Second confirmation (double confirmation - RN-417, CA-3.5)
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmação definitiva'),
        content: const Text(
          'Esta ação é irreversível. Tem certeza absoluta que deseja apagar todos os dados e recomeçar?',
        ),
        actions: [
          TextButton(
            key: const Key('recovery_confirm_cancel_2'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('recovery_confirm_proceed_2'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar e apagar'),
          ),
        ],
      ),
    );

    if (secondConfirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await widget.vault.destroy();
      if (widget.onRestartComplete != null) {
        await widget.onRestartComplete!();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyUnavailable = widget.opening is VaultKeyUnavailable;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          isKeyUnavailable
              ? 'Chave do banco inacessível'
              : 'Falha na segurança do banco',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    isKeyUnavailable ? AppIcons.lockBackup : AppIcons.warning,
                    size: 64,
                    color: isKeyUnavailable
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isKeyUnavailable
                        ? 'Chave de segurança inacessível'
                        : 'Conversão de segurança falhou',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isKeyUnavailable
                        ? 'Não foi possível acessar a chave de segurança no dispositivo. '
                              'Para proteger seus dados, nenhum banco vazio foi criado.\n\n'
                              'Você pode restaurar um backup anterior ou recomeçar do zero.'
                        : 'A conversão do banco existente para o formato cifrado falhou, '
                              'mas seus dados continuam intactos no banco original.\n\n'
                              'Recomendamos exportar um backup antes de prosseguir.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else if (isKeyUnavailable) ...[
                    Semantics(
                      button: true,
                      label: 'Importar backup',
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          key: const Key('recovery_import_backup_button'),
                          onPressed: widget.onImportBackup != null
                              ? () async {
                                  setState(() => _isProcessing = true);
                                  try {
                                    await widget.onImportBackup!();
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                }
                              : null,
                          icon: const Icon(AppIcons.fileImport, size: 20),
                          label: const Text('Importar backup'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Recomeçar do zero',
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('recovery_restart_button'),
                          onPressed: _handleResetAndRestart,
                          icon: const Icon(AppIcons.deleteForever, size: 20),
                          label: const Text('Recomeçar do zero'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Semantics(
                      button: true,
                      label: 'Exportar backup',
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          key: const Key('recovery_export_backup_button'),
                          onPressed: widget.onExportBackup != null
                              ? () async {
                                  setState(() => _isProcessing = true);
                                  try {
                                    await widget.onExportBackup!();
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                }
                              : null,
                          icon: const Icon(AppIcons.fileExport, size: 20),
                          label: const Text('Exportar backup'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Continuar no formato original',
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          key: const Key('recovery_continue_button'),
                          onPressed: widget.onContinueWithPlaintext,
                          child: const Text('Continuar'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (context.findAncestorWidgetOfExactType<MaterialApp>() == null &&
        context.findAncestorWidgetOfExactType<Directionality>() == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: scaffold,
      );
    }

    return scaffold;
  }
}
