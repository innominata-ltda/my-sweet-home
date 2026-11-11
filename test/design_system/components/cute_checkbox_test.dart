import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';

class _FakeMascotRepository implements MascotRepository {
  _FakeMascotRepository(this.config);

  MascotConfig config;

  @override
  Future<Result<MascotConfig, Failure>> loadConfig() async => Ok(config);

  @override
  Future<Result<Unit, Failure>> saveConfig(MascotConfig newConfig) async {
    config = newConfig;
    return const Ok(null);
  }

  @override
  Stream<MascotConfig> watchConfig() => Stream.value(config);
}

void main() {
  group('CuteCheckbox — SPEC-012 (RF-112, RN-280, CA-112.4)', () {
    testWidgets('displays paw icon when animal is cat or dog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteCheckbox(
                value: true,
                onChanged: null,
                animal: MascotAnimal.cat,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('cute_checkbox_icon_paw_true')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('displays heart icon when animal is rabbit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteCheckbox(
                value: true,
                onChanged: null,
                animal: MascotAnimal.bunny,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('cute_checkbox_icon_heart_true')),
        findsOneWidget,
      );
    });

    testWidgets('respects explicit CuteCheckboxShape regardless of animal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteCheckbox(
                value: false,
                onChanged: null,
                animal: MascotAnimal.bunny,
                shape: CuteCheckboxShape.paw,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('cute_checkbox_icon_paw_false')),
        findsOneWidget,
      );
    });

    testWidgets(
      'uses paw fallback (Momo cat default per CA-110.1) when unconfigured',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: CuteCheckbox(value: true, onChanged: null)),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey('cute_checkbox_icon_paw_true')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'resolves animal from mascotConfigStreamProvider (rabbit -> heart, cat -> paw)',
      (tester) async {
        final bunnyRepo = _FakeMascotRepository(
          MascotConfig.defaultMomo.copyWith(animal: MascotAnimal.bunny),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [mascotRepositoryProvider.overrideWithValue(bunnyRepo)],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(child: CuteCheckbox(value: true, onChanged: null)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('cute_checkbox_icon_heart_true')),
          findsOneWidget,
        );

        // Updates to cat and verifies dynamic update to paw
        final catRepo = _FakeMascotRepository(
          MascotConfig.defaultMomo.copyWith(animal: MascotAnimal.cat),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [mascotRepositoryProvider.overrideWithValue(catRepo)],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(child: CuteCheckbox(value: true, onChanged: null)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('cute_checkbox_icon_paw_true')),
          findsOneWidget,
        );
      },
    );

    testWidgets('performs elastic bounce animation on check', (tester) async {
      var isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: CuteCheckbox(
                    value: isChecked,
                    onChanged: (val) {
                      setState(() => isChecked = val);
                    },
                    shape: CuteCheckboxShape.heart,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final stateBefore = tester.state<CuteCheckboxState>(
        find.byType(CuteCheckbox),
      );
      expect(stateBefore.animationController.isAnimating, isFalse);

      // Toca para marcar
      await tester.tap(find.byType(CuteCheckbox));
      await tester.pump(); // Inicia o ticker

      final stateDuring = tester.state<CuteCheckboxState>(
        find.byType(CuteCheckbox),
      );
      expect(stateDuring.animationController.isAnimating, isTrue);

      // Advances to end of animation
      await tester.pump(const Duration(milliseconds: 450));
      expect(stateDuring.animationController.isAnimating, isFalse);
      expect(isChecked, isTrue);
    });

    testWidgets(
      'cuts immediately without animation when disableAnimations = true (CA-112.4, RN-290)',
      (tester) async {
        var isChecked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    return Center(
                      child: CuteCheckbox(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() => isChecked = val);
                        },
                        shape: CuteCheckboxShape.heart,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Toca para marcar
        await tester.tap(find.byType(CuteCheckbox));
        await tester.pump();

        final state = tester.state<CuteCheckboxState>(
          find.byType(CuteCheckbox),
        );
        // Controller must not be running continuous animation
        expect(state.animationController.isAnimating, isFalse);
        expect(isChecked, isTrue);
      },
    );

    testWidgets('meets minimum 48dp touch target guideline (A11Y-2)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CuteCheckbox(
                value: false,
                onChanged: (_) {},
                semanticLabel: 'Concluir tarefa',
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CuteCheckbox));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets(
      'has Semantics node with descriptive label and checked state (A11Y-3)',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CuteCheckbox(
                  value: true,
                  onChanged: (_) {},
                  semanticLabel: 'Item comprado: Arroz',
                ),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Item comprado: Arroz'), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'allows excludeSemantics when parent already manages accessibility',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Semantics(
                  label: 'Full row with own semantics',
                  child: const CuteCheckbox(
                    value: false,
                    onChanged: null,
                    excludeSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Full row with own semantics'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );
  });
}
