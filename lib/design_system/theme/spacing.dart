import 'package:flutter/material.dart';

/// Standard spacing constants for the design system.
///
/// These are the only allowed numeric values for [EdgeInsets],
/// [SizedBox], [Gap], and similar. Numeric literals outside
/// `design_system/` are prohibited by project conventions.
abstract final class Spacing {
  /// 4 dp
  static const xs = 4.0;

  /// 8 dp
  static const sm = 8.0;

  /// 16 dp
  static const md = 16.0;

  /// 24 dp
  static const lg = 24.0;

  /// 32 dp
  static const xl = 32.0;

  /// 48 dp
  static const xxl = 48.0;

  /// Minimum touch target - 48 dp (WCAG 2.5.5 / Material 3).
  static const touchTarget = 48.0;
}

/// Standard border radius constants for the design system (RN-292, CA-003.4, REPO-005).
abstract final class Radius {
  /// 8 dp
  static const sm = 8.0;

  /// 12 dp
  static const md = 12.0;

  /// 16 dp — chips (RN-292, CA-003.4)
  static const chip = 16.0;

  /// 20 dp — cards (RN-292, CA-003.4)
  static const lg = 20.0;
  static const card = 20.0;

  /// 28 dp — buttons (RN-292, CA-003.4)
  static const button = 28.0;

  /// Pill / circular — 999 dp
  static const full = 999.0;
}

/// Standard shadows and glows for the design system (RN-292, CA-003.4).
abstract final class AppShadows {
  /// Soft shadow with subtle glow in primary color of active palette (RN-292, CA-003.4).
  static List<BoxShadow> softGlow(
    Color primaryColor, {
    double opacity = 0.12,
  }) => [
    BoxShadow(
      color: primaryColor.withValues(alpha: opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Soft shadow with glow for cards in primary color.
  static List<BoxShadow> card(Color primaryColor) =>
      softGlow(primaryColor, opacity: 0.10);

  /// Soft shadow with glow for buttons in primary color.
  static List<BoxShadow> button(Color primaryColor) =>
      softGlow(primaryColor, opacity: 0.20);
}
