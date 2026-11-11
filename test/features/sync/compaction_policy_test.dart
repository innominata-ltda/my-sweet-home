import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/domain/compaction_policy.dart';

void main() {
  group('CompactionPolicy (RN-428, RN-429, CA-5.6)', () {
    const limits = SecurityLimits(tombstoneRetention: Duration(days: 90));
    const policy = CompactionPolicy(limits);
    final nowUtc = DateTime.utc(2026, 10, 30, 12, 0);

    final hlcTombstone = Hlc(
      millis: DateTime.utc(2026, 7, 30, 12, 0).millisecondsSinceEpoch,
      counter: 1,
      siteId: 'site-a',
    );
    final hlcAcked = Hlc(
      millis: DateTime.utc(2026, 7, 30, 12, 0).millisecondsSinceEpoch,
      counter: 2,
      siteId: 'site-a',
    );
    final hlcBehind = Hlc(
      millis: DateTime.utc(2026, 7, 29, 12, 0).millisecondsSinceEpoch,
      counter: 0,
      siteId: 'site-a',
    );

    test('CA-5.6: tombstone with 91 days and all active members confirmed returns true', () {
      final purgedAt91Days = nowUtc
          .subtract(const Duration(days: 91))
          .toIso8601String();
      final tombstone = RowTombstone(
        id: 'tomb-1',
        table: 'expenses',
        rowId: 'exp-1',
        hlc: hlcTombstone,
        purgedAt: purgedAt91Days,
      );

      final acks = <String, VersionVector>{
        'site-a': VersionVector({'site-a': hlcAcked}),
        'site-b': VersionVector({'site-a': hlcTombstone}),
        'site-c': VersionVector({'site-a': hlcAcked}),
      };

      expect(policy.canPurgeTombstone(tombstone, acks, nowUtc), isTrue);
    });

    test(
      'CA-5.6: lápide com 89 dias retorna false mesmo com todos os acks',
      () {
        final purgedAt89Days = nowUtc
            .subtract(const Duration(days: 89))
            .toIso8601String();
        final tombstone = RowTombstone(
          id: 'tomb-2',
          table: 'expenses',
          rowId: 'exp-2',
          hlc: hlcTombstone,
          purgedAt: purgedAt89Days,
        );

        final acks = <String, VersionVector>{
          'site-a': VersionVector({'site-a': hlcAcked}),
          'site-b': VersionVector({'site-a': hlcAcked}),
        };

        expect(policy.canPurgeTombstone(tombstone, acks, nowUtc), isFalse);
      },
    );

    test('CA-5.6: tombstone with 91 days but missing confirmation from active member returns false', () {
      final purgedAt91Days = nowUtc
          .subtract(const Duration(days: 91))
          .toIso8601String();
      final tombstone = RowTombstone(
        id: 'tomb-3',
        table: 'expenses',
        rowId: 'exp-3',
        hlc: hlcTombstone,
        purgedAt: purgedAt91Days,
      );

      final acksMissingOne = <String, VersionVector>{
        'site-a': VersionVector({'site-a': hlcAcked}),
        'site-b': VersionVector({'site-a': hlcBehind}), // behind tombstone HLC
      };

      expect(
        policy.canPurgeTombstone(tombstone, acksMissingOne, nowUtc),
        isFalse,
      );

      final acksEmptySite = <String, VersionVector>{
        'site-a': VersionVector({'site-a': hlcAcked}),
        'site-b': VersionVector.empty, // nunca viu site-a
      };

      expect(
        policy.canPurgeTombstone(tombstone, acksEmptySite, nowUtc),
        isFalse,
      );
    });
  });
}
