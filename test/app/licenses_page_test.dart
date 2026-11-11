import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/settings/presentation/about_page.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';

void main() {
  group('T-18 / RF-008 / RN-013 / CA-6.2 — Settings, About, and Licenses', () {
    testWidgets('SettingsPage renderiza e mostra item Sobre', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: lightTheme(), home: const SettingsPage()),
      );

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Informações sobre o aplicativo'), findsOneWidget);
      expect(find.text('Backup e Exportação'), findsOneWidget);
      expect(find.text('Exportar, importar e gerenciar dados'), findsOneWidget);
    });

    testWidgets(
      'Tapping Backup and Export with custom callback invokes callback',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: SettingsPage(onBackupTap: () => tapped = true),
          ),
        );

        await tester.tap(find.text('Backup e Exportação'));
        await tester.pump();

        expect(tapped, isTrue);
      },
    );

    testWidgets('Tapping Sobre with custom callback invokes callback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme(),
          home: SettingsPage(onAboutTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Sobre'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('Tapping Sobre navega para AboutPage via Navigator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: lightTheme(), home: const SettingsPage()),
      );

      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutPage), findsOneWidget);
      expect(find.text('Sobre o My Sweet Home'), findsOneWidget);
    });

    testWidgets('AboutPage shows app name, version and authorship', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme(), home: const AboutPage()),
      );

      expect(find.text('My Sweet Home'), findsOneWidget);
      expect(find.text('0.1.0'), findsOneWidget);
      expect(find.text('Feito por Innominata Ltda'), findsOneWidget);
    });

    testWidgets('AboutPage has Open-source licenses and Attributions button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme(), home: const AboutPage()),
      );

      expect(find.text('Licenças de código aberto'), findsOneWidget);
      expect(find.text('Atribuições'), findsOneWidget);
    });

    testWidgets(
      'Tapping licenses invokes showLicensePage and displays LicensePage',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: lightTheme(), home: const AboutPage()),
        );

        await tester.tap(find.text('Licenças de código aberto'));
        await tester.pumpAndSettle();

        expect(find.byType(LicensePage), findsOneWidget);
        expect(find.text('My Sweet Home'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('Tapping Attributions navigates to AttributionsPage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme(), home: const AboutPage()),
      );

      await tester.tap(find.text('Atribuições'));
      await tester.pumpAndSettle();

      expect(find.byType(AttributionsPage), findsOneWidget);
    });

    testWidgets(
      'CA-6.2: Complete flow Settings -> About -> Licenses in at most 2 taps (RN-013)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: darkTheme(), home: const SettingsPage()),
        );

        // Toque 1: Ajustes → Sobre
        await tester.tap(find.text('Sobre'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutPage), findsOneWidget);

        // Tap 2: About -> Licenses (RN-013: at most 2 taps from About)
        await tester.tap(find.text('Licenças de código aberto'));
        await tester.pumpAndSettle();

        expect(find.byType(LicensePage), findsOneWidget);
      },
    );
  });
}
