import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';

void main() {
  group('T-I04 / CA-003.1 & CA-003.2: Testes de contraste WCAG AA e paletas da Momo', () {
    test('CA-003.1: Paleta Rose (#E8A0BF) passa em WCAG AA (>= 4.5:1) em claro e escuro', () {
      final rose = AppPalette.rose;
      expect(rose.id, equals('rose'));
      expect(rose.name, equals('Rose'));
      expect(rose.seedColor, equals(const Color(0xFFE8A0BF)));
      expect(rose.isAaCompliant, isTrue);

      final lightRatios = ColorContrast.getSchemeContrastRatios(
        rose.lightScheme,
      );
      for (final entry in lightRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Rose (claro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }

      final darkRatios = ColorContrast.getSchemeContrastRatios(rose.darkScheme);
      for (final entry in darkRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Rose (escuro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }
    });

    test('CA-003.2: Mint palette (#7EC8A3) in dark theme does not use #000000 background and passes AA', () {
      final mint = AppPalette.mint;
      expect(mint.id, equals('mint'));
      expect(mint.name, equals('Mint'));
      expect(mint.seedColor, equals(const Color(0xFF7EC8A3)));
      expect(mint.isAaCompliant, isTrue);

      // CA-003.2 & RN-267: Dark background MUST NOT be #000000 (pure black)
      final darkSurface = mint.darkScheme.surface;
      expect(
        darkSurface,
        isNot(equals(const Color(0xFF000000))),
        reason: 'Mint dark theme cannot use pure black background (#000000)',
      );

      final lightRatios = ColorContrast.getSchemeContrastRatios(
        mint.lightScheme,
      );
      for (final entry in lightRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Mint (claro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }

      final darkRatios = ColorContrast.getSchemeContrastRatios(mint.darkScheme);
      for (final entry in darkRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Mint (escuro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }
    });

    test('RN-266: Paleta Lavender (#B8A9E8) passa em WCAG AA (>= 4.5:1) em claro e escuro', () {
      final lavender = AppPalette.lavender;
      expect(lavender.id, equals('lavender'));
      expect(lavender.name, equals('Lavender'));
      expect(lavender.seedColor, equals(const Color(0xFFB8A9E8)));
      expect(lavender.isAaCompliant, isTrue);

      final lightRatios = ColorContrast.getSchemeContrastRatios(
        lavender.lightScheme,
      );
      for (final entry in lightRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Lavender (claro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }

      final darkRatios = ColorContrast.getSchemeContrastRatios(
        lavender.darkScheme,
      );
      for (final entry in darkRatios.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(ColorContrast.wcagAaNormalTextThreshold),
          reason:
              'Lavender (escuro): Par ${entry.key} teve contraste de ${entry.value.toStringAsFixed(2)} < 4.5:1',
        );
      }
    });

    test(
      'RN-266 & RN-267: The 3 Momo seeds are compatible via isSeedAaCompliant',
      () {
        expect(AppPalette.isSeedAaCompliant(const Color(0xFFE8A0BF)), isTrue);
        expect(AppPalette.isSeedAaCompliant(const Color(0xFFB8A9E8)), isTrue);
        expect(AppPalette.isSeedAaCompliant(const Color(0xFF7EC8A3)), isTrue);
      },
    );

    test(
      'RN-266: AppPalette.mascotPalettes contains Rose, Lavender, and Mint',
      () {
        expect(
          AppPalette.mascotPalettes,
          containsAll([AppPalette.rose, AppPalette.lavender, AppPalette.mint]),
        );
        expect(AppPalette.mascotPalettes.length, equals(3));
      },
    );

    test(
      'RN-262: AppPalette.fromId retorna a paleta correta ou fallback Rose',
      () {
        expect(AppPalette.fromId('rose'), equals(AppPalette.rose));
        expect(AppPalette.fromId('ROSE'), equals(AppPalette.rose));
        expect(AppPalette.fromId(' Lavender '), equals(AppPalette.lavender));
        expect(AppPalette.fromId('mint'), equals(AppPalette.mint));
        expect(AppPalette.fromId(''), equals(AppPalette.rose));
        expect(AppPalette.fromId('inexistente'), equals(AppPalette.rose));
      },
    );
  });
}
