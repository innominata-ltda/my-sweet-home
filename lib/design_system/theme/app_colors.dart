import 'package:flutter/material.dart';

export 'app_palette.dart';

/// Semantic palette of the app — light/dark pairs derived from a seed
/// steel-blue (`0xFF3D5A80`) via [ColorScheme.fromSeed].
///
/// Access colors only via [ColorScheme] injected in [BuildContext].
/// This class is not used directly by widgets; it exists to
/// document the seed and facilitate contrast testing.
abstract final class AppColors {
  /// Primary seed — steel-blue (neither green nor red).
  static const seedColor = Color(0xFF3D5A80);

  /// [ColorScheme] claro gerado a partir de [seedColor].
  static final light = ColorScheme.fromSeed(seedColor: seedColor);

  /// [ColorScheme] escuro gerado a partir de [seedColor].
  static final dark = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );
}
