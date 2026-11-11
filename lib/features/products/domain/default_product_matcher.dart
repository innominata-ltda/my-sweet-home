import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/core/text/similarity.dart';

class DefaultProductMatcher implements ProductMatcher {
  const DefaultProductMatcher();

  @override
  MatchResult match(
    String rawText,
    ProductIndex index, {
    double threshold = 0.85,
  }) {
    if (rawText.trim().isEmpty) return const NoMatch();

    final normText = normalizeProductName(rawText);
    if (normText.isEmpty) return const NoMatch();

    bool isDenied(ProductId pid) {
      for (final d in index.denials) {
        if (normalizeProductName(d.rawText) == normText && d.productId == pid) {
          return true;
        }
      }
      return false;
    }

    final exactUserMatches = <ProductMatch>[];
    final exactSeedMatches = <ProductMatch>[];
    final fuzzyMatches = <ProductMatch>[];

    for (final p in index.products) {
      if (p.isArchived) continue;
      if (isDenied(p.id)) continue;

      final normCanonical = normalizeProductName(p.canonicalName);

      bool foundExactUser = false;
      bool foundExactSeed = false;

      if (normCanonical == normText) {
        foundExactUser = true;
      }

      final pAliases = index.aliases.where((a) => a.productId == p.id);
      for (final a in pAliases) {
        if (a.normalizedAlias == normText) {
          if (a.source == AliasSource.user || a.source == AliasSource.ocr) {
            foundExactUser = true;
          } else if (a.source == AliasSource.seed) {
            foundExactSeed = true;
          }
        }
      }

      if (foundExactUser) {
        exactUserMatches.add(
          ProductMatch(product: p, origin: const ExactUserAlias(), score: 1.0),
        );
        continue;
      }

      if (foundExactSeed) {
        exactSeedMatches.add(
          ProductMatch(product: p, origin: const ExactSeedAlias(), score: 1.0),
        );
        continue;
      }

      // Fuzzy
      double maxFuzzy = similarity(normText, normCanonical);
      for (final a in pAliases) {
        final sc = similarity(normText, a.normalizedAlias);
        if (sc > maxFuzzy) maxFuzzy = sc;
      }

      if (maxFuzzy >= threshold) {
        fuzzyMatches.add(
          ProductMatch(
            product: p,
            origin: Fuzzy(score: maxFuzzy),
            score: maxFuzzy,
          ),
        );
      }
    }

    if (exactUserMatches.isNotEmpty) {
      if (exactUserMatches.length == 1) {
        return SingleMatch(
          match: exactUserMatches.first,
          needsConfirmation: false,
        );
      }
      return AmbiguousMatch(candidates: exactUserMatches);
    }

    if (exactSeedMatches.isNotEmpty) {
      if (exactSeedMatches.length == 1) {
        return SingleMatch(
          match: exactSeedMatches.first,
          needsConfirmation: false,
        );
      }
      return AmbiguousMatch(candidates: exactSeedMatches);
    }

    if (fuzzyMatches.isNotEmpty) {
      fuzzyMatches.sort((a, b) => b.score.compareTo(a.score));
      if (fuzzyMatches.length == 1) {
        final match = fuzzyMatches.first;
        return SingleMatch(match: match, needsConfirmation: match.score < 0.85);
      }
      return AmbiguousMatch(candidates: fuzzyMatches);
    }

    return const NoMatch();
  }
}
