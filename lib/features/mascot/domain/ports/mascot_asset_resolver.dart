import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';

/// Abstract port responsible for resolving asset paths and mascot animations (SPEC-012, CA-110.5).
abstract interface class MascotAssetResolver {
  /// Returns the asset path for an [animal] and [expression].
  ///
  /// If specific asset does not exist or is unavailable, MUST return
  /// [fallbackPlaceholderPath] safely without throwing exception (CA-110.5).
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  );

  /// Returns Lottie file path for animation with name [animationName].
  String resolveAnimationPath(String animationName);

  /// Caminho do asset ou placeholder utilizado em caso de falha de carregamento (CA-110.5).
  String get fallbackPlaceholderPath;

  /// Returns `true` if asset for given animal and expression exists and is available.
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression);

  /// Returns `true` if given Lottie animation exists and is available.
  bool hasAnimationAsset(String animationName);
}
