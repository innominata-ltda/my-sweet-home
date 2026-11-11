import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_controller.dart';
import 'package:my_sweet_home/features/mascot/presentation/pages/mascot_customization_page.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';

class _FakeResolver implements MascotAssetResolver {
  const _FakeResolver();

  @override
  String get fallbackPlaceholderPath => 'assets/mascots/placeholder.webp';

  @override
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  ) => fallbackPlaceholderPath;

  @override
  String resolveAnimationPath(String animationName) =>
      'assets/lottie/$animationName.json';

  @override
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression) =>
      false;

  @override
  bool hasAnimationAsset(String animationName) => false;
}

class _DelayedMascotRepository implements MascotRepository {
  final Completer<Result<MascotConfig, Failure>> completer;
  _DelayedMascotRepository(this.completer);

  @override
  Future<Result<MascotConfig, Failure>> loadConfig() => completer.future;

  @override
  Future<Result<Unit, Failure>> saveConfig(MascotConfig config) async =>
      const Ok(null);

  @override
  Stream<MascotConfig> watchConfig() => Stream.value(MascotConfig.defaultMomo);
}

void main() {
  group('MascotCustomizationPage (RF-110, CA-110.2, CA-110.4, RN-263)', () {
    late FakeMascotRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeMascotRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    void setScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget buildHarness({
      required Widget child,
      MascotCustomizationController? controller,
    }) {
      return ProviderScope(
        overrides: [mascotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          home: child,
        ),
      );
    }

    testWidgets('Renders initial state with default mascot Momo Rose', (
      tester,
    ) async {
      setScreenSize(tester);
      final controller = MascotCustomizationController(
        repository: fakeRepo,
        initialConfig: MascotConfig.defaultMomo,
      );

      await tester.pumpWidget(
        buildHarness(
          child: MascotCustomizationPage(
            controller: controller,
            resolver: const _FakeResolver(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personalizar Mascote'), findsOneWidget);
      expect(find.byKey(const Key('mascot_preview_name')), findsOneWidget);
      expect(find.text('Momo'), findsWidgets);
      expect(find.text('Gato · Rose · Nenhum'), findsOneWidget);

      controller.dispose();
    });

    testWidgets(
      'Carrega com sucesso a partir do Riverpod quando controller não é injetado (sem loading infinito)',
      (tester) async {
        setScreenSize(tester);

        await tester.pumpWidget(
          buildHarness(
            child: const MascotCustomizationPage(resolver: _FakeResolver()),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mascot_loading')), findsNothing);
        expect(find.text('Personalizar Mascote'), findsOneWidget);
        expect(find.byKey(const Key('mascot_preview_name')), findsOneWidget);
        expect(find.text('Momo'), findsWidgets);
      },
    );

    testWidgets(
      'CA-110.2: Seleção de cachorro + Lavender + lacinho atualiza o preview em tempo real',
      (tester) async {
        setScreenSize(tester);
        final controller = MascotCustomizationController(
          repository: fakeRepo,
          initialConfig: MascotConfig.defaultMomo,
        );

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Seleciona animal cachorro
        final dogChip = find.byKey(const Key('mascot_animal_dog'));
        await tester.ensureVisible(dogChip);
        await tester.tap(dogChip);
        await tester.pump();

        // 2. Seleciona paleta Lavender
        final lavenderChip = find.byKey(const Key('mascot_palette_lavender'));
        await tester.ensureVisible(lavenderChip);
        await tester.tap(lavenderChip);
        await tester.pump();

        // 3. Select bow accessory and measure update time (< 200ms)
        final stopwatch = Stopwatch()..start();
        final bowChip = find.byKey(const Key('mascot_accessory_bow'));
        await tester.ensureVisible(bowChip);
        await tester.tap(bowChip);
        await tester.pump();
        stopwatch.stop();

        // CA-110.2: Real-time preview update (< 200ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(200));

        // Verifica que o preview reflete Cachorro · Lavender · Lacinho
        expect(find.text('Cachorro · Lavender · Lacinho'), findsOneWidget);
        expect(controller.state.animal, equals(MascotAnimal.dog));
        expect(controller.state.palette, equals(MascotPalette.lavender));
        expect(controller.state.accessory, equals(MascotAccessory.bow));

        controller.dispose();
      },
    );

    testWidgets(
      'Edição do campo de texto de nome atualiza o preview e aceita renomear',
      (tester) async {
        setScreenSize(tester);
        final controller = MascotCustomizationController(
          repository: fakeRepo,
          initialConfig: MascotConfig.defaultMomo,
        );

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nameField = find.byKey(const Key('mascot_name_field'));
        await tester.ensureVisible(nameField);

        // Digita um novo nome
        await tester.enterText(nameField, 'Bisteca');
        await tester.pump();

        expect(find.text('Bisteca'), findsWidgets);
        expect(controller.state.name, equals('Bisteca'));

        // Limpa o campo de texto para verificar fallback para "Momo"
        await tester.enterText(nameField, '');
        await tester.pump();

        expect(controller.state.displayName, equals('Momo'));

        controller.dispose();
      },
    );

    testWidgets(
      'CA-110.4: Toque em Cancelar restaura valores anteriores e não salva no repositório',
      (tester) async {
        setScreenSize(tester);
        bool canceledCalled = false;
        final controller = MascotCustomizationController(
          repository: fakeRepo,
          initialConfig: MascotConfig.defaultMomo,
        );

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
              onCanceled: () {
                canceledCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Altera animal para coelho e paleta para Mint
        final bunnyChip = find.byKey(const Key('mascot_animal_bunny'));
        await tester.ensureVisible(bunnyChip);
        await tester.tap(bunnyChip);

        final mintChip = find.byKey(const Key('mascot_palette_mint'));
        await tester.ensureVisible(mintChip);
        await tester.tap(mintChip);

        final nameField = find.byKey(const Key('mascot_name_field'));
        await tester.ensureVisible(nameField);
        await tester.enterText(nameField, 'Amora');
        await tester.pump();

        expect(find.text('Coelho · Mint · Nenhum'), findsOneWidget);
        expect(find.text('Amora'), findsWidgets);

        // Tap Cancel button
        final cancelButton = find.byKey(const Key('mascot_cancel_button'));
        await tester.ensureVisible(cancelButton);
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        expect(canceledCalled, isTrue);

        // Verifica que o estado voltou ao original
        expect(controller.state, equals(MascotConfig.defaultMomo));
        expect(find.text('Gato · Rose · Nenhum'), findsOneWidget);
        expect(find.text('Momo'), findsWidgets);

        // Verify repository retains original values
        final repoResult = await fakeRepo.loadConfig();
        expect(repoResult.isOk, isTrue);
        expect(
          (repoResult as Ok<MascotConfig, Failure>).value,
          equals(MascotConfig.defaultMomo),
        );

        controller.dispose();
      },
    );

    testWidgets(
      'Salvar persiste nova configuração e exibe SnackBar de sucesso',
      (tester) async {
        setScreenSize(tester);
        bool savedCalled = false;
        final controller = MascotCustomizationController(
          repository: fakeRepo,
          initialConfig: MascotConfig.defaultMomo,
        );

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
              onSaved: () {
                savedCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select rabbit, mint, scarf, "Luna"
        final bunnyChip = find.byKey(const Key('mascot_animal_bunny'));
        await tester.ensureVisible(bunnyChip);
        await tester.tap(bunnyChip);

        final mintChip = find.byKey(const Key('mascot_palette_mint'));
        await tester.ensureVisible(mintChip);
        await tester.tap(mintChip);

        final scarfChip = find.byKey(const Key('mascot_accessory_scarf'));
        await tester.ensureVisible(scarfChip);
        await tester.tap(scarfChip);

        final nameField = find.byKey(const Key('mascot_name_field'));
        await tester.ensureVisible(nameField);
        await tester.enterText(nameField, 'Luna');
        await tester.pump();

        // Toca em Salvar
        final saveButton = find.byKey(const Key('mascot_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(savedCalled, isTrue);
        expect(find.text('Personalização salva com carinho!'), findsOneWidget);

        // Verify configuration was saved in repository
        final repoResult = await fakeRepo.loadConfig();
        expect(repoResult.isOk, isTrue);
        final saved = (repoResult as Ok<MascotConfig, Failure>).value;
        expect(saved.animal, equals(MascotAnimal.bunny));
        expect(saved.palette, equals(MascotPalette.mint));
        expect(saved.accessory, equals(MascotAccessory.scarf));
        expect(saved.name, equals('Luna'));

        controller.dispose();
      },
    );

    testWidgets('Exibe indicador de carregamento no estado Loading', (
      tester,
    ) async {
      setScreenSize(tester);
      final completer = Completer<Result<MascotConfig, Failure>>();
      final delayedRepo = _DelayedMascotRepository(completer);
      final controller = MascotCustomizationController(repository: delayedRepo);

      await tester.pumpWidget(
        buildHarness(
          child: MascotCustomizationPage(
            controller: controller,
            resolver: const _FakeResolver(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('mascot_loading')), findsOneWidget);

      completer.complete(const Ok(MascotConfig.defaultMomo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mascot_loading')), findsNothing);
      expect(find.byKey(const Key('mascot_preview_card')), findsOneWidget);

      controller.dispose();
    });

    testWidgets(
      'Exibe tela de erro e botão "Tentar de novo" quando o carregamento falha',
      (tester) async {
        setScreenSize(tester);
        fakeRepo.shouldFail = true;
        final controller = MascotCustomizationController(repository: fakeRepo);

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mascot_error_view')), findsOneWidget);
        expect(find.byKey(const Key('mascot_retry_button')), findsOneWidget);

        // Simulate error resolution and tap retry button
        fakeRepo.shouldFail = false;
        await tester.tap(find.byKey(const Key('mascot_retry_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mascot_preview_card')), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets(
      'Acessibilidade: Chips de seleção e botões possuem altura de toque >= 48dp',
      (tester) async {
        setScreenSize(tester);
        final controller = MascotCustomizationController(
          repository: fakeRepo,
          initialConfig: MascotConfig.defaultMomo,
        );

        await tester.pumpWidget(
          buildHarness(
            child: MascotCustomizationPage(
              controller: controller,
              resolver: const _FakeResolver(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify action button height
        final saveSize = tester.getSize(
          find.byKey(const Key('mascot_save_button')),
        );
        expect(saveSize.height, greaterThanOrEqualTo(48.0));

        final cancelSize = tester.getSize(
          find.byKey(const Key('mascot_cancel_button')),
        );
        expect(cancelSize.height, greaterThanOrEqualTo(48.0));

        // Verify minimum height of animal chips
        for (final animal in MascotAnimal.values) {
          final chipSize = tester.getSize(
            find.byKey(Key('mascot_animal_${animal.name}')),
          );
          expect(chipSize.height, greaterThanOrEqualTo(48.0));
        }

        controller.dispose();
      },
    );

    testWidgets(
      'SettingsPage exibe atalho "Personalizar Momo" e permite navegação',
      (tester) async {
        setScreenSize(tester);
        bool mascotTapped = false;

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
            home: SettingsPage(
              onMascotTap: () {
                mascotTapped = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings_mascot_tile')), findsOneWidget);
        expect(find.text('Personalizar Momo'), findsOneWidget);

        await tester.tap(find.byKey(const Key('settings_mascot_tile')));
        await tester.pumpAndSettle();

        expect(mascotTapped, isTrue);
      },
    );

    testWidgets(
      'SettingsPage with null onMascotTap navigates to /mascot/customize via GoRouter',
      (tester) async {
        setScreenSize(tester);

        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/mascot/customize',
              builder: (context, state) =>
                  const Scaffold(body: Text('Personalizar Mascote Route')),
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

        expect(find.byKey(const Key('settings_mascot_tile')), findsOneWidget);
        await tester.tap(find.byKey(const Key('settings_mascot_tile')));
        await tester.pumpAndSettle();

        expect(find.text('Personalizar Mascote Route'), findsOneWidget);
      },
    );
  });
}
