import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';

void main() {
  group('VersionVector', () {
    final hlcA1 = Hlc(millis: 1000, counter: 0, siteId: 'a');
    final hlcA2 = Hlc(millis: 2000, counter: 0, siteId: 'a');
    final hlcB1 = Hlc(millis: 1500, counter: 0, siteId: 'b');
    final hlcC1 = Hlc(millis: 1200, counter: 0, siteId: 'c');

    test('empty vector covers no HLC', () {
      const vec = VersionVector.empty;
      expect(vec.covers(hlcA1), isFalse);
      expect(vec.maxBySite, isEmpty);
    });

    test(
      'covers returns true if HLC is less than or equal to registered for site',
      () {
        final vec = VersionVector({'a': hlcA2, 'b': hlcB1});

        expect(vec.covers(hlcA1), isTrue); // hlcA1 < hlcA2
        expect(vec.covers(hlcA2), isTrue); // hlcA2 == hlcA2
        expect(vec.covers(Hlc(millis: 2000, counter: 1, siteId: 'a')), isFalse);

        expect(vec.covers(hlcB1), isTrue);
        expect(vec.covers(hlcC1), isFalse); // 'c' not present
      },
    );

    test('update atualiza o vetor se o novo HLC for maior', () {
      final v0 = VersionVector({'a': hlcA1});
      final v1 = v0.update(hlcA2);
      expect(v1.maxBySite['a'], equals(hlcA2));

      // Smaller HLC does not alter
      final v2 = v1.update(hlcA1);
      expect(identical(v2, v1), isTrue);

      // New site is added
      final v3 = v2.update(hlcB1);
      expect(v3.maxBySite['b'], equals(hlcB1));
      expect(v3.maxBySite['a'], equals(hlcA2));
    });

    test('merge combina vetores escolhendo o maior HLC por site', () {
      final vA = VersionVector({'a': hlcA2, 'b': hlcB1});
      final vB = VersionVector({
        'a': hlcA1, // menor
        'b': Hlc(millis: 1800, counter: 0, siteId: 'b'), // maior
        'c': hlcC1, // novo
      });

      final merged = vA.merge(vB);
      expect(merged.maxBySite['a'], equals(hlcA2));
      expect(
        merged.maxBySite['b'],
        equals(Hlc(millis: 1800, counter: 0, siteId: 'b')),
      );
      expect(merged.maxBySite['c'], equals(hlcC1));
    });

    test('toJson e fromJson serializam e desserializam corretamente', () {
      final vec = VersionVector({'a': hlcA2, 'b': hlcB1});
      final json = vec.toJson();

      expect(json, equals({'a': hlcA2.pack(), 'b': hlcB1.pack()}));

      final restored = VersionVector.fromJson(json);
      expect(restored, equals(vec));

      final directHlcMap = VersionVector.fromJson({'a': hlcA2, 'b': hlcB1});
      expect(directHlcMap, equals(vec));
    });

    test('igualdade e hashCode', () {
      final v1 = VersionVector({'a': hlcA1});
      final v2 = VersionVector({'a': hlcA1});
      final v3 = VersionVector({'a': hlcA2});
      final v4 = VersionVector({'a': hlcA1, 'b': hlcB1});

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1, isNot(equals(v3)));
      expect(v1, isNot(equals(v4)));
      expect(v1.toString(), contains('VersionVector'));
    });
  });
}
