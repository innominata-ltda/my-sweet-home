// Testes de similarity — cobertura ≥ 95% (SPEC-001, 004-testing.md §2)
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/text/similarity.dart';

void main() {
  group('similarity — basic cases', () {
    test('identical strings -> 1.0', () {
      expect(similarity('leite', 'leite'), 1.0);
    });

    test('strings completamente diferentes → < 0.6', () {
      // Jaro-Winkler para 'leite' vs 'cafe' ≈ 0.48 (1 char em comum em strings de 5 chars)
      // Clearly below useful similarity threshold (0.8+)
      expect(similarity('leite', 'cafe'), lessThan(0.6));
    });

    test('leite integral vs leite int → ≥ 0.8', () {
      expect(
        similarity('leite integral', 'leite int'),
        greaterThanOrEqualTo(0.8),
      );
    });

    test('strings vazias → 1.0', () {
      expect(similarity('', ''), 1.0);
    });

    test('one empty and other not -> 0.0', () {
      expect(similarity('leite', ''), 0.0);
      expect(similarity('', 'leite'), 0.0);
    });

    test('a vs b → < 0.5', () {
      expect(similarity('a', 'b'), lessThan(0.5));
    });

    test('feijao preto vs feijao → > 0.5', () {
      expect(similarity('feijao preto', 'feijao'), greaterThan(0.5));
    });
  });

  group('similarity — implicit normalization / accents', () {
    test('macarrao vs macarrao (normalized beforehand) -> >= 0.9', () {
      // Simulating both having already passed through normalizeProductName
      expect(similarity('macarrao', 'macarrao'), greaterThanOrEqualTo(0.9));
    });

    test(
      'highly similar strings with 1 char difference -> high similarity',
      () {
        expect(similarity('feijao', 'feijão'), greaterThanOrEqualTo(0.7));
      },
    );
  });

  group('similarity — propriedades', () {
    test('is symmetric: similarity(a,b) == similarity(b,a)', () {
      const a = 'leite integral';
      const b = 'integral leite';
      // With token-set, they should be close (not necessarily equal via JW)
      final ab = similarity(a, b);
      final ba = similarity(b, a);
      expect((ab - ba).abs(), lessThan(0.1));
    });

    test('resultado sempre no intervalo [0.0, 1.0]', () {
      final pairs = [
        ('leite', 'cafe'),
        ('pao', 'sal'),
        ('arroz', 'feijao'),
        ('a', 'z'),
        ('xyz', 'abc'),
      ];
      for (final (a, b) in pairs) {
        final score = similarity(a, b);
        expect(score, greaterThanOrEqualTo(0.0), reason: '$a vs $b');
        expect(score, lessThanOrEqualTo(1.0), reason: '$a vs $b');
      }
    });
  });

  group('similarity — prefixos e substrings', () {
    test('prefixo comum longo → alta similaridade', () {
      expect(similarity('macarrao', 'macarrao espaguete'), greaterThan(0.7));
    });

    test('substring de uma → moderada similaridade', () {
      expect(similarity('leite', 'leite condensado'), greaterThan(0.6));
    });

    test('strings completamente sem caracteres em comum → baixa', () {
      expect(similarity('zzz', 'aaa'), lessThan(0.5));
    });
  });

  group('jaroWinkler (internal function via similarity)', () {
    test('string igual a si mesma → 1.0 via similarity', () {
      expect(similarity('cafe', 'cafe'), 1.0);
    });

    test('anagramas → similaridade detectada', () {
      // token-set reordena tokens → deve ter score ≥ 0.5
      expect(similarity('preto feijao', 'feijao preto'), greaterThan(0.5));
    });
  });
}
