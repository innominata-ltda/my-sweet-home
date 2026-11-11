import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/soft_progress_bar.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

void main() {
  group('T-I04 / CA-003.4 & RN-292: Tokens de raio, sombras com glow e componentes', () {
    test('Radius tokens are correct: card 20dp, button 28dp, chip 16dp', () {
      expect(Radius.card, equals(20.0));
      expect(Radius.lg, equals(20.0));
      expect(Radius.button, equals(28.0));
      expect(Radius.chip, equals(16.0));
    });

    test(
      'AppShadows.softGlow generates soft shadow with provided primary color',
      () {
        const primaryColor = Color(0xFFE8A0BF);
        final shadows = AppShadows.softGlow(primaryColor);

        expect(shadows, isNotEmpty);
        expect(
          shadows.first.color,
          equals(primaryColor.withValues(alpha: 0.12)),
        );
        expect(shadows.first.blurRadius, equals(12.0));
        expect(shadows.first.offset, equals(const Offset(0, 4)));
      },
    );

    for (final palette in [
      AppPalette.rose,
      AppPalette.lavender,
      AppPalette.mint,
    ]) {
      group('Paleta ${palette.name}', () {
        testWidgets(
          'AppCard applies 20dp radius and shadow with primary color glow',
          (tester) async {
            final theme = lightTheme(palette.lightScheme);

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const Scaffold(
                  body: AppCard(child: Text('Card Content')),
                ),
              ),
            );

            final cardFinder = find.byType(Card);
            expect(cardFinder, findsOneWidget);

            final card = tester.widget<Card>(cardFinder);
            expect(card.shape, isA<RoundedRectangleBorder>());
            final border = card.shape as RoundedRectangleBorder;
            expect(border.borderRadius, equals(BorderRadius.circular(20.0)));

            // Verifies glow uses primary color of active palette
            expect(
              card.shadowColor,
              equals(palette.lightScheme.primary.withValues(alpha: 0.12)),
            );
          },
        );

        testWidgets(
          'AppButton applies 28dp radius and shadow with primary color glow',
          (tester) async {
            final theme = lightTheme(palette.lightScheme);

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: AppButton.primary(label: 'Confirmar', onPressed: () {}),
                ),
              ),
            );

            final buttonFinder = find.byType(ElevatedButton);
            expect(buttonFinder, findsOneWidget);

            final button = tester.widget<ElevatedButton>(buttonFinder);
            final style = button.style;
            final shape = style?.shape?.resolve({});
            expect(shape, isA<RoundedRectangleBorder>());
            final border = shape as RoundedRectangleBorder;
            expect(border.borderRadius, equals(BorderRadius.circular(28.0)));

            final shadowColor = style?.shadowColor?.resolve({});
            expect(
              shadowColor,
              equals(palette.lightScheme.primary.withValues(alpha: 0.35)),
            );
          },
        );

        testWidgets(
          'Chips theme applies 16dp radius and primary color glow shadow',
          (tester) async {
            final theme = lightTheme(palette.lightScheme);

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: ActionChip(
                    label: const Text('Chip Tag'),
                    onPressed: () {},
                  ),
                ),
              ),
            );

            expect(theme.chipTheme.shape, isA<RoundedRectangleBorder>());
            final border = theme.chipTheme.shape as RoundedRectangleBorder;
            expect(border.borderRadius, equals(BorderRadius.circular(16.0)));
            expect(
              theme.chipTheme.shadowColor,
              equals(palette.lightScheme.primary.withValues(alpha: 0.15)),
            );
          },
        );

        testWidgets(
          'SoftProgressBar renders with rounded corners, primary color, and glow',
          (tester) async {
            final theme = lightTheme(palette.lightScheme);

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const Scaffold(body: SoftProgressBar(value: 0.65)),
              ),
            );
            await tester.pumpAndSettle();

            final barFinder = find.byType(SoftProgressBar);
            expect(barFinder, findsOneWidget);

            // Verifica se Semantics anuncia valor correto
            final semanticsFinder = find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.value == '65%',
            );
            expect(semanticsFinder, findsOneWidget);

            // Verifies outer Container BoxDecoration has rounded borders and primary color glow
            final outerContainerFinder = find
                .descendant(of: barFinder, matching: find.byType(Container))
                .first;
            final outerContainer = tester.widget<Container>(
              outerContainerFinder,
            );
            final decoration = outerContainer.decoration as BoxDecoration;

            expect(
              decoration.borderRadius,
              equals(BorderRadius.circular(Radius.full)),
            );
            expect(decoration.boxShadow, isNotEmpty);
            expect(
              decoration.boxShadow?.first.color,
              equals(palette.lightScheme.primary.withValues(alpha: 0.25)),
            );
          },
        );

        testWidgets(
          'SoftProgressBar com disableAnimations renderiza corte seco imediato',
          (tester) async {
            final theme = lightTheme(palette.lightScheme);

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: const MediaQuery(
                  data: MediaQueryData(disableAnimations: true),
                  child: Scaffold(body: SoftProgressBar(value: 0.40)),
                ),
              ),
            );
            await tester.pump();

            expect(find.byType(SoftProgressBar), findsOneWidget);
            // With disableAnimations: true, there should be no TweenAnimationBuilder
            expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
          },
        );
      });
    }

    group('Edge cases e robustez', () {
      testWidgets(
        'SoftProgressBar with NaN value renders as 0% without throwing exception',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(body: SoftProgressBar(value: double.nan)),
            ),
          );
          await tester.pumpAndSettle();

          final semanticsFinder = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == '0%',
          );
          expect(semanticsFinder, findsOneWidget);
        },
      );

      testWidgets('SoftProgressBar clamp de valores < 0 e > 1.0', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SoftProgressBar(value: -0.5),
                  SoftProgressBar(value: 1.5),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == '0%',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == '100%',
          ),
          findsOneWidget,
        );
      });

      testWidgets('SoftProgressBar with hasGlow: false has no boxShadow', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SoftProgressBar(value: 0.5, hasGlow: false)),
          ),
        );
        await tester.pumpAndSettle();

        final containerFinder = find
            .descendant(
              of: find.byType(SoftProgressBar),
              matching: find.byType(Container),
            )
            .first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isEmpty);
      });

      testWidgets(
        'AppCard with hasGlow: false does not apply primary color glow',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: AppCard(hasGlow: false, child: Text('No glow')),
              ),
            ),
          );

          final cardFinder = find.byType(Card);
          final card = tester.widget<Card>(cardFinder);
          expect(card.shadowColor, isNull);
          expect(card.elevation, equals(0.0));
        },
      );

      testWidgets('AppCard e AppButton aceitam borderRadius customizado', (
        tester,
      ) async {
        final customCardRadius = BorderRadius.circular(10.0);
        final customButtonRadius = BorderRadius.circular(8.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppCard(
                    borderRadius: customCardRadius,
                    child: const Text('Card'),
                  ),
                  AppButton.primary(
                    label: 'Button',
                    borderRadius: customButtonRadius,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final card = tester.widget<Card>(find.byType(Card));
        final cardBorder = card.shape as RoundedRectangleBorder;
        expect(cardBorder.borderRadius, equals(customCardRadius));

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        final buttonBorder =
            button.style?.shape?.resolve({}) as RoundedRectangleBorder;
        expect(buttonBorder.borderRadius, equals(customButtonRadius));
      });
    });
  });
}
