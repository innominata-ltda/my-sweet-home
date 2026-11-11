library;

import 'package:my_sweet_home/features/products/domain/product.dart';

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

sealed class MatchOrigin {
  const MatchOrigin();
}

final class ExactUserAlias extends MatchOrigin {
  const ExactUserAlias();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExactUserAlias;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class ExactSeedAlias extends MatchOrigin {
  const ExactSeedAlias();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExactSeedAlias;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class Fuzzy extends MatchOrigin {
  const Fuzzy({required this.score});
  final double score;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fuzzy &&
          runtimeType == other.runtimeType &&
          score == other.score;

  @override
  int get hashCode => Object.hash(runtimeType, score);
}

final class Unknown extends MatchOrigin {
  const Unknown();

  @override
  bool operator ==(Object other) => identical(this, other) || other is Unknown;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class ProductMatch {
  const ProductMatch({
    required this.product,
    required this.origin,
    required this.score,
  });

  final Product product;
  final MatchOrigin origin;
  final double score;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductMatch &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          origin == other.origin &&
          score == other.score;

  @override
  int get hashCode => Object.hash(product, origin, score);
}

sealed class MatchResult {
  const MatchResult();
}

final class NoMatch extends MatchResult {
  const NoMatch();

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoMatch;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class SingleMatch extends MatchResult {
  const SingleMatch({required this.match, required this.needsConfirmation});

  final ProductMatch match;
  final bool needsConfirmation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleMatch &&
          runtimeType == other.runtimeType &&
          match == other.match &&
          needsConfirmation == other.needsConfirmation;

  @override
  int get hashCode => Object.hash(match, needsConfirmation);
}

final class AmbiguousMatch extends MatchResult {
  const AmbiguousMatch({required this.candidates});

  final List<ProductMatch> candidates;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmbiguousMatch &&
          runtimeType == other.runtimeType &&
          _listEquals(candidates, other.candidates);

  @override
  int get hashCode => Object.hashAll(candidates);
}

class DeniedPair {
  const DeniedPair({required this.rawText, required this.productId});

  final String rawText;
  final ProductId productId;
}

final class ProductIndex {
  const ProductIndex({
    required this.products,
    required this.aliases,
    required this.denials,
  });

  factory ProductIndex.from(
    List<Product> products,
    List<ProductAlias> aliases,
    List<DeniedPair> denials,
  ) {
    return ProductIndex(products: products, aliases: aliases, denials: denials);
  }

  final List<Product> products;
  final List<ProductAlias> aliases;
  final List<DeniedPair> denials;
}

abstract interface class ProductMatcher {
  MatchResult match(
    String rawText,
    ProductIndex index, {
    double threshold = 0.85,
  });
}
