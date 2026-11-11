import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';

void main() {
  group('SPEC-012/T-I02 — Mascot, Onboarding and Splash Routes Test', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Widget buildTestApp(GoRouter router) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: lightTheme(),
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
        ),
      );
    }

    testWidgets('Navega para /onboarding e renderiza OnboardingPage', (
      tester,
    ) async {
      final router = container.read(appRouterProvider);
      router.go('/onboarding');

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('Action "Pular" in /onboarding navigates to dashboard (/)', (
      tester,
    ) async {
      final router = container.read(appRouterProvider);
      router.go('/onboarding');

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);

      final skipButton = find.byKey(const Key('onboarding_skip_button'));
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Navega para /splash e exibe placeholder de splash', (
      tester,
    ) async {
      final router = container.read(appRouterProvider);
      router.go('/splash');

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Splash'), findsOneWidget);
    });

    testWidgets(
      'Navigates to /mascot/customize and displays customization placeholder',
      (tester) async {
        final router = container.read(appRouterProvider);
        router.go('/mascot/customize');

        await tester.pumpWidget(buildTestApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Personalizar Mascote'), findsOneWidget);
      },
    );

    testWidgets('Access to root route /mascot redirects to /mascot/customize', (
      tester,
    ) async {
      final router = container.read(appRouterProvider);
      router.go('/mascot');

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Personalizar Mascote'), findsOneWidget);
    });

    testWidgets(
      'Navigates to /mascot/customize with query parameters and extra payload',
      (tester) async {
        final router = container.read(appRouterProvider);
        router.go(
          '/mascot/customize?source=settings&step=2',
          extra: {'initialAnimal': 'cat'},
        );

        await tester.pumpWidget(buildTestApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Personalizar Mascote'), findsOneWidget);
      },
    );

    testWidgets(
      'Smooth transition between routes: dashboard -> splash -> customize -> dashboard',
      (tester) async {
        final router = container.read(appRouterProvider);
        router.go('/');

        await tester.pumpWidget(buildTestApp(router));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);

        router.go('/splash');
        await tester.pumpAndSettle();
        expect(find.text('Splash'), findsOneWidget);

        router.go('/mascot/customize');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Personalizar Mascote'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );
  });
}
