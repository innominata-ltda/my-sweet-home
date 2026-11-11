import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? lightTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppEmptyState (RF-110, CA-110.6, CA-289.1)', () {
    testWidgets('renders default icon and texts when used without mascot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            title: 'Nenhum item',
            description: 'Your list is empty.',
            icon: AppIcons.info,
          ),
        ),
      );

      expect(find.byIcon(AppIcons.info), findsOneWidget);
      expect(find.text('Nenhum item'), findsOneWidget);
      expect(find.text('Your list is empty.'), findsOneWidget);
      expect(find.byType(MascotWidget), findsNothing);
    });

    testWidgets('renders custom illustration with precedence over icon', (
      tester,
    ) async {
      const illustrationKey = Key('custom_illustration');
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            title: 'Custom illustration',
            illustration: SizedBox(key: illustrationKey, width: 80, height: 80),
          ),
        ),
      );

      expect(find.byKey(illustrationKey), findsOneWidget);
      expect(find.text('Custom illustration'), findsOneWidget);
      expect(find.byIcon(AppIcons.info), findsNothing);
    });

    testWidgets(
      'AppEmptyState.mascot renders MascotWidget with provided expression',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const AppEmptyState.mascot(
              title: 'No expenses this month.',
              description:
                  'No expenses this month. How about logging the first one?',
              mascotExpression: MascotExpression.thinking,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MascotWidget), findsOneWidget);
        expect(find.text('No expenses this month.'), findsOneWidget);
        expect(
          find.text('No expenses this month. How about logging the first one?'),
          findsOneWidget,
        );

        final mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget),
        );
        expect(mascotWidget.expression, MascotExpression.thinking);
      },
    );

    testWidgets(
      'CA-289.1: TalkBack announces contextual Momo semantics in empty state',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        const customSemanticLabel =
            'Momo is thoughtful — no expense recorded yet';

        await tester.pumpWidget(
          _wrap(
            const AppEmptyState.mascot(
              title: 'No expenses this month.',
              description: 'How about logging the first one?',
              mascotExpression: MascotExpression.thinking,
              mascotSemanticLabel: customSemanticLabel,
            ),
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel(customSemanticLabel), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'AppEmptyState.mascot for empty shopping with shopping expression',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        const shoppingLabel =
            'Momo pronta para as compras — nenhuma listinha criada ainda';

        await tester.pumpWidget(
          _wrap(
            const AppEmptyState.mascot(
              title: 'Your list is empty',
              description:
                  'Add items so you do not forget anything at the market.',
              mascotExpression: MascotExpression.shopping,
              mascotSemanticLabel: shoppingLabel,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MascotWidget), findsOneWidget);
        final mascotWidget = tester.widget<MascotWidget>(
          find.byType(MascotWidget),
        );
        expect(mascotWidget.expression, MascotExpression.shopping);
        expect(find.bySemanticsLabel(shoppingLabel), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'AppEmptyState triggers action callback (onAction / actionLabel)',
      (tester) async {
        var actionClicked = false;
        await tester.pumpWidget(
          _wrap(
            AppEmptyState.mascot(
              title: 'Lista vazia',
              actionLabel: 'Criar item',
              onAction: () => actionClicked = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Criar item'), findsOneWidget);
        await tester.tap(find.text('Criar item'));
        expect(actionClicked, isTrue);
      },
    );

    testWidgets('supports textScale 2.0 without rendering overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Center(
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(2.0),
                  ),
                  child: const AppEmptyState.mascot(
                    title: 'Nenhuma despesa registrada',
                    description: 'Long descriptive text to verify accessibility stability with scaled text factor.',
                    mascotExpression: MascotExpression.thinking,
                    actionLabel: 'Log first expense',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
