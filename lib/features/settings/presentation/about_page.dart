import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/update/app_update_providers.dart';
import 'package:my_sweet_home/core/update/update_dialog.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Tela "Sobre o My Sweet Home".
///
/// Displays version information, authorship, link to open-source licenses
/// (fulfilling RF-008 and RN-013) and asset/third-party attributions.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key, this.onLicensesTap, this.onAttributionsTap});

  static const appName = 'My Sweet Home';
  static const appVersion = '0.1.0';
  static const legalese = 'Feito por Innominata Ltda';
  static const githubRepoUrl =
      'https://github.com/innominata-ltda/my-sweet-home';
  static const wikiUrl = 'https://innominata-ltda.github.io/my-sweet-home/';

  /// Optional callback triggered upon tapping "Open-source licenses".
  ///
  /// Quando nulo, chama [showLicensePage].
  final VoidCallback? onLicensesTap;

  /// Optional callback triggered upon tapping "Attributions".
  ///
  /// When null, navigates to [AttributionsPage].
  final VoidCallback? onAttributionsTap;

  Future<void> _handleCheckForUpdates(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(appUpdateServiceProvider);
    final result = await service.checkManually();

    if (!context.mounted) return;

    result.fold(
      (info) {
        if (info.updateAvailable) {
          showAppUpdateDialog(
            context: context,
            updateInfo: info,
            service: service,
          );
        } else {
          final l10n =
              Localizations.of<AppLocalizations>(context, AppLocalizations) ??
              lookupAppLocalizations(const Locale('pt'));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.aboutUpToDate)));
        }
      },
      (failure) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            lookupAppLocalizations(const Locale('pt'));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.aboutUpdateCheckFailed)));
      },
    );
  }

  Future<void> _handleOpenExternalUrl(
    BuildContext context,
    WidgetRef ref, {
    required String url,
    required String fallbackMessage,
  }) async {
    final service = ref.read(appUpdateServiceProvider);
    final result = await service.openExternalUrl(url);

    if (!context.mounted) return;

    if (result.isErr) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(fallbackMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final theme = Theme.of(context);
    var isPlayStoreInstall = true;
    try {
      isPlayStoreInstall =
          ref.watch(installedFromPlayStoreProvider).asData?.value ?? true;
    } catch (_) {
      // Isolated widget tests without ProviderScope default to enabled
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: Spacing.md),
                Text(
                  appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.aboutVersionLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      appVersion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  legalese,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.openSource),
            title: Text(l10n.aboutLicensesTitle),
            subtitle: Text(l10n.aboutLicensesSubtitle),
            onTap:
                onLicensesTap ??
                () {
                  showLicensePage(
                    context: context,
                    applicationName: appName,
                    applicationVersion: appVersion,
                    applicationLegalese: legalese,
                  );
                },
          ),
          ListTile(
            leading: const Icon(AppIcons.info),
            title: Text(l10n.aboutAttributionsTitle),
            subtitle: Text(l10n.aboutAttributionsSubtitle),
            onTap:
                onAttributionsTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AttributionsPage(),
                    ),
                  );
                },
          ),
          ListTile(
            key: const Key('about_github_tile'),
            leading: const Icon(AppIcons.openSource),
            title: Text(l10n.aboutGithubTitle),
            subtitle: const Text('github.com/innominata-ltda/my-sweet-home'),
            onTap: () => _handleOpenExternalUrl(
              context,
              ref,
              url: githubRepoUrl,
              fallbackMessage: l10n.aboutGithubCopied,
            ),
          ),
          ListTile(
            key: const Key('about_wiki_tile'),
            leading: const Icon(AppIcons.info),
            title: Text(l10n.aboutDocsTitle),
            subtitle: const Text('innominata-ltda.github.io/my-sweet-home'),
            onTap: () => _handleOpenExternalUrl(
              context,
              ref,
              url: wikiUrl,
              fallbackMessage: l10n.aboutDocsCopied,
            ),
          ),
          ListTile(
            key: const Key('about_update_tile'),
            enabled: isPlayStoreInstall,
            leading: const Icon(AppIcons.sync),
            title: Text(l10n.aboutCheckUpdatesTitle),
            subtitle: Text(
              isPlayStoreInstall
                  ? l10n.aboutCheckUpdatesSubtitle
                  : l10n.aboutCheckUpdatesPlayStoreOnly,
            ),
            onTap: isPlayStoreInstall
                ? () => _handleCheckForUpdates(context, ref)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Screen displaying license attributions from text file.
class AttributionsPage extends StatelessWidget {
  const AttributionsPage({
    super.key,
    this.assetPath = 'assets/licenses/attributions.md',
  });

  /// Asset path containing attributions text.
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutAttributionsTitle)),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(l10n.aboutAttributionsError('${snapshot.error}')),
              ),
            );
          }
          final content = snapshot.data ?? '';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(content),
          );
        },
      ),
    );
  }
}
