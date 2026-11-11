import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';

void main() {
  group('UuidV5DeterministicIdGenerator', () {
    const generator = UuidV5DeterministicIdGenerator();

    final uuidV5Pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('forSeed gera UUID v5 valido e estavel', () {
      final id1 = generator.forSeed('product', 'arroz branco agulhinha');
      final id2 = generator.forSeed('product', 'arroz branco agulhinha');

      expect(id1, matches(uuidV5Pattern));
      expect(id1, equals(id2));
    });

    test('forSeed diferencia kind e naturalKey', () {
      final prodId = generator.forSeed('product', 'leite');
      final aliasId = generator.forSeed('product_alias', 'leite');
      final otherProdId = generator.forSeed('product', 'feijao');

      expect(prodId, isNot(equals(aliasId)));
      expect(prodId, isNot(equals(otherProdId)));
    });

    test('forOccurrence gera UUID v5 valido e estavel', () {
      final id1 = generator.forOccurrence('rule-001', '2026-10-22');
      final id2 = generator.forOccurrence('rule-001', '2026-10-22');

      expect(id1, matches(uuidV5Pattern));
      expect(id1, equals(id2));
    });

    test('forOccurrence diferencia regra e data', () {
      final idA = generator.forOccurrence('rule-001', '2026-10-22');
      final idB = generator.forOccurrence('rule-002', '2026-10-22');
      final idC = generator.forOccurrence('rule-001', '2026-10-23');

      expect(idA, isNot(equals(idB)));
      expect(idA, isNot(equals(idC)));
    });

    test('permite customizar namespace se necessario', () {
      const customGen = UuidV5DeterministicIdGenerator(
        namespace: '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
      );
      final idStandard = generator.forSeed('product', 'arroz');
      final idCustom = customGen.forSeed('product', 'arroz');

      expect(idStandard, isNot(equals(idCustom)));
      expect(idCustom, matches(uuidV5Pattern));
    });
  });
}
