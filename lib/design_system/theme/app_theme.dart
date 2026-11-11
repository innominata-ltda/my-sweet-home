import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'spacing.dart';

/// Builds Nunito typography with 700 weight for titles and 400/500 for body (RN-285, ADR-0008).
/// Declares safe fallback to system font (RN-286, CA-285.1).
TextTheme _buildNunitoTextTheme(ColorScheme scheme) {
  const fallback = ['Roboto', 'sans-serif'];
  const fontFamily = 'Nunito';

  TextStyle titleStyle({
    required double fontSize,
    required double height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallback,
    fontWeight: FontWeight.w700,
    fontSize: fontSize,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle bodyStyle({
    required double fontSize,
    required double height,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallback,
    fontWeight: weight,
    fontSize: fontSize,
    height: height,
    letterSpacing: letterSpacing,
  );

  return TextTheme(
    displayLarge: titleStyle(
      fontSize: 57,
      height: 64 / 57,
      letterSpacing: -0.25,
    ),
    displayMedium: titleStyle(fontSize: 45, height: 52 / 45),
    displaySmall: titleStyle(fontSize: 36, height: 44 / 36),
    headlineLarge: titleStyle(fontSize: 32, height: 40 / 32),
    headlineMedium: titleStyle(fontSize: 28, height: 36 / 28),
    headlineSmall: titleStyle(fontSize: 24, height: 32 / 24),
    titleLarge: titleStyle(fontSize: 22, height: 28 / 22),
    titleMedium: titleStyle(fontSize: 16, height: 24 / 16, letterSpacing: 0.15),
    titleSmall: titleStyle(fontSize: 14, height: 20 / 14, letterSpacing: 0.1),
    bodyLarge: bodyStyle(fontSize: 16, height: 24 / 16, letterSpacing: 0.5),
    bodyMedium: bodyStyle(fontSize: 14, height: 20 / 14, letterSpacing: 0.25),
    bodySmall: bodyStyle(fontSize: 12, height: 16 / 12, letterSpacing: 0.4),
    labelLarge: bodyStyle(
      fontSize: 14,
      height: 20 / 14,
      weight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: bodyStyle(
      fontSize: 12,
      height: 16 / 12,
      weight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: bodyStyle(
      fontSize: 11,
      height: 16 / 11,
      weight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}

ThemeData _buildTheme(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
    textTheme: _buildNunitoTextTheme(scheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: scheme.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radius.card),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: scheme.primary.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radius.button),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radius.chip),
      ),
      shadowColor: scheme.primary.withValues(alpha: 0.15),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
  );
}

/// Builds light [ThemeData] for the app.
///
/// Passes [customScheme] in tests to override the generated [ColorScheme].
ThemeData lightTheme([ColorScheme? customScheme]) {
  final scheme = customScheme ?? AppColors.light;
  return _buildTheme(scheme);
}

/// Builds dark [ThemeData] for the app.
///
/// Passes [customScheme] in tests to override the generated [ColorScheme].
ThemeData darkTheme([ColorScheme? customScheme]) {
  final scheme = customScheme ?? AppColors.dark;
  return _buildTheme(scheme);
}
