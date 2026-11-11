import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/data/resolvers/mascot_asset_resolver_impl.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/pages/splash_screen.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

void main() {
  group('SPEC-012/T-04 — SplashScreen (RF-111, CA-111.1, CA-111.2, CA-111.3, RN-270..272)', () {
    late FakeMascotRepository fakeMascotRepo;

    setUp(() {
      fakeMascotRepo = FakeMascotRepository();
    });

    tearDown(() {
      fakeMascotRepo.dispose();
    });

    Widget buildSubject({
      Future<void> Function()? onInitialize,
      void Function(Object, StackTrace)? onError,
      void Function(BuildContext, String)? onTransition,
      String destination = '/',
      bool autoTransition = false,
      bool repeatAnimation = false,
      bool? disableAnimations,
      bool systemDisableAnimations = false,
      double textScaleFactor = 1.0,
      MascotAssetResolver? resolver,
      MascotConfig? config,
      String? semanticLabel,
    }) {
      return ProviderScope(
        overrides: [
          mascotRepositoryProvider.overrideWithValue(fakeMascotRepo),
          if (resolver != null)
            mascotAssetResolverProvider.overrideWithValue(resolver),
        ],
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
              disableAnimations: systemDisableAnimations,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: SplashScreen(
              onInitialize: onInitialize,
              onError: onError,
              onTransition: onTransition,
              destination: destination,
              autoTransition: autoTransition,
              repeatAnimation: repeatAnimation,
              disableAnimations: disableAnimations,
              resolver: resolver,
              config: config,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'CA-111.1 & RN-270: Exibe Momo visível, título "My Sweet Home" legível e fundo na cor do tema',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // 1. Title "My Sweet Home" visible
        expect(find.text('My Sweet Home'), findsOneWidget);

        // 2. Momo visible via MascotWidget
        expect(find.byType(MascotWidget), findsOneWidget);

        // 3. Fundo na cor de background da paleta ativa (RN-270)
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        final theme = lightTheme();
        expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);

        // 4. Accessible semantics for TalkBack
        final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
        expect(
          mascot.semanticLabel,
          'Momo, mascote acolhedora do My Sweet Home',
        );
        handle.dispose();
      },
    );

    testWidgets(
      'CA-111.1 & RN-271: Animação sutil de 2–3 frames progride com waving e happy',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );
        expect(state.isAnimating, isTrue);

        // Frame 0 (start): waving with neutral tilt
        expect(state.currentFrame, 0);
        expect(state.currentExpression, MascotExpression.waving);
        expect(state.currentTilt, 0.0);

        // Advance 400ms (1/3 duration): Frame 1 (happy with slight tilt)
        await tester.pump(const Duration(milliseconds: 450));
        expect(state.currentFrame, 1);
        expect(state.currentExpression, MascotExpression.happy);
        expect(state.currentTilt, -0.035);

        // Advance another 400ms: Frame 2 (waving with ear twitch to other side)
        await tester.pump(const Duration(milliseconds: 450));
        expect(state.currentFrame, 2);
        expect(state.currentExpression, MascotExpression.waving);
        expect(state.currentTilt, 0.035);

        // Conclui o ciclo suavemente
        await tester.pump(const Duration(milliseconds: 400));
        expect(state.animationController.isCompleted, isTrue);
      },
    );

    testWidgets(
      'CA-111.1: Fallback determinístico funciona quando asset Lottie de splash não existe',
      (tester) async {
        final resolverWithoutLottie = MascotAssetResolverImpl(
          knownAssets: {'assets/mascots/cat/happy.webp'},
        );

        await tester.pumpWidget(buildSubject(resolver: resolverWithoutLottie));
        await tester.pump();

        // Should not render Lottie, should render fallback MascotWidget
        expect(find.byType(LottieBuilder), findsNothing);
        expect(find.byType(MascotWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CA-111.1: Renderiza Lottie quando asset de splash estiver registrado e disponível',
      (tester) async {
        final resolverWithLottie = MascotAssetResolverImpl(
          knownAssets: {'assets/lottie/splash.json'},
        );

        await tester.pumpWidget(buildSubject(resolver: resolverWithLottie));
        await tester.pump();

        expect(find.byType(LottieBuilder), findsOneWidget);
      },
    );

    testWidgets(
      'CA-111.3 & RN-290: Com MediaQuery.disableAnimations = true, exibe frame estático sem iniciar AnimationController',
      (tester) async {
        await tester.pumpWidget(buildSubject(systemDisableAnimations: true));
        await tester.pump();

        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );

        // Controller MUST NOT be animating
        expect(state.isAnimating, isFalse);
        expect(state.animationController.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);

        // Static frame with happy expression and no tilt
        expect(state.currentExpression, MascotExpression.happy);
        expect(state.currentTilt, 0.0);
      },
    );

    testWidgets(
      'CA-111.3: Com widget.disableAnimations = true explícito, desativa animação de frames',
      (tester) async {
        await tester.pumpWidget(buildSubject(disableAnimations: true));
        await tester.pump();

        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );

        expect(state.isAnimating, isFalse);
        expect(state.animationController.isAnimating, isFalse);
        expect(state.currentExpression, MascotExpression.happy);
        expect(state.currentTilt, 0.0);
      },
    );

    testWidgets(
      'CA-111.2 & RN-272: Transição imediata após bootstrap sem atrasos artificiais fixos',
      (tester) async {
        final completer = Completer<void>();
        String? transitionedTo;

        await tester.pumpWidget(
          buildSubject(
            onInitialize: () => completer.future,
            onTransition: (context, dest) {
              transitionedTo = dest;
            },
            destination: '/',
          ),
        );
        await tester.pump();

        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );

        // While bootstrap is in progress, initialization is not complete
        expect(state.isInitialized, isFalse);
        expect(transitionedTo, isNull);

        // Bootstrap completa (ex: 50ms)
        completer.complete();
        await tester.pump();

        // Transition executed immediately upon completion
        expect(state.isInitialized, isTrue);
        expect(transitionedTo, '/');
      },
    );

    testWidgets(
      'CA-111.2: Transição para /onboarding quando configurada como destino',
      (tester) async {
        String? navigatedDestination;

        await tester.pumpWidget(
          buildSubject(
            autoTransition: true,
            destination: '/onboarding',
            onTransition: (context, dest) {
              navigatedDestination = dest;
            },
          ),
        );
        await tester.pump();

        expect(navigatedDestination, '/onboarding');
      },
    );

    testWidgets('A11Y: Suporte a textScaleFactor 2.0 sem overflow na Splash', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(textScaleFactor: 2.0));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('My Sweet Home'), findsOneWidget);
      expect(find.byType(MascotWidget), findsOneWidget);
    });

    testWidgets(
      'Robustness: Bootstrap failure captures error, triggers onError and shows Momo worried with retry',
      (tester) async {
        Object? capturedError;
        final errorException = Exception('Falha ao abrir banco Drift');

        await tester.pumpWidget(
          buildSubject(
            onInitialize: () => Future.error(errorException),
            onError: (err, st) {
              capturedError = err;
            },
          ),
        );
        await tester.pump();

        expect(capturedError, errorException);
        expect(tester.takeException(), isNull);

        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );
        expect(state.error, errorException);
        expect(state.currentExpression, MascotExpression.worried);

        expect(
          find.text('Ops! Ocorreu uma instabilidade na inicialização.'),
          findsOneWidget,
        );
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );

    testWidgets(
      'Robustez: Botão "Tentar novamente" recupera do erro ao reexecutar onInitialize',
      (tester) async {
        int attempts = 0;
        String? transitionedTo;

        await tester.pumpWidget(
          buildSubject(
            onInitialize: () async {
              attempts++;
              if (attempts == 1) {
                throw Exception('Erro temporário');
              }
            },
            onTransition: (context, dest) {
              transitionedTo = dest;
            },
          ),
        );
        await tester.pump();

        expect(attempts, 1);
        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(transitionedTo, isNull);

        // Toca em "Tentar novamente"
        await tester.tap(find.text('Tentar novamente'));
        await tester.pump();

        expect(attempts, 2);
        final state = tester.state<SplashScreenState>(
          find.byType(SplashScreen),
        );
        expect(state.error, isNull);
        expect(state.isInitialized, isTrue);
        expect(transitionedTo, '/');
      },
    );

    testWidgets(
      'A11Y: ExcludeSemantics impede que o identificador de teste "Splash" seja anunciado pelo TalkBack',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Widget exists in element tree for backward compatibility
        expect(find.text('Splash'), findsOneWidget);

        // But corresponding semantic node MUST NOT exist
        final semanticsNode = tester.getSemantics(find.text('Splash'));
        expect(semanticsNode.label, isEmpty);
        handle.dispose();
      },
    );

    testWidgets(
      'CA-110.3 & RN-289: Configuração com mascote personalizada reflete nome no semanticLabel',
      (tester) async {
        const customLuna = MascotConfig(
          animal: MascotAnimal.bunny,
          palette: MascotPalette.mint,
          accessory: MascotAccessory.scarf,
          name: 'Luna',
        );

        await tester.pumpWidget(buildSubject(config: customLuna));
        await tester.pump();

        final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
        expect(
          mascot.semanticLabel,
          'Luna, mascote acolhedora do My Sweet Home',
        );
      },
    );

    testWidgets(
      'Robustez: Transição sem GoRouter ou onTransition fornecidos degrada suavemente sem crash',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(autoTransition: true, destination: '/'),
        );
        await tester.pump();

        // Does not throw unhandled exception when executing _performTransition outside GoRouter
        expect(tester.takeException(), isNull);
      },
    );
  });
}
