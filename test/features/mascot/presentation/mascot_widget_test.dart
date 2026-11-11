import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

class _FakeResolver implements MascotAssetResolver {
  final bool Function(MascotAnimal, MascotExpression)? hasAsset;

  const _FakeResolver({this.hasAsset});

  @override
  String get fallbackPlaceholderPath => 'assets/mascots/placeholder.webp';

  @override
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  ) {
    if (hasExpressionAsset(animal, expression)) {
      return 'assets/mascots/${animal.name}/${expression.name}.webp';
    }
    return fallbackPlaceholderPath;
  }

  @override
  String resolveAnimationPath(String animationName) =>
      'assets/lottie/$animationName.json';

  @override
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression) {
    return hasAsset?.call(animal, expression) ?? false;
  }

  @override
  bool hasAnimationAsset(String animationName) => false;
}

void main() {
  group('MascotWidget & MascotPlaceholder (CA-110.5, RF-110)', () {
    Widget buildTestHarness({required Widget child}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets(
      'CA-110.5: Falha ao carregar asset renderiza placeholder sem quebrar nem exibir erro',
      (tester) async {
        const resolver = _FakeResolver(hasAsset: null); // todos retornam false

        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              expression: MascotExpression.neutral,
              resolver: resolver,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MascotPlaceholder), findsOneWidget);
        expect(find.byKey(const Key('mascot_placeholder')), findsOneWidget);
        expect(find.byIcon(AppIcons.catPets), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Placeholder aplica cor da paleta ativa (Rose, Lavender, Mint)',
      (tester) async {
        for (final palette in MascotPalette.values) {
          final config = MascotConfig.defaultMomo.copyWith(palette: palette);
          final expectedColor = AppPalette.fromId(palette.name).seedColor;

          await tester.pumpWidget(
            buildTestHarness(
              child: MascotWidget(
                config: config,
                resolver: const _FakeResolver(hasAsset: null),
              ),
            ),
          );
          await tester.pump();

          final icon = tester.widget<Icon>(find.byIcon(AppIcons.catPets));
          expect(icon.color, equals(expectedColor));
        }
      },
    );

    testWidgets(
      'Placeholder exibe badge com nome do acessório quando configurado e com altura suficiente',
      (tester) async {
        const withBow = MascotConfig(
          animal: MascotAnimal.cat,
          palette: MascotPalette.rose,
          accessory: MascotAccessory.bow,
          name: 'Momo',
        );

        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: withBow,
              size: 80,
              resolver: _FakeResolver(hasAsset: null),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(MascotAccessory.bow.label), findsOneWidget);

        // When accessory is none, badge is not rendered
        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              size: 80,
              resolver: _FakeResolver(hasAsset: null),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(MascotAccessory.bow.label), findsNothing);
      },
    );

    testWidgets('Allows customization via placeholderBuilder', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: MascotWidget(
            config: MascotConfig.defaultMomo,
            resolver: const _FakeResolver(hasAsset: null),
            placeholderBuilder: (context, config, expression) {
              return const Text('Custom Mascot Placeholder');
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom Mascot Placeholder'), findsOneWidget);
      expect(find.byType(MascotPlaceholder), findsNothing);
    });

    testWidgets(
      'Applies dimensions via size and via independent width/height',
      (tester) async {
        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              size: 72,
              resolver: _FakeResolver(hasAsset: null),
            ),
          ),
        );
        await tester.pump();

        final containerFinder = find.byKey(const Key('mascot_placeholder'));
        final size72 = tester.getSize(containerFinder);
        expect(size72.width, 72);
        expect(size72.height, 72);

        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              width: 100,
              height: 50,
              resolver: _FakeResolver(hasAsset: null),
            ),
          ),
        );
        await tester.pump();

        final sizeCustom = tester.getSize(containerFinder);
        expect(sizeCustom.width, 100);
        expect(sizeCustom.height, 50);
      },
    );

    testWidgets('Dispara onTap quando tocado', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          child: MascotWidget(
            config: MascotConfig.defaultMomo,
            resolver: const _FakeResolver(hasAsset: null),
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(MascotWidget));
      expect(tapped, isTrue);
    });

    testWidgets('Sobrescreve atributos individuais sobre a config base', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const MascotWidget(
            config: MascotConfig.defaultMomo,
            animal: MascotAnimal.bunny,
            palette: MascotPalette.mint,
            accessory: MascotAccessory.scarf,
            name: 'Luna',
            resolver: _FakeResolver(hasAsset: null),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<MascotWidgetState>(find.byType(MascotWidget));
      expect(state.resolveConfig().animal, MascotAnimal.bunny);
      expect(state.resolveConfig().palette, MascotPalette.mint);
      expect(state.resolveConfig().accessory, MascotAccessory.scarf);
      expect(state.resolveConfig().name, 'Luna');
    });

    testWidgets(
      'Reage dinamicamente a mudanças no mascotConfigStreamProvider quando config é nula',
      (tester) async {
        final controller = StreamController<MascotConfig>.broadcast();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mascotConfigStreamProvider.overrideWith(
                (ref) => controller.stream,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: MascotWidget(resolver: _FakeResolver(hasAsset: null)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Initial default if stream has not emitted yet
        final state1 = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state1.resolveConfig().animal, MascotAnimal.cat);

        // Emit new config via stream
        const updatedConfig = MascotConfig(
          animal: MascotAnimal.dog,
          palette: MascotPalette.lavender,
          accessory: MascotAccessory.collar,
          name: 'Pipoca',
        );
        controller.add(updatedConfig);
        await tester.pump();

        final state2 = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state2.resolveConfig().animal, MascotAnimal.dog);
        expect(state2.resolveConfig().palette, MascotPalette.lavender);
        expect(state2.resolveConfig().name, 'Pipoca');

        await controller.close();
      },
    );

    testWidgets(
      'Lida graciosamente com tamanhos reduzidos (ex: size 16 ou 20) sem overflow',
      (tester) async {
        await tester.pumpWidget(
          buildTestHarness(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              size: 16,
              resolver: _FakeResolver(hasAsset: null),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Lida com restrições rígidas externas menores que 32 sem quebrar BoxConstraints',
      (tester) async {
        await tester.pumpWidget(
          buildTestHarness(
            child: const SizedBox(
              width: 20,
              height: 20,
              child: MascotWidget(
                config: MascotConfig.defaultMomo,
                resolver: _FakeResolver(hasAsset: null),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Não causa overflow com acessório e textScale 2.0 (CA-285.2, RNF-011)',
      (tester) async {
        const withBow = MascotConfig(
          animal: MascotAnimal.cat,
          palette: MascotPalette.rose,
          accessory: MascotAccessory.bow,
          name: 'Momo',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: const Scaffold(
                  body: Center(
                    child: MascotWidget(
                      config: withBow,
                      size: 64,
                      resolver: _FakeResolver(hasAsset: null),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'onTap expõe semântica de botão e ação de toque para leitores de tela',
      (tester) async {
        final handle = tester.ensureSemantics();
        var tapped = false;

        await tester.pumpWidget(
          buildTestHarness(
            child: MascotWidget(
              config: MascotConfig.defaultMomo,
              resolver: const _FakeResolver(hasAsset: null),
              onTap: () => tapped = true,
            ),
          ),
        );
        await tester.pump();

        final semantics = tester
            .getSemantics(find.byType(MascotWidget))
            .getSemanticsData();
        expect(
          semantics.hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'MascotWidget with onTap MUST have tap action in semantics',
        );
        expect(
          semantics.flagsCollection.isButton,
          isTrue,
          reason: 'MascotWidget with onTap MUST be announced as button',
        );

        await tester.tap(find.byType(MascotWidget));
        expect(tapped, isTrue);

        handle.dispose();
      },
    );
  });
}
