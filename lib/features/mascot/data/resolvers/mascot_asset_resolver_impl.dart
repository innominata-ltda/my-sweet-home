import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';

/// Default implementation of mascot asset resolver (SPEC-012, CA-110.5).
class MascotAssetResolverImpl implements MascotAssetResolver {
  final String fallbackPlaceholder;
  final bool Function(String path)? assetExists;
  final Set<String>? knownAssets;

  const MascotAssetResolverImpl({
    this.fallbackPlaceholder = 'assets/mascots/placeholder.webp',
    this.assetExists,
    this.knownAssets,
  });

  @override
  String get fallbackPlaceholderPath => fallbackPlaceholder;

  @override
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  ) {
    final standardPath =
        'assets/mascots/${animal.name}/${expression.name}.webp';
    if (!hasExpressionAsset(animal, expression)) {
      return fallbackPlaceholder;
    }
    return standardPath;
  }

  @override
  String resolveAnimationPath(String animationName) {
    final sanitized = animationName.trim();
    if (sanitized.isEmpty) return '';
    if (sanitized.startsWith('assets/')) {
      return sanitized.endsWith('.json') ? sanitized : '$sanitized.json';
    }
    final fileName = sanitized.endsWith('.json')
        ? sanitized
        : '$sanitized.json';
    return 'assets/lottie/$fileName';
  }

  @override
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression) {
    final path = 'assets/mascots/${animal.name}/${expression.name}.webp';
    if (assetExists != null) {
      return assetExists!(path);
    }
    if (knownAssets != null) {
      return knownAssets!.contains(path);
    }
    return true;
  }

  @override
  bool hasAnimationAsset(String animationName) {
    final sanitized = animationName.trim();
    if (sanitized.isEmpty) return false;
    final path = resolveAnimationPath(animationName);
    if (assetExists != null) {
      return assetExists!(path);
    }
    if (knownAssets != null) {
      return knownAssets!.contains(path);
    }
    return true;
  }
}
