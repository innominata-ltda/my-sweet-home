import 'dart:math' show pow;

import 'package:flutter/material.dart';

/// Relative luminance calculation and contrast ratios according to W3C WCAG 2.1.
abstract final class ColorContrast {
  /// Minimum required for normal text under WCAG 2.1 AA standard.
  static const double wcagAaNormalTextThreshold = 4.5;

  /// Calculates relative luminance of a [Color] according to W3C WCAG 2.1.
  ///
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      final c = channel / 255.0;
      return c <= 0.04045
          ? c / 12.92
          : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize((color.r * 255.0).round().toDouble());
    final g = linearize((color.g * 255.0).round().toDouble());
    final b = linearize((color.b * 255.0).round().toDouble());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates contrast ratio between two colors (WCAG 2.1).
  ///
  /// Returns a value between 1.0 and 21.0.
  static double contrastRatio(Color foreground, Color background) {
    final la = relativeLuminance(foreground);
    final lb = relativeLuminance(background);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if a color pair meets the WCAG AA threshold (default 4.5:1).
  static bool passesAa(
    Color foreground,
    Color background, {
    double minRatio = wcagAaNormalTextThreshold,
  }) {
    return contrastRatio(foreground, background) >= minRatio;
  }

  /// Returns all essential text/background pairs of a [ColorScheme] and their contrast ratios.
  static Map<String, double> getSchemeContrastRatios(ColorScheme scheme) {
    return {
      'onSurface / surface': contrastRatio(scheme.onSurface, scheme.surface),
      'onPrimary / primary': contrastRatio(scheme.onPrimary, scheme.primary),
      'onSecondary / secondary': contrastRatio(
        scheme.onSecondary,
        scheme.secondary,
      ),
      'onTertiary / tertiary': contrastRatio(
        scheme.onTertiary,
        scheme.tertiary,
      ),
      'onError / error': contrastRatio(scheme.onError, scheme.error),
      'onSurfaceVariant / surfaceContainerHighest': contrastRatio(
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      'onPrimaryContainer / primaryContainer': contrastRatio(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      ),
      'onSecondaryContainer / secondaryContainer': contrastRatio(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      'onTertiaryContainer / tertiaryContainer': contrastRatio(
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
      ),
      'onErrorContainer / errorContainer': contrastRatio(
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
    };
  }

  /// Returns `true` if ALL primary text/background pairs of a [ColorScheme]
  /// meet the minimum 4.5:1 ratio (WCAG AA).
  static bool isSchemeAaCompliant(
    ColorScheme scheme, {
    double minRatio = wcagAaNormalTextThreshold,
  }) {
    final ratios = getSchemeContrastRatios(scheme);
    return ratios.values.every((ratio) => ratio >= minRatio);
  }
}

/// Represents a color palette for app theme customization (RF-003, RN-257, CA-5.1).
class AppPalette {
  final String id;
  final String name;
  final Color seedColor;

  const AppPalette({
    required this.id,
    required this.name,
    required this.seedColor,
  });

  /// [ColorScheme] for light theme generated from [seedColor].
  ColorScheme get lightScheme => ColorScheme.fromSeed(seedColor: seedColor);

  /// [ColorScheme] for dark theme generated from [seedColor].
  ColorScheme get darkScheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    // RN-267: Dark background MUST NOT be pure black (#000000).
    if (scheme.surface == const Color(0xFF000000)) {
      return scheme.copyWith(surface: const Color(0xFF121212));
    }
    return scheme;
  }

  /// Returns `true` if BOTH schemes (light and dark) pass WCAG AA contrast (4.5:1)
  /// for all essential text and background pairs (CA-5.1, RN-257).
  bool get isAaCompliant {
    return ColorContrast.isSchemeAaCompliant(lightScheme) &&
        ColorContrast.isSchemeAaCompliant(darkScheme);
  }

  /// Rose palette / caring pink (seed #E8A0BF, RN-266, CA-003.1).
  static const rose = AppPalette(
    id: 'rose',
    name: 'Rose',
    seedColor: Color(0xFFE8A0BF),
  );

  /// Lavender palette / soft lilac (seed #B8A9E8, RN-266, CA-003.3).
  static const lavender = AppPalette(
    id: 'lavender',
    name: 'Lavender',
    seedColor: Color(0xFFB8A9E8),
  );

  /// Mint palette / fresh mint (seed #7EC8A3, RN-266, CA-003.2).
  static const mint = AppPalette(
    id: 'mint',
    name: 'Mint',
    seedColor: Color(0xFF7EC8A3),
  );

  /// Default palette - Steel blue (neither green nor red).
  static const steelBlue = AppPalette(
    id: 'steel_blue',
    name: 'Azul Aço',
    seedColor: Color(0xFF3D5A80),
  );

  /// Teal palette / blue-green.
  static const teal = AppPalette(
    id: 'teal',
    name: 'Teal',
    seedColor: Color(0xFF006A60),
  );

  /// Terracotta palette.
  static const terracotta = AppPalette(
    id: 'terracotta',
    name: 'Terracota',
    seedColor: Color(0xFF984028),
  );

  /// Deep Purple palette.
  static const deepPurple = AppPalette(
    id: 'purple',
    name: 'Roxo Profundo',
    seedColor: Color(0xFF6750A4),
  );

  /// Slate / graphite palette.
  static const slate = AppPalette(
    id: 'slate',
    name: 'Grafite',
    seedColor: Color(0xFF4C616B),
  );

  /// Navy blue palette.
  static const navy = AppPalette(
    id: 'navy',
    name: 'Azul Marinho',
    seedColor: Color(0xFF1A385C),
  );

  /// Forest green palette.
  static const forest = AppPalette(
    id: 'forest',
    name: 'Verde Floresta',
    seedColor: Color(0xFF2E5B18),
  );

  /// Dark Amber / Warm Amber palette.
  static const amber = AppPalette(
    id: 'amber',
    name: 'Âmbar',
    seedColor: Color(0xFF825500),
  );

  /// Momo mascot thematic palettes (RN-266).
  static const List<AppPalette> mascotPalettes = [rose, lavender, mint];

  /// List of all predefined palettes in the application.
  static const List<AppPalette> allPalettes = [
    rose,
    lavender,
    mint,
    steelBlue,
    teal,
    terracotta,
    deepPurple,
    slate,
    navy,
    forest,
    amber,
  ];

  /// Finds a palette by its unique identifier [id].
  /// Returns [rose] as safe fallback if ID is not recognized (RN-262).
  static AppPalette fromId(String id) {
    final normalized = id.trim().toLowerCase();
    return allPalettes.firstWhere(
      (p) => p.id.toLowerCase() == normalized,
      orElse: () => rose,
    );
  }

  /// Returns ONLY palettes that pass AA contrast test (4.5:1)
  /// in both light and dark themes (RN-257, CA-5.1).
  ///
  /// Any palette or free color failing the test MUST NOT be offered to the user.
  static List<AppPalette> get availablePalettes {
    return allPalettes.where((p) => p.isAaCompliant).toList();
  }

  /// Evaluates whether a given [seedColor] is compliant with WCAG AA (4.5:1)
  /// in both light and dark themes.
  static bool isSeedAaCompliant(Color seed) {
    final light = ColorScheme.fromSeed(seedColor: seed);
    final dark = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ColorContrast.isSchemeAaCompliant(light) &&
        ColorContrast.isSchemeAaCompliant(dark);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPalette &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          seedColor == other.seedColor;

  @override
  int get hashCode => id.hashCode ^ seedColor.hashCode;
}
