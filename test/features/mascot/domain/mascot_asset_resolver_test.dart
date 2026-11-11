import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/mascot/data/resolvers/mascot_asset_resolver_impl.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot.dart';

void main() {
  group('MascotAssetResolver (CA-110.5, RN-260, RN-288)', () {
    test('resolves expression paths in default format assets/mascots/{animal}/{expression}.webp', () {
      const resolver = MascotAssetResolverImpl();

      for (final animal in MascotAnimal.values) {
        for (final expression in MascotExpression.values) {
          final path = resolver.resolveExpressionPath(animal, expression);
          expect(path, 'assets/mascots/${animal.name}/${expression.name}.webp');
        }
      }
    });

    test(
      'resolve caminhos de animação no formato assets/lottie/{name}.json',
      () {
        const resolver = MascotAssetResolverImpl();

        expect(
          resolver.resolveAnimationPath('confetti'),
          'assets/lottie/confetti.json',
        );
        expect(
          resolver.resolveAnimationPath('celebration.json'),
          'assets/lottie/celebration.json',
        );
        expect(
          resolver.resolveAnimationPath('idle'),
          'assets/lottie/idle.json',
        );
        expect(
          resolver.resolveAnimationPath('assets/lottie/confetti.json'),
          'assets/lottie/confetti.json',
        );
        expect(
          resolver.resolveAnimationPath('assets/splash/intro'),
          'assets/splash/intro.json',
        );
        expect(resolver.resolveAnimationPath('   '), '');
      },
    );

    test(
      'hasAnimationAsset validates existence and discards empty strings',
      () {
        final resolver = MascotAssetResolverImpl(
          knownAssets: {'assets/lottie/confetti.json'},
        );

        expect(resolver.hasAnimationAsset(''), isFalse);
        expect(resolver.hasAnimationAsset('   '), isFalse);
        expect(resolver.hasAnimationAsset('confetti'), isTrue);
        expect(resolver.hasAnimationAsset('unknown_anim'), isFalse);
      },
    );

    test('CA-110.5: returns safe placeholder when asset does not exist', () {
      final knownAssets = {
        'assets/mascots/cat/neutral.webp',
        'assets/mascots/cat/happy.webp',
      };

      final resolver = MascotAssetResolverImpl(
        knownAssets: knownAssets,
        fallbackPlaceholder: 'assets/mascots/placeholder.webp',
      );

      // Asset existente
      expect(
        resolver.resolveExpressionPath(
          MascotAnimal.cat,
          MascotExpression.neutral,
        ),
        'assets/mascots/cat/neutral.webp',
      );

      // Non-existent asset should trigger placeholder fallback
      expect(
        resolver.resolveExpressionPath(
          MascotAnimal.bunny,
          MascotExpression.worried,
        ),
        'assets/mascots/placeholder.webp',
      );
      expect(
        resolver.hasExpressionAsset(
          MascotAnimal.bunny,
          MascotExpression.worried,
        ),
        isFalse,
      );
    });

    test('supports dynamic check via assetExists closure', () {
      final resolver = MascotAssetResolverImpl(
        assetExists: (path) => path.contains('dog'),
      );

      expect(
        resolver.hasExpressionAsset(MascotAnimal.dog, MascotExpression.happy),
        isTrue,
      );
      expect(
        resolver.hasExpressionAsset(MascotAnimal.cat, MascotExpression.happy),
        isFalse,
      );
      expect(
        resolver.resolveExpressionPath(
          MascotAnimal.cat,
          MascotExpression.happy,
        ),
        resolver.fallbackPlaceholderPath,
      );
    });
  });
}
