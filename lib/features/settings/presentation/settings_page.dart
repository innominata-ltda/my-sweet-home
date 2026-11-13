import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/regionalization/regionalization_models.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/settings/presentation/about_page.dart';

/// Main settings and adjustments screen of My Sweet Home app (SPEC-015, RF-012, RF-014, RN-387..389).
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.onAboutTap,
    this.onBackupTap,
    this.onMascotTap,
    this.onTutorialTap,
  });

  /// Optional callback triggered upon tapping "About".
  final VoidCallback? onAboutTap;

  /// Optional callback triggered upon tapping "Backup and Export".
  final VoidCallback? onBackupTap;

  /// Optional callback triggered upon tapping "Customize Momo" (RN-263).
  final VoidCallback? onMascotTap;

  /// Optional callback triggered upon tapping "View tutorial with Momo" (RN-276, CA-009.4).
  final VoidCallback? onTutorialTap;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ProviderSubscription<bool>? _visualEffectsSub;
  bool _visualEffects = true;
  bool _hideValues = false;
  bool _deleteReceiptPhoto = true;
  bool _cloudBackup = false;
  bool _cloudOcr = false;
  String _appLocale = AppLocaleRegistry.systemLocaleId;
  String _receiptFormat = ReceiptFormatCatalog.autoFormatId;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _initPreferences();
    }
  }

  @override
  void dispose() {
    _visualEffectsSub?.close();
    super.dispose();
  }

  void _initPreferences() {
    _loaded = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      _visualEffectsSub = container.listen<bool>(visualEffectsEnabledProvider, (
        prev,
        next,
      ) {
        if (mounted) {
          setState(() => _visualEffects = next);
        }
      });
      _visualEffects = container.read(visualEffectsEnabledProvider);

      final repo = container.read(settingsRepositoryProvider);
      repo.isHideValuesEnabled().then((v) {
        if (mounted) setState(() => _hideValues = v);
      });
      repo.isDeleteReceiptPhotoEnabled().then((v) {
        if (mounted) setState(() => _deleteReceiptPhoto = v);
      });
      repo.isCloudBackupAllowed().then((v) {
        if (mounted) setState(() => _cloudBackup = v);
      });
      repo.isCloudOcrAllowed().then((v) {
        if (mounted) setState(() => _cloudOcr = v);
      });
      repo.getAppLocale().then((v) {
        if (mounted) setState(() => _appLocale = v);
      });
      repo.getReceiptFormat().then((v) {
        if (mounted) setState(() => _receiptFormat = v);
      });
    } catch (_) {
      // No ProviderScope found (isolated widget unit tests without Riverpod)
    }
  }

  Future<void> _toggleVisualEffects(bool value) async {
    setState(() => _visualEffects = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(visualEffectsEnabledProvider.notifier)
          .setEnabled(value);
    } catch (_) {}
  }

  Future<void> _toggleHideValues(bool value) async {
    setState(() => _hideValues = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(settingsRepositoryProvider)
          .setHideValuesEnabled(value);
    } catch (_) {}
  }

  Future<void> _toggleDeleteReceiptPhoto(bool value) async {
    setState(() => _deleteReceiptPhoto = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(settingsRepositoryProvider)
          .setDeleteReceiptPhotoEnabled(value);
    } catch (_) {}
  }

  Future<void> _toggleCloudBackup(bool value) async {
    setState(() => _cloudBackup = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(settingsRepositoryProvider)
          .setCloudBackupAllowed(value);
    } catch (_) {}
  }

  Future<void> _toggleCloudOcr(bool value) async {
    setState(() => _cloudOcr = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(settingsRepositoryProvider)
          .setCloudOcrAllowed(value);
    } catch (_) {}
  }

  String _localeDisplayName(String localeId) {
    if (localeId == AppLocaleRegistry.systemLocaleId) {
      return 'Automático (sistema)';
    }
    return AppLocaleRegistry.findById(localeId)?.displayName ??
        'Automático (sistema)';
  }

  String _receiptFormatDisplayName(String formatId) {
    if (formatId == ReceiptFormatCatalog.autoFormatId) {
      return 'Automático (melhor modelo)';
    }
    return ReceiptFormatCatalog.findById(formatId)?.displayName ??
        'Automático (melhor modelo)';
  }

  Future<void> _showOptionPicker({
    required String title,
    required String currentId,
    required List<({String id, String title, String? subtitle, Key key})>
    options,
    required Future<void> Function(String selectedId) onSelected,
  }) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                ListTile(
                  key: option.key,
                  leading: Icon(
                    option.id == currentId
                        ? AppIcons.radioButtonChecked
                        : AppIcons.radioButtonOff,
                  ),
                  title: Text(option.title),
                  subtitle: option.subtitle != null
                      ? Text(option.subtitle!)
                      : null,
                  onTap: () => Navigator.of(dialogContext).pop(option.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      await onSelected(chosen);
    }
  }

  Future<void> _selectAppLocale() async {
    await _showOptionPicker(
      title: 'Idioma do aplicativo',
      currentId: _appLocale,
      options: [
        (
          id: AppLocaleRegistry.systemLocaleId,
          title: 'Automático (sistema)',
          subtitle: 'Segue o idioma configurado no aparelho',
          key: const Key('settings_locale_option_system'),
        ),
        for (final locale in AppLocaleRegistry.supportedLocales)
          (
            id: locale.id,
            title: locale.displayName,
            subtitle: locale.id,
            key: Key('settings_locale_option_${locale.id}'),
          ),
      ],
      onSelected: (selectedId) async {
        setState(() => _appLocale = selectedId);
        try {
          final container = ProviderScope.containerOf(context, listen: false);
          await container
              .read(appLocaleProvider.notifier)
              .setLocale(selectedId);
        } catch (_) {}
      },
    );
  }

  Future<void> _selectReceiptFormat() async {
    await _showOptionPicker(
      title: 'Modelo de nota fiscal (OCR)',
      currentId: _receiptFormat,
      options: [
        (
          id: ReceiptFormatCatalog.autoFormatId,
          title: 'Automático (melhor modelo)',
          subtitle: 'Seleciona automaticamente o formato com maior pontuação',
          key: const Key('settings_receipt_format_option_auto'),
        ),
        for (final format in ReceiptFormatCatalog.descriptors)
          (
            id: format.id,
            title: format.displayName,
            subtitle: format.description,
            key: Key('settings_receipt_format_option_${format.id}'),
          ),
      ],
      onSelected: (selectedId) async {
        setState(() => _receiptFormat = selectedId);
        try {
          final container = ProviderScope.containerOf(context, listen: false);
          await container
              .read(receiptFormatProvider.notifier)
              .setFormat(selectedId);
        } catch (_) {}
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.lg,
        bottom: Spacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // ── 1. Appearance and Experience ─────────────────────────────────────
          _buildSectionHeader(context, 'Aparência e Experiência'),
          ListTile(
            key: const Key('settings_mascot_tile'),
            leading: const Icon(AppIcons.catPets),
            title: Text(l10n?.settingsMascotOption ?? 'Personalizar Momo'),
            subtitle: Text(
              l10n?.settingsMascotSubtitle ??
                  'Animal, paleta de cor e acessório',
            ),
            onTap:
                widget.onMascotTap ??
                () {
                  context.push('/mascot/customize');
                },
          ),
          SwitchListTile(
            key: const Key('settings_visual_effects_switch'),
            secondary: const Icon(AppIcons.taskPreset),
            title: const Text('Efeitos visuais e partículas'),
            subtitle: const Text('Partículas, confetes e animações contínuas'),
            value: _visualEffects,
            onChanged: _toggleVisualEffects,
          ),
          ListTile(
            key: const Key('settings_tutorial_tile'),
            leading: const Icon(AppIcons.info),
            title: Text(
              l10n?.settingsTutorialOption ?? 'Ver tutorial com a Momo',
            ),
            subtitle: Text(
              l10n?.settingsTutorialSubtitle ??
                  'Relembre o funcionamento do app com a mascote',
            ),
            onTap:
                widget.onTutorialTap ??
                () {
                  context.push('/onboarding');
                },
          ),
          ListTile(
            key: const Key('settings_language_tile'),
            leading: const Icon(AppIcons.info),
            title: const Text('Idioma do aplicativo'),
            subtitle: Text(_localeDisplayName(_appLocale)),
            onTap: _selectAppLocale,
          ),
          ListTile(
            key: const Key('settings_receipt_format_tile'),
            leading: const Icon(AppIcons.ocr),
            title: const Text('Modelo de nota fiscal (OCR)'),
            subtitle: Text(_receiptFormatDisplayName(_receiptFormat)),
            onTap: _selectReceiptFormat,
          ),

          const Divider(),

          // ── 2. Your Home and Modules ─────────────────────────────────────────
          _buildSectionHeader(context, 'Sua Casa e Módulos'),
          ListTile(
            key: const Key('settings_household_tile'),
            leading: const Icon(AppIcons.household),
            title: Text(l10n?.householdTitle ?? 'Casa compartilhada'),
            subtitle: Text(
              l10n?.householdSubtitle ??
                  'Sincronizar tarefas e finanças em rede local',
            ),
            onTap: () => context.push('/ajustes/casa'),
          ),
          ListTile(
            key: const Key('settings_recipes_tile'),
            leading: const Icon(AppIcons.recipes),
            title: const Text('Receitas'),
            subtitle: const Text('Livro de receitas e ingredientes'),
            onTap: () => context.push('/receitas'),
          ),
          ListTile(
            key: const Key('settings_stock_tile'),
            leading: const Icon(AppIcons.stock),
            title: const Text('Estoque'),
            subtitle: const Text('Despensa e itens essenciais'),
            onTap: () => context.push('/estoque'),
          ),
          ListTile(
            key: const Key('settings_economy_tile'),
            leading: const Icon(AppIcons.economy),
            title: const Text('Modo Economia'),
            subtitle: const Text('Dicas e metas de economia'),
            onTap: () => context.push('/economia'),
          ),
          ListTile(
            key: const Key('settings_checklist_tile'),
            leading: const Icon(AppIcons.checklist),
            title: const Text('Checklist da 1ª Casa'),
            subtitle: const Text('Itens essenciais para a casa nova'),
            onTap: () => context.push('/checklist'),
          ),
          ListTile(
            key: const Key('settings_suggestions_tile'),
            leading: const Icon(AppIcons.tasks),
            title: const Text('Sugestões de Manutenção'),
            subtitle: const Text('Catálogo de tarefas sugeridas para o lar'),
            onTap: () => context.push('/tarefas/sugestoes'),
          ),
          ListTile(
            key: const Key('settings_products_tile'),
            leading: const Icon(AppIcons.product),
            title: const Text('Produtos e Sinônimos'),
            subtitle: const Text('Gerenciar catálogo de produtos'),
            onTap: () => context.push('/produtos'),
          ),

          const Divider(),

          // ── 3. Privacy, Security and Data ─────────────────────────────────────
          _buildSectionHeader(context, 'Privacidade, Segurança e Dados'),
          SwitchListTile(
            key: const Key('settings_hide_values_switch'),
            secondary: const Icon(AppIcons.money),
            title: const Text('Ocultar valores financeiros na tela inicial'),
            subtitle: const Text(
              'Mascarar centavos e totais quando em segundo plano',
            ),
            value: _hideValues,
            onChanged: _toggleHideValues,
          ),
          SwitchListTile(
            key: const Key('settings_delete_receipt_photo_switch'),
            secondary: const Icon(AppIcons.delete),
            title: const Text('Apagar foto do cupom após leitura'),
            subtitle: const Text(
              'Excluir arquivo de imagem após processamento do OCR',
            ),
            value: _deleteReceiptPhoto,
            onChanged: _toggleDeleteReceiptPhoto,
          ),
          SwitchListTile(
            key: const Key('settings_cloud_backup_switch'),
            secondary: const Icon(AppIcons.cloudBackup),
            title: const Text('Permitir backup em nuvem'),
            subtitle: const Text('Cópia criptografada no Google Drive'),
            value: _cloudBackup,
            onChanged: _toggleCloudBackup,
          ),
          SwitchListTile(
            key: const Key('settings_cloud_ocr_switch'),
            secondary: const Icon(AppIcons.ocr),
            title: const Text('Permitir leitura de cupom em nuvem (OCR)'),
            subtitle: const Text(
              'Processar recibos complexos na nuvem anonimamente',
            ),
            value: _cloudOcr,
            onChanged: _toggleCloudOcr,
          ),
          ListTile(
            key: const Key('settings_security_tile'),
            leading: const Icon(AppIcons.lockBackup),
            title: const Text('Bloqueio do aplicativo'),
            subtitle: const Text('Proteção por biometria ou PIN'),
            onTap: () {
              try {
                context.push('/settings/security');
              } catch (_) {}
            },
          ),
          ListTile(
            key: const Key('settings_backup_tile'),
            leading: const Icon(AppIcons.backup),
            title: const Text('Backup e Exportação'),
            subtitle: const Text('Exportar, importar e gerenciar dados'),
            onTap:
                widget.onBackupTap ??
                () {
                  context.push('/settings/backup');
                },
          ),

          const Divider(),

          // ── 4. Ajuda e Sobre ────────────────────────────────────────────────
          _buildSectionHeader(context, 'Ajuda e Sobre'),
          ListTile(
            key: const Key('settings_about_tile'),
            leading: const Icon(AppIcons.about),
            title: const Text('Sobre'),
            subtitle: const Text('Informações sobre o aplicativo'),
            onTap:
                widget.onAboutTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                  );
                },
          ),
        ],
      ),
    );
  }
}
