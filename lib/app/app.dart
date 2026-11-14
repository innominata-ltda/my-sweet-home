import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/core/notifications/notification_providers.dart';
import 'package:my_sweet_home/core/regionalization/regionalization_models.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/sync/presentation/providers/household_providers.dart';

class MySweetHomeApp extends ConsumerStatefulWidget {
  const MySweetHomeApp({super.key, this.router});

  /// Optional [GoRouter] instance for tests or custom routes.
  final GoRouter? router;

  @override
  ConsumerState<MySweetHomeApp> createState() => _MySweetHomeAppState();
}

class _MySweetHomeAppState extends ConsumerState<MySweetHomeApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _scheduleRetention);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRetention());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _scheduleRetention() {
    try {
      unawaited(
        ref
            .read(retentionNotificationCoordinatorProvider)
            .onAppOpenedOrResumed(),
      );
    } catch (_) {
      // Ignored in isolated widget tests without database overrides.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Automatically start LAN listener if there is an active household
    final household = ref.watch(householdStreamProvider).asData?.value;
    if (household != null) {
      ref.read(lanSyncTransportProvider).start();
    }

    final effectiveRouter = widget.router ?? ref.watch(appRouterProvider);

    AppPalette palette = AppPalette.rose;
    try {
      final mascotConfigAsync = ref.watch(mascotConfigStreamProvider);
      palette = mascotConfigAsync.maybeWhen(
        data: (config) => AppPalette.fromId(config.palette.name),
        orElse: () => AppPalette.rose,
      );
    } catch (_) {
      palette = AppPalette.rose;
    }

    Locale? activeLocale;
    try {
      final localeId = ref.watch(appLocaleProvider);
      final descriptor = AppLocaleRegistry.findById(localeId);
      if (descriptor != null) {
        activeLocale = Locale(descriptor.languageCode, descriptor.countryCode);
      }
    } catch (_) {
      activeLocale = null;
    }

    final supportedLocales = AppLocaleRegistry.supportedLocales
        .map((d) => Locale(d.languageCode, d.countryCode))
        .toList(growable: false);

    return MaterialApp.router(
      title: 'My Sweet Home',
      theme: lightTheme(palette.lightScheme),
      darkTheme: darkTheme(palette.darkScheme),
      routerConfig: effectiveRouter,
      locale: activeLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    );
  }
}
