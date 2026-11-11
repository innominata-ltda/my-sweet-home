import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

void main() {
  group('Mascot Semantics & TalkBack (CA-289.1, RN-289, A11Y-3)', () {
    Widget buildTestApp({required Widget child}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets(
      'CA-289.1: TalkBack anuncia rótulo semântico contextual customizado em empty state',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        const customLabel =
            'Momo está pensativa — nenhuma despesa registrada ainda';

        await tester.pumpWidget(
          buildTestApp(
            child: const MascotWidget(
              config: MascotConfig.defaultMomo,
              expression: MascotExpression.thinking,
              semanticLabel: customLabel,
            ),
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel(customLabel), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'RN-289: Todas as 10 expressões geram descrições contextuais em pt-BR por padrão',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        final expectedDescriptions = <MascotExpression, String>{
          MascotExpression.neutral: 'Momo está te acompanhando com atenção',
          MascotExpression.happy: 'Momo está muito feliz com o seu progresso',
          MascotExpression.worried: 'Momo está com carinha de preocupação',
          MascotExpression.sleepy: 'Momo está com soninho e descansando',
          MascotExpression.pointing: 'Momo está apontando para esta seção',
          MascotExpression.waving: 'Momo está dando um oizinho carinhoso',
          MascotExpression.thinking: 'Momo está pensando com carinho',
          MascotExpression.relaxed: 'Momo está relaxando tranquilamente',
          MascotExpression.shopping: 'Momo está animada para as comprinhas',
          MascotExpression.budget: 'Momo está de olho no orçamento',
        };

        for (final entry in expectedDescriptions.entries) {
          await tester.pumpWidget(
            buildTestApp(
              child: MascotWidget(
                config: MascotConfig.defaultMomo,
                expression: entry.key,
              ),
            ),
          );
          await tester.pump();

          expect(
            find.bySemanticsLabel(entry.value),
            findsOneWidget,
            reason: 'Failure in semantics for expression ${entry.key.name}',
          );
        }

        handle.dispose();
      },
    );

    testWidgets('Semantic description uses custom mascot name', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      const customConfig = MascotConfig(
        animal: MascotAnimal.bunny,
        palette: MascotPalette.mint,
        accessory: MascotAccessory.scarf,
        name: 'Amora',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const MascotWidget(
            config: customConfig,
            expression: MascotExpression.happy,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('Amora está muito feliz com o seu progresso'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('isDecorative: true excludes mascot from semantics tree', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildTestApp(
          child: const MascotWidget(
            config: MascotConfig.defaultMomo,
            expression: MascotExpression.happy,
            isDecorative: true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('Momo está muito feliz com o seu progresso'),
        findsNothing,
      );

      handle.dispose();
    });

    testWidgets(
      'MascotWidget interativo com onTap expõe botão e ação de toque no TalkBack',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          buildTestApp(
            child: MascotWidget(
              config: MascotConfig.defaultMomo,
              expression: MascotExpression.neutral,
              onTap: () {},
            ),
          ),
        );
        await tester.pump();

        final semantics = tester
            .getSemantics(find.byType(MascotWidget))
            .getSemanticsData();
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(semantics.flagsCollection.isButton, isTrue);

        handle.dispose();
      },
    );
  });
}
