import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/sync/data/lan/discovery_tag.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

void main() {
  group('DiscoveryTag (RN-411, CA-2.9)', () {
    late HouseholdKey keyA;
    late HouseholdKey keyB;
    late DiscoveryTag discoveryTagA;
    late DiscoveryTag discoveryTagB;

    setUp(() {
      keyA = HouseholdKey(List.generate(32, (i) => i));
      keyB = HouseholdKey(List.generate(32, (i) => i ^ 0xAA));
      discoveryTagA = DiscoveryTag(keyA);
      discoveryTagB = DiscoveryTag(keyB);
    });

    test(
      'tagFor generates 22-character URL-safe tag based on UTC day (RN-411)',
      () async {
        final now = DateTime.utc(2026, 10, 30, 14, 30, 0);
        final tag = await discoveryTagA.tagFor(now);

        expect(tag.length, equals(22));
        // Base64URL has no '+' or '/' and no '=' padding
        expect(tag.contains('+'), isFalse);
        expect(tag.contains('/'), isFalse);
        expect(tag.contains('='), isFalse);
      },
    );

    test('today tag differs from tomorrow tag for the same household (RN-411, CA-2.9)', () async {
      final today = DateTime.utc(2026, 10, 30, 10, 0, 0);
      final tomorrow = DateTime.utc(2026, 10, 31, 10, 0, 0);

      final tagToday = await discoveryTagA.tagFor(today);
      final tagTomorrow = await discoveryTagA.tagFor(tomorrow);

      expect(tagToday, isNot(equals(tagTomorrow)));
    });

    test('same day at different times generates the same tag', () async {
      final t1 = DateTime.utc(2026, 10, 30, 1, 0, 0);
      final t2 = DateTime.utc(2026, 10, 30, 23, 59, 59);

      final tag1 = await discoveryTagA.tagFor(t1);
      final tag2 = await discoveryTagA.tagFor(t2);

      expect(tag1, equals(tag2));
    });

    test('different keys for the same date generate distinct tags', () async {
      final now = DateTime.utc(2026, 10, 30, 12, 0, 0);

      final tagA = await discoveryTagA.tagFor(now);
      final tagB = await discoveryTagB.tagFor(now);

      expect(tagA, isNot(equals(tagB)));
    });

    test(
      'acceptedAt accepts today and yesterday tags (day rollover)',
      () async {
        final today = DateTime.utc(2026, 10, 30, 12, 0, 0);
        final yesterday = DateTime.utc(2026, 10, 29, 12, 0, 0);
        final tomorrow = DateTime.utc(2026, 10, 31, 12, 0, 0);

        final accepted = await discoveryTagA.acceptedAt(today);
        final tagToday = await discoveryTagA.tagFor(today);
        final tagYesterday = await discoveryTagA.tagFor(yesterday);
        final tagTomorrow = await discoveryTagA.tagFor(tomorrow);

        expect(accepted.contains(tagToday), isTrue);
        expect(accepted.contains(tagYesterday), isTrue);
        expect(accepted.contains(tagTomorrow), isFalse);
        expect(accepted.length, equals(2));
      },
    );
  });
}
