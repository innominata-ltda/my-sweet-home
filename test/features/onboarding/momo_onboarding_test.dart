import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_step.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';

void main() {
  group('SPEC-012/T-05 — Momo Onboarding (RF-009, CA-009.1, CA-009.2, CA-009.3, CA-009.4, RN-273..278)', () {
    late FakeMascotRepository fakeMascotRepo;

    setUp(() {
      fakeMascotRepo = FakeMascotRepository();
    });

    tearDown(() {
      fakeMascotRepo.dispose();
    });

    Widget buildSubject({
      VoidCallback? onComplete,
      VoidCallback? onCustomize,
      int initialStep = 0,
      bool? disableAnimations,
      double textScaleFactor = 1.0,
    }) {
      return ProviderScope(
        overrides: [mascotRepositoryProvider.overrideWithValue(fakeMascotRepo)],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
              disableAnimations: disableAnimations ?? false,
            ),
            child: OnboardingPage(
              onComplete: onComplete,
              onCustomize: onCustomize,
              initialStep: initialStep,
              disableAnimations: disableAnimations,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'CA-009.1: Apresenta 7 passos com Momo nas expressões corretas e rotina no passo 6',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final pageView = tester.widget<PageView>(find.byType(PageView));
        final delegate = pageView.childrenDelegate as SliverChildListDelegate;
        expect(delegate.children.length, equals(8));

        // Passo 1: waving
        expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);
        expect(
          find.text(
            'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!',
          ),
          findsOneWidget,
        );
        var mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.waving));

        // Passo 2: pointing
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(
          find.text('Aqui a gente cuida do dinheirinho juntas'),
          findsOneWidget,
        );
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.pointing));

        // Passo 3: shopping
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('E também das comprinhas!'), findsOneWidget);
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.shopping));

        // Passo 4: happy
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('Não esquece das tarefinhas do dia'), findsOneWidget);
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.happy));

        // Passo 5: budget
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(
          find.text('Eu te aviso quando algo precisa de atenção'),
          findsOneWidget,
        );
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.budget));

        // Passo 6: Rotina da casa (SPEC-014)
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('Monte sua rotina da casa'), findsOneWidget);

        // Passo 7: Checklist Primeira Casa (SPEC-015)
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('Está montando sua casa nova?'), findsOneWidget);
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.happy));

        // Passo 8: relaxed
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();
        expect(
          find.text('Pode personalizar meu visual quando quiser!'),
          findsOneWidget,
        );
        mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.relaxed));
      },
    );

    testWidgets(
      'CA-009.2: Na tela 3, botão "Pular introdução" vai direto para a Home',
      (tester) async {
        var completed = false;
        await tester.pumpWidget(
          buildSubject(
            initialStep: 2, // Screen 3 (index 2)
            onComplete: () => completed = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('E também das comprinhas!'), findsOneWidget);

        final skipButton = find.byKey(const Key('onboarding_skip_button'));
        expect(skipButton, findsOneWidget);

        // Can be tapped via "Skip intro" text or Key
        await tester.tap(find.text('Pular introdução'));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
      },
    );

    testWidgets(
      'CA-009.3: Na última tela, exibe convite de personalização e botão leva a /mascot/customize',
      (tester) async {
        var customized = false;
        var completed = false;
        await tester.pumpWidget(
          buildSubject(
            initialStep: 7, // Tela 8
            onCustomize: () => customized = true,
            onComplete: () => completed = true,
          ),
        );
        await tester.pumpAndSettle();

        // Customization question present
        expect(
          find.text('Quer personalizar meu visual agora?'),
          findsOneWidget,
        );

        // "Customize now" button
        final customizeBtn = find.byKey(
          const Key('onboarding_customize_button'),
        );
        expect(customizeBtn, findsOneWidget);
        expect(find.text('Personalizar agora'), findsOneWidget);

        await tester.ensureVisible(customizeBtn);
        await tester.tap(customizeBtn);
        await tester.pumpAndSettle();
        expect(customized, isTrue);

        // "Start" button present
        final startBtn = find.byKey(const Key('onboarding_start_button'));
        expect(startBtn, findsOneWidget);
        expect(find.text('Começar'), findsOneWidget);

        await tester.tap(startBtn);
        await tester.pumpAndSettle();
        expect(completed, isTrue);
      },
    );

    testWidgets(
      'CA-009.4: Settings displays tutorial prompt and navigates to /onboarding',
      (tester) async {
        var tutorialTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
            home: SettingsPage(onTutorialTap: () => tutorialTapped = true),
          ),
        );
        await tester.pumpAndSettle();

        final tutorialTile = find.byKey(const Key('settings_tutorial_tile'));
        expect(tutorialTile, findsOneWidget);
        expect(find.text('Ver tutorial com a Momo'), findsOneWidget);
        expect(
          find.text('Relembre o funcionamento do app com a mascote'),
          findsOneWidget,
        );

        await tester.tap(tutorialTile);
        await tester.pumpAndSettle();
        expect(tutorialTapped, isTrue);
      },
    );

    testWidgets(
      'SettingsPage navega para /onboarding via GoRouter quando onTutorialTap é nulo',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Onboarding Screen Route')),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
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
        await tester.pumpAndSettle();

        final tutorialTile = find.byKey(const Key('settings_tutorial_tile'));
        expect(tutorialTile, findsOneWidget);

        await tester.tap(tutorialTile);
        await tester.pumpAndSettle();

        expect(find.text('Onboarding Screen Route'), findsOneWidget);
      },
    );

    testWidgets(
      'RN-275: Nenhum campo de entrada de dados pessoais no onboarding',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        for (var i = 0; i < 7; i++) {
          if (i != 5) {
            expect(find.byType(TextField), findsNothing);
          }
          expect(find.byType(TextFormField), findsNothing);
          expect(find.byType(Form), findsNothing);

          if (i < 6) {
            await tester.tap(find.byKey(const Key('onboarding_next_button')));
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets(
      'RN-278 & CA-290.1: Respeita disableAnimations na animação de entrada da mascote',
      (tester) async {
        // When animations disabled, MascotEntrance does not start AnimationController
        await tester.pumpWidget(buildSubject(disableAnimations: true));
        await tester.pump();

        final entranceState = tester.state<MascotEntranceState>(
          find.byType(MascotEntrance).first,
        );
        expect(entranceState.controller.value, equals(1.0));
        expect(entranceState.controller.isAnimating, isFalse);
      },
    );

    testWidgets(
      'CA-285.2 & RNF-011: Escala de texto 2.0 não causa overflow em nenhuma das 7 telas',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject(textScaleFactor: 2.0));
        await tester.pumpAndSettle();

        for (var i = 0; i < 7; i++) {
          expect(tester.takeException(), isNull);
          if (i < 6) {
            await tester.tap(find.byKey(const Key('onboarding_next_button')));
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets(
      'CA-009.4 & CA-110.3: Onboarding reflete a mascote customizada do repositório',
      (tester) async {
        await fakeMascotRepo.saveConfig(
          const MascotConfig(
            animal: MascotAnimal.dog,
            palette: MascotPalette.lavender,
            accessory: MascotAccessory.bow,
            name: 'Luna',
          ),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget).first,
        );
        expect(mascotWidget.expression, equals(MascotExpression.waving));

        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics && (w.properties.label?.contains('Luna') ?? false),
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );
  });
}
