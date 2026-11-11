import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';

void main() {
  group(
    'T-I04 / CA-285.1 & RN-285 & RN-286: Tipografia Nunito com fallback seguro',
    () {
      test(
        'lightTheme e darkTheme configuram Nunito como fontFamily principal',
        () {
          final light = lightTheme();
          final dark = darkTheme();

          expect(light.textTheme.bodyMedium?.fontFamily, equals('Nunito'));
          expect(dark.textTheme.bodyMedium?.fontFamily, equals('Nunito'));
        },
      );

      test('lightTheme e darkTheme declaram fontFamilyFallback seguro para fonte do sistema (RN-286)', () {
        final light = lightTheme();
        final dark = darkTheme();

        expect(light.textTheme.bodyMedium?.fontFamilyFallback, isNotNull);
        expect(
          light.textTheme.bodyMedium?.fontFamilyFallback,
          containsAll(['Roboto', 'sans-serif']),
        );

        expect(dark.textTheme.bodyMedium?.fontFamilyFallback, isNotNull);
        expect(
          dark.textTheme.bodyMedium?.fontFamilyFallback,
          containsAll(['Roboto', 'sans-serif']),
        );
      });

      test('RN-285: Titles use weight 700 (FontWeight.w700)', () {
        final textTheme = lightTheme().textTheme;

        final titleStyles = [
          textTheme.displayLarge,
          textTheme.displayMedium,
          textTheme.displaySmall,
          textTheme.headlineLarge,
          textTheme.headlineMedium,
          textTheme.headlineSmall,
          textTheme.titleLarge,
          textTheme.titleMedium,
          textTheme.titleSmall,
        ];

        for (final style in titleStyles) {
          expect(style, isNotNull);
          expect(
            style?.fontWeight,
            equals(FontWeight.w700),
            reason: 'Title style $style must have weight 700 (FontWeight.w700)',
          );
        }
      });

      test('RN-285: Textos de corpo e labels usam pesos 400 ou 500', () {
        final textTheme = lightTheme().textTheme;

        // Corpo usa 400
        expect(textTheme.bodyLarge?.fontWeight, equals(FontWeight.w400));
        expect(textTheme.bodyMedium?.fontWeight, equals(FontWeight.w400));
        expect(textTheme.bodySmall?.fontWeight, equals(FontWeight.w400));

        // Labels usam 500
        expect(textTheme.labelLarge?.fontWeight, equals(FontWeight.w500));
        expect(textTheme.labelMedium?.fontWeight, equals(FontWeight.w500));
        expect(textTheme.labelSmall?.fontWeight, equals(FontWeight.w500));
      });

      testWidgets(
        'CA-285.1: Text widget herda Nunito e fallback do tema sem erros de layout',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: lightTheme(),
              home: const Scaffold(
                body: Column(
                  children: [
                    Text(
                      'Main Title',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('Texto de corpo carinhoso da Momo'),
                  ],
                ),
              ),
            ),
          );

          expect(find.text('Main Title'), findsOneWidget);
          expect(find.text('Texto de corpo carinhoso da Momo'), findsOneWidget);

          final theme = Theme.of(tester.element(find.text('Main Title')));
          expect(theme.textTheme.bodyMedium?.fontFamily, equals('Nunito'));
          expect(
            theme.textTheme.bodyMedium?.fontFamilyFallback,
            contains('sans-serif'),
          );
        },
      );
    },
  );
}
