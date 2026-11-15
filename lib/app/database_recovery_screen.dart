import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
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

  AppLocalizations _resolveL10n(BuildContext context) {
    final existing = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (existing != null) return existing;
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final isSupported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == platformLocale.languageCode,
    );
    return lookupAppLocalizations(
      isSupported ? Locale(platformLocale.languageCode) : const Locale('pt'),
    );
  }

  Future<void> _handleResetAndRestart() async {
    final l10n = _resolveL10n(context);
    // First confirmation
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recoveryResetConfirmTitle),
        content: Text(l10n.recoveryResetConfirmBody),
        actions: [
          TextButton(
            key: const Key('recovery_confirm_cancel_1'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('recovery_confirm_proceed_1'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !mounted) return;

    // Second confirmation (double confirmation - RN-417, CA-3.5)
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recoveryResetFinalTitle),
        content: Text(l10n.recoveryResetFinalBody),
        actions: [
          TextButton(
            key: const Key('recovery_confirm_cancel_2'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('recovery_confirm_proceed_2'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recoveryResetFinalConfirm),
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
    final l10n = _resolveL10n(context);
    final theme = Theme.of(context);
    final isKeyUnavailable = widget.opening is VaultKeyUnavailable;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          isKeyUnavailable
              ? l10n.recoveryKeyUnavailableAppBar
              : l10n.recoverySecurityFailureAppBar,
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
                        ? l10n.recoveryKeyUnavailableTitle
                        : l10n.recoveryConversionFailedTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isKeyUnavailable
                        ? l10n.recoveryKeyUnavailableBody
                        : l10n.recoveryConversionFailedBody,
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
                      label: l10n.recoveryImportBackup,
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
                          label: Text(l10n.recoveryImportBackup),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: l10n.recoveryStartFromScratch,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('recovery_restart_button'),
                          onPressed: _handleResetAndRestart,
                          icon: const Icon(AppIcons.deleteForever, size: 20),
                          label: Text(l10n.recoveryStartFromScratch),
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
                      label: l10n.recoveryExportBackup,
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
                          label: Text(l10n.recoveryExportBackup),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: l10n.recoveryContinuePlaintextSemantics,
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          key: const Key('recovery_continue_button'),
                          onPressed: widget.onContinueWithPlaintext,
                          child: Text(l10n.commonContinue),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: scaffold,
      );
    }

    return scaffold;
  }
}
