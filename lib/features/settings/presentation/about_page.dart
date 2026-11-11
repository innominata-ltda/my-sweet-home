import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você já está na versão mais recente.'),
            ),
          );
        }
      },
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível verificar atualizações no momento.',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o My Sweet Home')),
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
                      'Versão ',
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
            title: const Text('Licenças de código aberto'),
            subtitle: const Text('Licenças de pacotes e dependências'),
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
            title: const Text('Atribuições'),
            subtitle: const Text('Atribuições de ativos e terceiros'),
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
            leading: const Icon(AppIcons.sync),
            title: const Text('Verificar atualizações'),
            subtitle: const Text('Buscar novas versões na loja de aplicativos'),
            onTap: () => _handleCheckForUpdates(context, ref),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Atribuições')),
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
                child: Text('Erro ao carregar atribuições: ${snapshot.error}'),
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
