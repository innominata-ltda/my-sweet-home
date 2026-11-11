import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/app/app.dart';
import 'package:my_sweet_home/app/error_boundary.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';

/// Deterministic HttpOverrides blocking all network attempts,
/// simulating device airplane mode (offline first-run flow).
class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Airplane mode active: network requests are blocked in offline test environment',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Configure global network interceptor to throw SocketException in airplane mode
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group(
    'First run onboarding experience in offline airplane mode',
    () {
      test('HttpOverrides blocks network connections with SocketException', () {
        expect(
          () => HttpClient().openUrl(
            'GET',
            Uri.parse('https://innominata.com.br'),
          ),
          throwsA(isA<SocketException>()),
        );
      });

      testWidgets(
        'First run opens onboarding, allows skip, and navigates to Dashboard offline',
        (tester) async {
          final originalBuilder = ErrorWidget.builder;
          final db = AppDatabase.memory();
          final container = ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(db)],
          );

          try {
            setupGlobalErrorHandling();

            final router = container.read(appRouterProvider);
            router.go('/onboarding');

            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: const MySweetHomeApp(),
              ),
            );
            await tester.pumpAndSettle();

            // 1. Verify Onboarding is displayed on first run
            expect(find.byType(OnboardingPage), findsOneWidget);
            expect(find.text('Boas-vindas'), findsOneWidget);
            expect(find.text('Organize suas finanças'), findsOneWidget);

            // 2. Ensure no personal data entry fields are shown
            expect(find.byType(TextField), findsNothing);
            expect(find.byType(TextFormField), findsNothing);
            expect(find.byType(EditableText), findsNothing);

            // 3. Locate Skip button
            final skipButton = find.byKey(const Key('onboarding_skip_button'));
            expect(skipButton, findsOneWidget);
            expect(find.text('Pular'), findsOneWidget);

            // 4. Tap Skip
            await tester.tap(skipButton);
            await tester.pumpAndSettle();

            // 5. Verify onboarding closed and Dashboard rendered
            expect(find.byType(OnboardingPage), findsNothing);
            expect(find.text('My Sweet Home'), findsOneWidget);
          } finally {
            container.dispose();
            await db.close();
            ErrorWidget.builder = originalBuilder;
          }
        },
      );

      testWidgets(
        'First run advances across steps and completes onboarding to Dashboard',
        (tester) async {
          final originalBuilder = ErrorWidget.builder;
          final db = AppDatabase.memory();
          final container = ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(db)],
          );

          try {
            setupGlobalErrorHandling();

            final router = container.read(appRouterProvider);
            router.go('/onboarding');

            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: const MySweetHomeApp(),
              ),
            );
            await tester.pumpAndSettle();

            // Step 1 -> Step 2
            await tester.tap(find.byKey(const Key('onboarding_next_button')));
            await tester.pumpAndSettle();
            expect(find.text('Controle'), findsOneWidget);

            // Step 2 -> Step 3
            await tester.tap(find.byKey(const Key('onboarding_next_button')));
            await tester.pumpAndSettle();
            expect(find.text('Pronto!'), findsOneWidget);

            // Tap Start button
            await tester.tap(find.byKey(const Key('onboarding_start_button')));
            await tester.pumpAndSettle();

            // Verify arrival at Dashboard
            expect(find.byType(OnboardingPage), findsNothing);
            expect(find.text('My Sweet Home'), findsOneWidget);
          } finally {
            container.dispose();
            await db.close();
            ErrorWidget.builder = originalBuilder;
          }
        },
      );
    },
  );
}
