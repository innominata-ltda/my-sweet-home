import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/default_product_matcher.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';

void main() {
  group('DefaultProductMatcher', () {
    late DefaultProductMatcher matcher;

    setUp(() {
      matcher = const DefaultProductMatcher();
    });

    final p1 = Product(
      id: 'p1',
      canonicalName: 'Leite Integral',
      categoryId: 'c1',
      defaultUnit: Unit.l,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final p2 = Product(
      id: 'p2',
      canonicalName: 'Pão de Sal',
      categoryId: 'c2',
      defaultUnit: Unit.un,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final pArchived = Product(
      id: 'p3',
      canonicalName: 'Café',
      categoryId: 'c3',
      defaultUnit: Unit.kg,
      isArchived: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('returns NoMatch for empty text or stopwords only', () {
      final index = ProductIndex.from([p1], [], []);
      expect(matcher.match('', index), isA<NoMatch>());
      expect(matcher.match('   ', index), isA<NoMatch>());
      expect(matcher.match('de com para', index), isA<NoMatch>());
    });

    test('CA-1.1: Exact match with canonical name (User)', () {
      final index = ProductIndex.from([p1], [], []);
      final result = matcher.match('Leite Integral 1L', index);

      expect(result, isA<SingleMatch>());
      final match = (result as SingleMatch).match;
      expect(match.product.id, 'p1');
      expect(match.origin, isA<ExactUserAlias>());
      expect(result.needsConfirmation, false);
    });

    test('CA-1.1: Exact match with user alias (User)', () {
      final alias = ProductAlias(
        id: 'a1',
        productId: 'p2',
        alias: 'Pão francês',
        normalizedAlias: 'pao frances',
        source: AliasSource.user,
        createdAt: DateTime.now(),
      );
      final index = ProductIndex.from([p1, p2], [alias], []);

      final result = matcher.match('Pão francês', index);

      expect(result, isA<SingleMatch>());
      final match = (result as SingleMatch).match;
      expect(match.product.id, 'p2');
      expect(match.origin, isA<ExactUserAlias>());
      expect(result.needsConfirmation, false);
    });

    test('CA-1.2: Exact match com alias da seed', () {
      final alias = ProductAlias(
        id: 'a2',
        productId: 'p1',
        alias: 'Leite de vaca',
        normalizedAlias: 'leite vaca',
        source: AliasSource.seed,
        createdAt: DateTime.now(),
      );
      final index = ProductIndex.from([p1, p2], [alias], []);

      final result = matcher.match('Leite de vaca', index);

      expect(result, isA<SingleMatch>());
      final match = (result as SingleMatch).match;
      expect(match.product.id, 'p1');
      expect(match.origin, isA<ExactSeedAlias>());
      expect(result.needsConfirmation, false);
    });

    test('CA-1.3: Fuzzy match', () {
      final index = ProductIndex.from([p1, p2], [], []);

      // "Leite intgral" must have high similarity with "leite integral"
      final result = matcher.match('Leit Intgral', index);

      expect(result, isA<SingleMatch>());
      final matchResult = result as SingleMatch;
      expect(matchResult.match.product.id, 'p1');
      expect(matchResult.match.origin, isA<Fuzzy>());
      expect(matchResult.needsConfirmation, false); // se > 0.85
    });

    test('Fuzzy match needs confirmation in threshold-0.85 range', () {
      final pTest = Product(
        id: 'ptest',
        canonicalName: 'abcd',
        categoryId: 'c1',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final index = ProductIndex.from([pTest], [], []);
      final result = matcher.match('abxx', index, threshold: 0.60);

      expect(result, isA<SingleMatch>());
      final match = result as SingleMatch;
      expect(match.match.origin, isA<Fuzzy>());
      expect(match.needsConfirmation, isTrue);
    });

    test(
      'CA-7.1, CA-7.2: AmbiguousMatch when multiple pass threshold (fuzzy)',
      () {
        final pB = Product(
          id: 'pb',
          canonicalName: 'Leite Desnatado',
          categoryId: 'c1',
          defaultUnit: Unit.l,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final index = ProductIndex.from([p1, pB], [], []);

        final result = matcher.match('Leite', index, threshold: 0.70);

        expect(result, isA<AmbiguousMatch>());
        final candidates = (result as AmbiguousMatch).candidates;
        expect(candidates.length, 2);
      },
    );

    test('Precedence order: Exact User > Exact Seed > Fuzzy', () {
      final aliasSeed = ProductAlias(
        id: 'a1',
        productId: 'p1',
        alias: 'pao sal',
        normalizedAlias: 'pao sal',
        source: AliasSource.seed,
        createdAt: DateTime.now(),
      );

      final px = Product(
        id: 'px',
        canonicalName: 'Outro',
        categoryId: 'c',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final aliasUser = ProductAlias(
        id: 'a2',
        productId: 'px',
        alias: 'pao sal',
        normalizedAlias: 'pao sal',
        source: AliasSource.user,
        createdAt: DateTime.now(),
      );

      final index = ProductIndex.from([p1, px], [aliasSeed, aliasUser], []);

      final result = matcher.match('pão de sal', index);

      expect(result, isA<SingleMatch>());
      final matchResult = result as SingleMatch;
      // Exato User (px) deve ganhar de Exato Seed (p1)
      expect(matchResult.match.product.id, 'px');
      expect(matchResult.match.origin, isA<ExactUserAlias>());
    });

    test('Ignora produtos arquivados', () {
      final index = ProductIndex.from([pArchived], [], []);
      final result = matcher.match('Café', index);
      expect(result, isA<NoMatch>());
    });

    test('Ignora produto se estiver na lista de denials (DeniedPair)', () {
      final denial = DeniedPair(rawText: 'leite de soja', productId: 'p1');
      final index = ProductIndex.from([p1], [], [denial]);

      final result = matcher.match('leite de soja', index, threshold: 0.50);

      expect(result, isA<NoMatch>());
    });

    test('Empate Exato User -> Ambiguous', () {
      final pA = Product(
        id: 'pa',
        canonicalName: 'A',
        categoryId: 'c',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final pB = Product(
        id: 'pb',
        canonicalName: 'B',
        categoryId: 'c',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final a1 = ProductAlias(
        id: 'a1',
        productId: 'pa',
        alias: 'x',
        normalizedAlias: 'x',
        source: AliasSource.user,
        createdAt: DateTime.now(),
      );
      final a2 = ProductAlias(
        id: 'a2',
        productId: 'pb',
        alias: 'x',
        normalizedAlias: 'x',
        source: AliasSource.user,
        createdAt: DateTime.now(),
      );

      final index = ProductIndex.from([pA, pB], [a1, a2], []);
      final result = matcher.match('x', index);

      expect(result, isA<AmbiguousMatch>());
      final ambig = result as AmbiguousMatch;
      expect(ambig.candidates.length, 2);
    });

    test('Empate Exato Seed -> Ambiguous', () {
      final pA = Product(
        id: 'pa',
        canonicalName: 'A',
        categoryId: 'c',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final pB = Product(
        id: 'pb',
        canonicalName: 'B',
        categoryId: 'c',
        defaultUnit: Unit.un,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final a1 = ProductAlias(
        id: 'a1',
        productId: 'pa',
        alias: 'y',
        normalizedAlias: 'y',
        source: AliasSource.seed,
        createdAt: DateTime.now(),
      );
      final a2 = ProductAlias(
        id: 'a2',
        productId: 'pb',
        alias: 'y',
        normalizedAlias: 'y',
        source: AliasSource.seed,
        createdAt: DateTime.now(),
      );

      final index = ProductIndex.from([pA, pB], [a1, a2], []);
      final result = matcher.match('y', index);

      expect(result, isA<AmbiguousMatch>());
      final ambig = result as AmbiguousMatch;
      expect(ambig.candidates.length, 2);
    });

    test('MatchOrigin e MatchResult equality e hashCode', () {
      const u1 = ExactUserAlias();
      const u2 = ExactUserAlias();
      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));

      const s1 = ExactSeedAlias();
      const s2 = ExactSeedAlias();
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(u1 == s1, isFalse);

      const f1 = Fuzzy(score: 0.9);
      const f2 = Fuzzy(score: 0.9);
      const f3 = Fuzzy(score: 0.8);
      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1 == f3, isFalse);

      const unk1 = Unknown();
      const unk2 = Unknown();
      expect(unk1, equals(unk2));
      expect(unk1.hashCode, equals(unk2.hashCode));

      final match1 = ProductMatch(product: p1, origin: u1, score: 1.0);
      final match2 = ProductMatch(product: p1, origin: u1, score: 1.0);
      final matchDiff = ProductMatch(product: p2, origin: u1, score: 1.0);
      expect(match1, equals(match2));
      expect(match1.hashCode, equals(match2.hashCode));
      expect(match1 == matchDiff, isFalse);

      const noMatch1 = NoMatch();
      const noMatch2 = NoMatch();
      expect(noMatch1, equals(noMatch2));
      expect(noMatch1.hashCode, equals(noMatch2.hashCode));

      final single1 = SingleMatch(match: match1, needsConfirmation: false);
      final single2 = SingleMatch(match: match1, needsConfirmation: false);
      final singleDiff = SingleMatch(match: match1, needsConfirmation: true);
      expect(single1, equals(single2));
      expect(single1.hashCode, equals(single2.hashCode));
      expect(single1 == singleDiff, isFalse);

      final ambig1 = AmbiguousMatch(candidates: [match1]);
      final ambig2 = AmbiguousMatch(candidates: [match1]);
      final ambigDiff = AmbiguousMatch(candidates: [matchDiff]);
      expect(ambig1, equals(ambig2));
      expect(ambig1.hashCode, equals(ambig2.hashCode));
      expect(ambig1 == ambigDiff, isFalse);
    });
  });
}
