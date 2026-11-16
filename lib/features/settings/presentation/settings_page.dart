import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/notifications/notification_providers.dart';
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
  bool _deleteReceiptPhoto = true;
  bool _retentionNotifications = true;
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
      repo.isDeleteReceiptPhotoEnabled().then((v) {
        if (mounted) setState(() => _deleteReceiptPhoto = v);
      });
      repo.isRetentionNotificationsEnabled().then((v) {
        if (mounted) setState(() => _retentionNotifications = v);
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

  Future<void> _toggleDeleteReceiptPhoto(bool value) async {
    setState(() => _deleteReceiptPhoto = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(settingsRepositoryProvider)
          .setDeleteReceiptPhotoEnabled(value);
    } catch (_) {}
  }

  Future<void> _toggleRetentionNotifications(bool value) async {
    setState(() => _retentionNotifications = value);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(retentionNotificationCoordinatorProvider)
          .onSettingChanged(value);
    } catch (_) {}
  }

  AppLocalizations _resolveL10n(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
  }

  String _localeDisplayName(AppLocalizations l10n, String localeId) {
    if (localeId == AppLocaleRegistry.systemLocaleId) {
      return l10n.settingsLanguageSystem;
    }
    return AppLocaleRegistry.findById(localeId)?.displayName ??
        l10n.settingsLanguageSystem;
  }

  String _receiptFormatDisplayName(AppLocalizations l10n, String formatId) {
    if (formatId == ReceiptFormatCatalog.autoFormatId) {
      return l10n.settingsOcrFormatAuto;
    }
    return ReceiptFormatCatalog.findById(formatId)?.displayName ??
        l10n.settingsOcrFormatAuto;
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
    final l10n = _resolveL10n(context);
    await _showOptionPicker(
      title: l10n.settingsLanguageTitle,
      currentId: _appLocale,
      options: [
        (
          id: AppLocaleRegistry.systemLocaleId,
          title: l10n.settingsLanguageSystem,
          subtitle: l10n.settingsLanguageSystemSubtitle,
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
    final l10n = _resolveL10n(context);
    await _showOptionPicker(
      title: l10n.settingsOcrFormatTitle,
      currentId: _receiptFormat,
      options: [
        (
          id: ReceiptFormatCatalog.autoFormatId,
          title: l10n.settingsOcrFormatAuto,
          subtitle: l10n.settingsOcrFormatAutoSubtitle,
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
    final l10n = _resolveL10n(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ── 1. Appearance and Experience ─────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionAppearance),
          ListTile(
            key: const Key('settings_mascot_tile'),
            leading: const Icon(AppIcons.catPets),
            title: Text(l10n.settingsMascotOption),
            subtitle: Text(l10n.settingsMascotShortSubtitle),
            onTap:
                widget.onMascotTap ??
                () {
                  context.push('/mascot/customize');
                },
          ),
          SwitchListTile(
            key: const Key('settings_visual_effects_switch'),
            secondary: const Icon(AppIcons.taskPreset),
            title: Text(l10n.settingsVisualEffectsTitle),
            subtitle: Text(l10n.settingsVisualEffectsSubtitle),
            value: _visualEffects,
            onChanged: _toggleVisualEffects,
          ),
          SwitchListTile(
            key: const Key('settings_retention_notifications_switch'),
            secondary: const Icon(AppIcons.catPets),
            title: Text(l10n.settingsRetentionNotificationsTitle),
            subtitle: Text(l10n.settingsRetentionNotificationsSubtitle),
            value: _retentionNotifications,
            onChanged: _toggleRetentionNotifications,
          ),
          ListTile(
            key: const Key('settings_tutorial_tile'),
            leading: const Icon(AppIcons.info),
            title: Text(l10n.settingsTutorialOption),
            subtitle: Text(l10n.settingsTutorialSubtitle),
            onTap:
                widget.onTutorialTap ??
                () {
                  context.push('/onboarding');
                },
          ),
          ListTile(
            key: const Key('settings_language_tile'),
            leading: const Icon(AppIcons.info),
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(_localeDisplayName(l10n, _appLocale)),
            onTap: _selectAppLocale,
          ),
          ListTile(
            key: const Key('settings_receipt_format_tile'),
            leading: const Icon(AppIcons.ocr),
            title: Text(l10n.settingsOcrFormatTitle),
            subtitle: Text(_receiptFormatDisplayName(l10n, _receiptFormat)),
            onTap: _selectReceiptFormat,
          ),

          const Divider(),

          // ── 2. Your Home and Modules ─────────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionModules),
          ListTile(
            key: const Key('settings_household_tile'),
            leading: const Icon(AppIcons.household),
            title: Text(l10n.householdTitle),
            subtitle: Text(l10n.householdSubtitle),
            onTap: () => context.push('/ajustes/casa'),
          ),
          ListTile(
            key: const Key('settings_recipes_tile'),
            leading: const Icon(AppIcons.recipes),
            title: Text(l10n.recipesTitle),
            subtitle: Text(l10n.settingsRecipesSubtitle),
            onTap: () => context.push('/receitas'),
          ),
          ListTile(
            key: const Key('settings_stock_tile'),
            leading: const Icon(AppIcons.stock),
            title: Text(l10n.settingsStockTitle),
            subtitle: Text(l10n.settingsStockSubtitle),
            onTap: () => context.push('/estoque'),
          ),
          ListTile(
            key: const Key('settings_economy_tile'),
            leading: const Icon(AppIcons.economy),
            title: Text(l10n.economyTitle),
            subtitle: Text(l10n.settingsEconomySubtitle),
            onTap: () => context.push('/economia'),
          ),
          ListTile(
            key: const Key('settings_checklist_tile'),
            leading: const Icon(AppIcons.checklist),
            title: Text(l10n.settingsChecklistTitle),
            subtitle: Text(l10n.settingsChecklistSubtitle),
            onTap: () => context.push('/checklist'),
          ),
          ListTile(
            key: const Key('settings_suggestions_tile'),
            leading: const Icon(AppIcons.tasks),
            title: Text(l10n.settingsSuggestionsTitle),
            subtitle: Text(l10n.settingsSuggestionsSubtitle),
            onTap: () => context.push('/tarefas/sugestoes'),
          ),
          ListTile(
            key: const Key('settings_products_tile'),
            leading: const Icon(AppIcons.product),
            title: Text(l10n.settingsProductsTitle),
            subtitle: Text(l10n.settingsProductsSubtitle),
            onTap: () => context.push('/produtos'),
          ),

          const Divider(),

          // ── 3. Privacy, Security and Data ─────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionPrivacy),
          SwitchListTile(
            key: const Key('settings_delete_receipt_photo_switch'),
            secondary: const Icon(AppIcons.delete),
            title: Text(l10n.settingsDeleteReceiptPhotoTitle),
            subtitle: Text(l10n.settingsDeleteReceiptPhotoSubtitle),
            value: _deleteReceiptPhoto,
            onChanged: _toggleDeleteReceiptPhoto,
          ),
          ListTile(
            key: const Key('settings_backup_tile'),
            leading: const Icon(AppIcons.backup),
            title: Text(l10n.backupTitle),
            subtitle: Text(l10n.settingsBackupSubtitle),
            onTap:
                widget.onBackupTap ??
                () {
                  context.push('/settings/backup');
                },
          ),

          const Divider(),

          // ── 4. Ajuda e Sobre ────────────────────────────────────────────────
          _buildSectionHeader(context, l10n.settingsSectionHelp),
          ListTile(
            key: const Key('settings_about_tile'),
            leading: const Icon(AppIcons.about),
            title: Text(l10n.settingsAboutTitle),
            subtitle: Text(l10n.settingsAboutSubtitle),
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
