import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

void main() {
  group('Mascot Animations & Accessibility (CA-290.1, RN-290, A11Y-7)', () {
    Widget buildTestApp({
      required Widget child,
      bool disableAnimations = false,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      );
    }

    testWidgets(
      'Construtor padrão (animateIdle: false) mantém quadro estático sem iniciar AnimationController',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: const MascotWidget(config: MascotConfig.defaultMomo),
          ),
        );
        await tester.pump();

        final state = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);
      },
    );

    testWidgets(
      'Quando animateIdle: true e animações habilitadas, o controlador executa ativamente',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: false,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
            ),
          ),
        );
        await tester.pump();

        final state = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state.isAnimating, isTrue);

        // Advance time and verify smooth animation progression
        await tester.pump(const Duration(milliseconds: 600));
        expect(state.animationController.value, greaterThan(0.0));
      },
    );

    testWidgets(
      'CA-290.1: Com MediaQuery.disableAnimations = true, a mascote aparece estática (sem CPU/GPU)',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: true,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
            ),
          ),
        );
        await tester.pump();

        final state = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);

        // Even advancing time, value remains 0.0
        await tester.pump(const Duration(seconds: 2));
        expect(state.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);
      },
    );

    testWidgets(
      'Parâmetro disableAnimations: true no widget força quadro estático mesmo se sistema permitir animação',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: false,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
              disableAnimations: true,
            ),
          ),
        );
        await tester.pump();

        final state = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);
      },
    );

    testWidgets(
      'Transição dinâmica de MediaQuery.disableAnimations pausa e retoma animação corretamente',
      (tester) async {
        // 1. Initialize with animations enabled
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: false,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
            ),
          ),
        );
        await tester.pump();

        final state = tester.state<MascotWidgetState>(
          find.byType(MascotWidget),
        );
        expect(state.isAnimating, isTrue);

        // 2. System disables animations (e.g. user enabled "remove animations" on Android)
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: true,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
            ),
          ),
        );
        await tester.pump();

        expect(state.isAnimating, isFalse);
        expect(state.animationController.value, 0.0);

        // 3. System re-enables animations
        await tester.pumpWidget(
          buildTestApp(
            disableAnimations: false,
            child: const MascotWidget.animated(
              config: MascotConfig.defaultMomo,
            ),
          ),
        );
        await tester.pump();

        expect(state.isAnimating, isTrue);
      },
    );
  });
}
