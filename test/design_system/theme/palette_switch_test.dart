import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';

void main() {
  group('T-I04 / CA-003.3: Dynamic switching between the 3 Momo palettes', () {
    test('Rose, Lavender, and Mint palettes have distinct primary colors', () {
      final rosePrimary = AppPalette.rose.lightScheme.primary;
      final lavenderPrimary = AppPalette.lavender.lightScheme.primary;
      final mintPrimary = AppPalette.mint.lightScheme.primary;

      expect(rosePrimary, isNot(equals(lavenderPrimary)));
      expect(lavenderPrimary, isNot(equals(mintPrimary)));
      expect(rosePrimary, isNot(equals(mintPrimary)));
    });

    testWidgets(
      'CA-003.3: Troca entre as 3 paletas atualiza ThemeData imediatamente sem restart',
      (tester) async {
        // Um widget com estado que alterna a paleta ativa
        AppPalette currentPalette = AppPalette.rose;
        late void Function(AppPalette) setPalette;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setPalette = (newPalette) {
                setState(() {
                  currentPalette = newPalette;
                });
              };

              return MaterialApp(
                theme: lightTheme(currentPalette.lightScheme),
                darkTheme: darkTheme(currentPalette.darkScheme),
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) {
                      final theme = Theme.of(ctx);
                      return Center(
                        child: Text(
                          'Tema Ativo',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );

        // 1. Inicialmente na paleta Rose
        var textWidget = tester.widget<Text>(find.text('Tema Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.rose.lightScheme.primary),
        );

        // 2. Muda para Lavender sem restart do app
        setPalette(AppPalette.lavender);
        await tester.pumpAndSettle();

        textWidget = tester.widget<Text>(find.text('Tema Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.lavender.lightScheme.primary),
        );

        // 3. Muda para Mint sem restart do app
        setPalette(AppPalette.mint);
        await tester.pumpAndSettle();

        textWidget = tester.widget<Text>(find.text('Tema Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.mint.lightScheme.primary),
        );

        // 4. Volta para Rose
        setPalette(AppPalette.rose);
        await tester.pumpAndSettle();

        textWidget = tester.widget<Text>(find.text('Tema Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.rose.lightScheme.primary),
        );
      },
    );

    testWidgets(
      'CA-003.3: Troca de paleta em tema escuro atualiza cores escuras sem restart',
      (tester) async {
        AppPalette currentPalette = AppPalette.rose;
        late void Function(AppPalette) setPalette;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setPalette = (newPalette) {
                setState(() {
                  currentPalette = newPalette;
                });
              };

              return MaterialApp(
                themeMode: ThemeMode.dark,
                theme: lightTheme(currentPalette.lightScheme),
                darkTheme: darkTheme(currentPalette.darkScheme),
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) {
                      final theme = Theme.of(ctx);
                      return Center(
                        child: Text(
                          'Tema Escuro Ativo',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );

        // 1. Rose dark
        var textWidget = tester.widget<Text>(find.text('Tema Escuro Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.rose.darkScheme.primary),
        );

        // 2. Mint dark
        setPalette(AppPalette.mint);
        await tester.pumpAndSettle();

        textWidget = tester.widget<Text>(find.text('Tema Escuro Ativo'));
        expect(
          textWidget.style?.color,
          equals(AppPalette.mint.darkScheme.primary),
        );
      },
    );
  });
}
