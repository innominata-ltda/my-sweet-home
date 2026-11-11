import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';

void main() {
  group('T-10 / CA-5.1 & RN-257: Paletas de cor com contraste AA garantido por teste', () {
    test('CA-5.1: All palettes available in AppPalette.availablePalettes pass 4.5:1 contrast in light and dark', () {
      final available = AppPalette.availablePalettes;

      expect(
        available,
        isNotEmpty,
        reason:
            'Deve haver pelo menos uma paleta disponível que cumpra WCAG AA',
      );

      for (final palette in available) {
        expect(
          palette.isAaCompliant,
          isTrue,
          reason:
              'Paleta ${palette.name} (${palette.id}) deve passar em isAaCompliant',
        );

        // Verifica cada par do esquema claro
        final lightRatios = ColorContrast.getSchemeContrastRatios(
          palette.lightScheme,
        );
        for (final entry in lightRatios.entries) {
          expect(
            entry.value,
            greaterThanOrEqualTo(4.5),
            reason:
                'Paleta ${palette.name} (claro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)}, mas o mínimo WCAG AA é 4.5:1',
          );
        }

        // Verifica cada par do esquema escuro
        final darkRatios = ColorContrast.getSchemeContrastRatios(
          palette.darkScheme,
        );
        for (final entry in darkRatios.entries) {
          expect(
            entry.value,
            greaterThanOrEqualTo(4.5),
            reason:
                'Paleta ${palette.name} (escuro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)}, mas o mínimo WCAG AA é 4.5:1',
          );
        }
      }
    });

    test('RN-257: Palette or ColorScheme with text/background pair lacking AA contrast fails isSchemeAaCompliant', () {
      // ColorScheme customizado com texto cinza claro sobre fundo branco (contraste ~1.4:1 < 4.5:1)
      const lowContrastScheme = ColorScheme.light(
        surface: Colors.white,
        onSurface: Color(0xFFE0E0E0), // Grey 300
      );

      expect(
        ColorContrast.isSchemeAaCompliant(lowContrastScheme),
        isFalse,
        reason: 'Color scheme with insufficient contrast must be rejected by isSchemeAaCompliant',
      );
    });

    test('RF-003: Default palette steelBlue is valid and compatible with lightTheme and darkTheme', () {
      final defaultPalette = AppPalette.steelBlue;
      expect(defaultPalette.isAaCompliant, isTrue);

      final light = lightTheme(defaultPalette.lightScheme);
      final dark = darkTheme(defaultPalette.darkScheme);

      expect(
        light.colorScheme.primary,
        equals(defaultPalette.lightScheme.primary),
      );
      expect(
        dark.colorScheme.primary,
        equals(defaultPalette.darkScheme.primary),
      );
    });

    test('ColorContrast: calculates relative luminance and contrast according to WCAG 2.1', () {
      // Preto sobre branco deve ser 21.0
      final ratioBlackWhite = ColorContrast.contrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(ratioBlackWhite, closeTo(21.0, 0.01));

      // Branco sobre branco deve ser 1.0
      final ratioWhiteWhite = ColorContrast.contrastRatio(
        Colors.white,
        Colors.white,
      );
      expect(ratioWhiteWhite, closeTo(1.0, 0.01));

      expect(ColorContrast.passesAa(Colors.black, Colors.white), isTrue);
      expect(ColorContrast.passesAa(Colors.white, Colors.white), isFalse);
    });
  });
}
