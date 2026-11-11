import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_step.dart';

Widget _buildSubject({VoidCallback? onComplete}) {
  return ProviderScope(
    child: MaterialApp(home: OnboardingPage(onComplete: onComplete)),
  );
}

void main() {
  group('T-05 / SPEC-012 — Onboarding (RF-009, RN-012, RN-273..278, CA-009.1..009.4)', () {
    testWidgets('Renderiza 7 telas no PageView guiadas pela Momo', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      final pageView = tester.widget<PageView>(pageViewFinder);
      final delegate = pageView.childrenDelegate as SliverChildListDelegate;
      expect(delegate.children.length, equals(8));

      // Screen 1 is visible initially
      expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);
      expect(
        find.text(
          'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Displays page indicator with 8 dots', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_indicator')), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        expect(find.byKey(Key('page_indicator_dot_$i')), findsOneWidget);
      }
    });

    testWidgets('Skip button is present and works (calls onComplete)', (
      tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(
        _buildSubject(onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      final skipButton = find.byKey(const Key('onboarding_skip_button'));
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Skip button is present on all 8 screens', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _buildSubject(onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 8; i++) {
        expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
        if (i < 7) {
          await tester.tap(find.text('Próximo'));
          await tester.pumpAndSettle();
        }
      }

      // Tapping Skip on Screen 8 also completes
      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('Next button advances to the next screen', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Initially on Screen 1
      expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Now on Screen 2
      expect(
        find.text('Aqui a gente cuida do dinheirinho juntas'),
        findsOneWidget,
      );
    });

    testWidgets('On the last screen, button is Comecar', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Advances through the first 7 screens (0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7)
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      // On Screen 8
      expect(
        find.text('Pode personalizar meu visual quando quiser!'),
        findsOneWidget,
      );
      expect(find.text('Próximo'), findsNothing);
      expect(find.text('Começar'), findsOneWidget);
    });

    testWidgets('Start button calls onComplete', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        _buildSubject(onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      // Advances to the last screen
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      // Tap Start
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('No text field, form, or personal data input is present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      void assertNoInputs(int step) {
        // Step 6 (index 5: routine) has suggestion search, but no personal data input (RN-012/RN-365)
        if (step != 5) {
          expect(find.byType(TextField), findsNothing);
        }
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(Form), findsNothing);
      }

      for (var i = 0; i < 7; i++) {
        assertNoInputs(i);
        if (i < 6) {
          await tester.tap(find.text('Próximo'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('OnboardingStep renders legacy icon, title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingStep(
              icon: AppIcons.home,
              title: 'Título de Teste',
              subtitle: 'Subtítulo explicativo de teste',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.home), findsOneWidget);
      expect(find.text('Título de Teste'), findsOneWidget);
      expect(find.text('Subtítulo explicativo de teste'), findsOneWidget);
    });

    testWidgets('OnboardingStep renders Momo expression', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OnboardingStep(
                expression: MascotExpression.happy,
                title: 'Título Feliz',
                subtitle: 'Momo está feliz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Título Feliz'), findsOneWidget);
      expect(find.text('Momo está feliz'), findsOneWidget);
    });

    testWidgets('When onComplete is not provided, Skip navigates to /', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Destination')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      final skipButton = find.byKey(const Key('onboarding_skip_button'));
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });

    testWidgets('When onComplete is not provided, Start navigates to /', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Destination')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Começar'), findsOneWidget);
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });
  });
}
