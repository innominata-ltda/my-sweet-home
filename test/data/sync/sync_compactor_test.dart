import 'package:drift/drift.dart' hide Column;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/member_ack_store.dart';
import 'package:my_sweet_home/data/sync/sync_compactor.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/domain/compaction_policy.dart';

import '../../fakes/fake_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncCompactor & MemberAckStore (RN-428, RN-429, CA-5.5, CA-5.6)', () {
    late AppDatabase db;
    late FakeClock clock;
    late SyncCompactor compactor;
    late MemberAckStore ackStore;
    late TombstoneStore tombstoneStore;

    const testHouseholdId = 'house-compaction-1';
    final initialDate = DateTime.utc(2026, 1, 1, 10, 0);

    setUp(() async {
      db = AppDatabase.memory();
      clock = FakeClock(initialDate);
      compactor = SyncCompactor(
        db: db,
        clock: clock,
        policy: const CompactionPolicy(
          SecurityLimits(tombstoneRetention: Duration(days: 90)),
        ),
      );
      ackStore = MemberAckStore(db: db, clock: clock);
      tombstoneStore = TombstoneStore(db: db, clock: clock);

      // Ativa casa no banco
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: testHouseholdId,
              name: 'Nossa Casa',
              localSiteId: 'site-a',
              sharedAreas: 'home,finance,catalog',
              createdAt: initialDate.toIso8601String(),
              joinedAt: initialDate.toIso8601String(),
              active: const Value(true),
            ),
          );

      // Membros da casa: site-a (local), site-b (ativo), site-c (ativo)
      await db.customStatement(
        '''
        INSERT INTO sync_members (id, household_id, site_id, name, is_active, joined_at, last_seen_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          'member-a',
          testHouseholdId,
          'site-a',
          'Aparelho A',
          1,
          initialDate.toIso8601String(),
          initialDate.toIso8601String(),
        ],
      );
      await db.customStatement(
        '''
        INSERT INTO sync_members (id, household_id, site_id, name, is_active, joined_at, last_seen_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          'member-b',
          testHouseholdId,
          'site-b',
          'Aparelho B',
          1,
          initialDate.toIso8601String(),
          initialDate.toIso8601String(),
        ],
      );
      await db.customStatement(
        '''
        INSERT INTO sync_members (id, household_id, site_id, name, is_active, joined_at, last_seen_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          'member-c',
          testHouseholdId,
          'site-c',
          'Aparelho C',
          1,
          initialDate.toIso8601String(),
          initialDate.toIso8601String(),
        ],
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('CA-5.5: 3 membros ativos confirmaram versao (e lapide > 90 dias) -> lapide e sync_column_versions removidos e horizonte avanca', () async {
      final tHlc = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 1,
        siteId: 'site-a',
      );

      // Insere lapide e versoes de coluna para a linha 'room-1' em 'rooms'
      await tombstoneStore.recordPurge(
        table: 'rooms',
        rowId: 'room-1',
        hlc: tHlc,
        purgedAt: initialDate,
      );
      await db.customStatement(
        '''
          INSERT INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at)
          VALUES (?, ?, ?, ?, ?, ?);
          ''',
        [
          'rooms',
          'room-1',
          'name',
          tHlc.pack(),
          'site-a',
          initialDate.toIso8601String(),
        ],
      );

      // Membro A (local), B e C confirmam HLC >= tHlc
      await ackStore.record(
        testHouseholdId,
        'site-a',
        VersionVector({'site-a': tHlc}),
      );
      await ackStore.record(
        testHouseholdId,
        'site-b',
        VersionVector({'site-a': tHlc}),
      );
      await ackStore.record(
        testHouseholdId,
        'site-c',
        VersionVector({'site-a': tHlc}),
      );

      // Avanca relogio em 91 dias (> 90 dias de retencao)
      clock.advance(const Duration(days: 91));

      final report = await compactor.compact();

      expect(report.purgedTombstonesCount, 1);
      expect(report.purgedColumnVersionsCount, 1);

      // Tombstone and column were removed
      final remainingTombstones = await tombstoneStore.getAllTombstones();
      expect(remainingTombstones, isEmpty);

      final colVersions = await db
          .customSelect(
            'SELECT * FROM sync_column_versions WHERE row_id = ?;',
            variables: [Variable.withString('room-1')],
          )
          .get();
      expect(colVersions, isEmpty);

      // Horizonte de compactacao avancou para tHlc
      final horizon = await compactor.horizon();
      expect(horizon.maxBySite['site-a'], equals(tHlc));
    });

    test(
      'CA-5.6: Tombstone with 89 days is not removed by compact()',
      () async {
        final tHlc = Hlc(
          millis: initialDate.millisecondsSinceEpoch,
          counter: 1,
          siteId: 'site-a',
        );

        await tombstoneStore.recordPurge(
          table: 'rooms',
          rowId: 'room-1',
          hlc: tHlc,
          purgedAt: initialDate,
        );

        // Todos os membros ativos confirmaram
        for (final site in ['site-a', 'site-b', 'site-c']) {
          await ackStore.record(
            testHouseholdId,
            site,
            VersionVector({'site-a': tHlc}),
          );
        }

        // Advances only 89 days
        clock.advance(const Duration(days: 89));

        final report = await compactor.compact();
        expect(report.purgedTombstonesCount, 0);

        final tombstones = await tombstoneStore.getAllTombstones();
        expect(tombstones.length, 1);
      },
    );

    test('CA-5.6: Missing confirmation from an active member does not remove tombstone', () async {
      final tHlc = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 1,
        siteId: 'site-a',
      );

      await tombstoneStore.recordPurge(
        table: 'rooms',
        rowId: 'room-1',
        hlc: tHlc,
        purgedAt: initialDate,
      );

      // Only site-a and site-b confirmed; site-c has not yet
      await ackStore.record(
        testHouseholdId,
        'site-a',
        VersionVector({'site-a': tHlc}),
      );
      await ackStore.record(
        testHouseholdId,
        'site-b',
        VersionVector({'site-a': tHlc}),
      );

      clock.advance(const Duration(days: 91));

      final report = await compactor.compact();
      expect(report.purgedTombstonesCount, 0);

      final tombstones = await tombstoneStore.getAllTombstones();
      expect(tombstones.length, 1);
    });

    test('CA-5.6 / RN-429: Inactive member (is_active = 0) is ignored in compaction', () async {
      // Desativa site-c
      await db.customStatement(
        'UPDATE sync_members SET is_active = 0 WHERE site_id = ?;',
        ['site-c'],
      );

      final tHlc = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 1,
        siteId: 'site-a',
      );

      await tombstoneStore.recordPurge(
        table: 'rooms',
        rowId: 'room-1',
        hlc: tHlc,
        purgedAt: initialDate,
      );

      // Only site-a and site-b confirmed; site-c is inactive and did not confirm
      await ackStore.record(
        testHouseholdId,
        'site-a',
        VersionVector({'site-a': tHlc}),
      );
      await ackStore.record(
        testHouseholdId,
        'site-b',
        VersionVector({'site-a': tHlc}),
      );

      clock.advance(const Duration(days: 91));

      final report = await compactor.compact();
      expect(report.purgedTombstonesCount, 1);

      final tombstones = await tombstoneStore.getAllTombstones();
      expect(tombstones, isEmpty);
    });
  });
}
