import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/celebration_overlay.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';

import '../../../../test/fakes/fake_settings_repository.dart';

void main() {
  group('SPEC-015 / T-04 — Settings, Categorization and Visual Effects (CA-3.1, CA-3.2, CA-3.3, RN-387..389)', () {
    late FakeSettingsRepository fakeSettingsRepo;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
    });

    Widget buildSubject({GoRouter? router, Widget? child}) {
      return ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        ],
        child: router != null
            ? MaterialApp.router(
                theme: lightTheme(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('pt', 'BR')],
                routerConfig: router,
              )
            : MaterialApp(
                theme: lightTheme(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('pt', 'BR')],
                home: child ?? const SettingsPage(),
              ),
      );
    }

    testWidgets(
      'CA-3.1: Exibe as 4 seções temáticas e atalhos para todos os módulos',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Appearance and Experience
        expect(find.text('Aparência e Experiência'), findsOneWidget);
        expect(find.byKey(const Key('settings_mascot_tile')), findsOneWidget);
        expect(
          find.byKey(const Key('settings_visual_effects_switch')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings_tutorial_tile')), findsOneWidget);

        // 2. Your Home and Modules
        expect(find.text('Sua Casa e Módulos'), findsOneWidget);
        expect(
          find.byKey(const Key('settings_household_tile')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings_recipes_tile')), findsOneWidget);
        expect(find.byKey(const Key('settings_stock_tile')), findsOneWidget);
        expect(find.byKey(const Key('settings_economy_tile')), findsOneWidget);
        expect(
          find.byKey(const Key('settings_checklist_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('settings_suggestions_tile')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings_products_tile')), findsOneWidget);

        // 3. Privacy, Security and Data
        expect(find.text('Privacidade, Segurança e Dados'), findsOneWidget);
        expect(
          find.byKey(const Key('settings_hide_values_switch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('settings_delete_receipt_photo_switch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('settings_household_sync_remote_switch')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('settings_cloud_backup_switch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('settings_cloud_ocr_switch')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('settings_security_tile')), findsOneWidget);
        expect(find.byKey(const Key('settings_backup_tile')), findsOneWidget);

        // 4. Ajuda e Sobre
        expect(find.text('Ajuda e Sobre'), findsOneWidget);
        expect(find.byKey(const Key('settings_about_tile')), findsOneWidget);
      },
    );

    testWidgets(
      'CA-3.1: Navega para submódulos ao tocar nos atalhos da seção Sua Casa e Módulos',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final routesVisited = <String>[];
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/receitas',
              builder: (context, state) {
                routesVisited.add('/receitas');
                return const Scaffold(body: Text('Tela Receitas'));
              },
            ),
            GoRoute(
              path: '/estoque',
              builder: (context, state) {
                routesVisited.add('/estoque');
                return const Scaffold(body: Text('Tela Estoque'));
              },
            ),
            GoRoute(
              path: '/economia',
              builder: (context, state) {
                routesVisited.add('/economia');
                return const Scaffold(body: Text('Tela Economia'));
              },
            ),
            GoRoute(
              path: '/checklist',
              builder: (context, state) {
                routesVisited.add('/checklist');
                return const Scaffold(body: Text('Tela Checklist'));
              },
            ),
            GoRoute(
              path: '/tarefas/sugestoes',
              builder: (context, state) {
                routesVisited.add('/tarefas/sugestoes');
                return const Scaffold(body: Text('Tela Sugestoes'));
              },
            ),
          ],
        );

        await tester.pumpWidget(buildSubject(router: router));
        await tester.pumpAndSettle();

        // Clica em Receitas
        final recipesTile = find.byKey(const Key('settings_recipes_tile'));
        await tester.tap(recipesTile);
        await tester.pumpAndSettle();
        expect(routesVisited, contains('/receitas'));

        // Volta para /settings
        router.go('/settings');
        await tester.pumpAndSettle();

        // Clica em Estoque
        final stockTile = find.byKey(const Key('settings_stock_tile'));
        await tester.tap(stockTile);
        await tester.pumpAndSettle();
        expect(routesVisited, contains('/estoque'));

        // Volta e clica em Economia
        router.go('/settings');
        await tester.pumpAndSettle();
        final economyTile = find.byKey(const Key('settings_economy_tile'));
        await tester.tap(economyTile);
        await tester.pumpAndSettle();
        expect(routesVisited, contains('/economia'));

        // Volta e clica em Checklist
        router.go('/settings');
        await tester.pumpAndSettle();
        final checklistTile = find.byKey(const Key('settings_checklist_tile'));
        await tester.tap(checklistTile);
        await tester.pumpAndSettle();
        expect(routesVisited, contains('/checklist'));

        // Back and click Suggestions
        router.go('/settings');
        await tester.pumpAndSettle();
        final suggestionsTile = find.byKey(
          const Key('settings_suggestions_tile'),
        );
        await tester.tap(suggestionsTile);
        await tester.pumpAndSettle();
        expect(routesVisited, contains('/tarefas/sugestoes'));
      },
    );

    testWidgets(
      'CA-3.2: Desativar "Efeitos visuais e partículas" desativa animações em MascotWidget e CelebrationOverlay',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        final switchFinder = find.byKey(
          const Key('settings_visual_effects_switch'),
        );
        expect(switchFinder, findsOneWidget);

        // Inicialmente true
        expect(await fakeSettingsRepo.isVisualEffectsEnabled(), isTrue);

        // Desativa o switch
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(await fakeSettingsRepo.isVisualEffectsEnabled(), isFalse);
        expect(container.read(visualEffectsEnabledProvider), isFalse);

        // Test MascotWidget rendering under visualEffectsEnabled == false
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: MascotWidget(
                  expression: MascotExpression.happy,
                  animateIdle: true,
                  disableAnimations: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final mascotState = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(mascotState.isAnimating, isFalse);

        // Testa CelebrationOverlay sob visualEffectsEnabled == false
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: CelebrationOverlay(disableAnimations: false),
              ),
            ),
          ),
        );
        await tester.pump();

        final celebrationState = tester.state<CelebrationOverlayState>(
          find.byType(CelebrationOverlay),
        );
        expect(celebrationState.animationController.isAnimating, isFalse);
      },
    );

    testWidgets(
      'CA-3.3: Alternar switches de privacidade persiste imediatamente em SettingsRepository',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Ocultar valores financeiros
        final hideValuesFinder = find.byKey(
          const Key('settings_hide_values_switch'),
        );
        await tester.tap(hideValuesFinder);
        await tester.pumpAndSettle();
        expect(await fakeSettingsRepo.isHideValuesEnabled(), isTrue);

        // 2. Delete receipt photo (default true -> toggle to false)
        final deletePhotoFinder = find.byKey(
          const Key('settings_delete_receipt_photo_switch'),
        );
        await tester.tap(deletePhotoFinder);
        await tester.pumpAndSettle();
        expect(await fakeSettingsRepo.isDeleteReceiptPhotoEnabled(), isFalse);

        // 3. Backup em nuvem
        final cloudBackupFinder = find.byKey(
          const Key('settings_cloud_backup_switch'),
        );
        await tester.tap(cloudBackupFinder);
        await tester.pumpAndSettle();
        expect(await fakeSettingsRepo.isCloudBackupAllowed(), isTrue);

        // 4. OCR em nuvem
        final cloudOcrFinder = find.byKey(
          const Key('settings_cloud_ocr_switch'),
        );
        await tester.tap(cloudOcrFinder);
        await tester.pumpAndSettle();
        expect(await fakeSettingsRepo.isCloudOcrAllowed(), isTrue);
      },
    );
  });
}
