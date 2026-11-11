import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_colors.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Calculates relative luminance of a [Color] per W3C WCAG 2.1.
///
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double _relativeLuminance(Color color) {
  double linearize(double channel) {
    final c = channel / 255.0;
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize((color.r * 255.0).round().toDouble());
  final g = linearize((color.g * 255.0).round().toDouble());
  final b = linearize((color.b * 255.0).round().toDouble());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates contrast ratio between two colors (WCAG 2.1).
///
/// Retorna um valor entre 1 (sem contraste) e 21 (preto sobre branco).
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('T-13 — Tema claro e escuro', () {
    test('CA-8.1 lightTheme is not null', () {
      expect(lightTheme(), isNotNull);
    });

    test('CA-8.1 darkTheme is not null', () {
      expect(darkTheme(), isNotNull);
    });

    test('CA-8.1 Spacing.touchTarget == 48.0 (WCAG 2.5.5)', () {
      expect(Spacing.touchTarget, equals(48.0));
    });

    test('CA-8.1 lightTheme usa Material 3', () {
      expect(lightTheme().useMaterial3, isTrue);
    });

    test('CA-8.1 darkTheme usa Material 3', () {
      expect(darkTheme().useMaterial3, isTrue);
    });

    test('CA-8.1 Spacing constants are correct', () {
      expect(Spacing.xs, equals(4.0));
      expect(Spacing.sm, equals(8.0));
      expect(Spacing.md, equals(16.0));
      expect(Spacing.lg, equals(24.0));
      expect(Spacing.xl, equals(32.0));
      expect(Spacing.xxl, equals(48.0));
    });

    test('CA-8.1 Radius constants are correct', () {
      expect(Radius.sm, equals(8.0));
      expect(Radius.md, equals(12.0));
      expect(Radius.lg, equals(20.0));
      expect(Radius.full, equals(999.0));
    });

    test('CA-8.1 lightTheme aceita ColorScheme customizado', () {
      final custom = ColorScheme.fromSeed(seedColor: Colors.teal);
      final theme = lightTheme(custom);
      expect(theme.colorScheme, equals(custom));
    });

    test('CA-8.1 darkTheme aceita ColorScheme customizado', () {
      final custom = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      );
      final theme = darkTheme(custom);
      expect(theme.colorScheme, equals(custom));
    });

    // ── WCAG AA contrast tests (minimum 4.5:1 for normal text) ─────────

    test('CA-8.1 lightTheme: onSurface sobre surface tem contraste >= 4.5 (WCAG AA)', () {
      final scheme = AppColors.light;
      final ratio = _contrastRatio(scheme.onSurface, scheme.surface);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'Contraste onSurface/surface no tema claro foi $ratio — '
            'minimum WCAG AA is 4.5:1',
      );
    });

    test('CA-8.1 darkTheme: onSurface sobre surface tem contraste >= 4.5 (WCAG AA)', () {
      final scheme = AppColors.dark;
      final ratio = _contrastRatio(scheme.onSurface, scheme.surface);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            'Contraste onSurface/surface no tema escuro foi $ratio — '
            'minimum WCAG AA is 4.5:1',
      );
    });
  });
}
