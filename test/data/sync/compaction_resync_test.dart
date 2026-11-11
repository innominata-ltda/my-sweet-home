import 'package:drift/drift.dart' hide Column, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/member_ack_store.dart';
import 'package:my_sweet_home/data/sync/sync_batch_factory.dart';
import 'package:my_sweet_home/data/sync/sync_compactor.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/domain/compaction_policy.dart';

import '../../fakes/fake_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Compaction Resync (RN-429, CA-5.7)', () {
    late AppDatabase dbA;
    late AppDatabase dbC;
    late FakeClock clockA;
    late FakeClock clockC;
    late SyncTableRegistry registry;
    late DriftChangeSource sourceA;
    late TombstoneStore tombstoneStoreA;
    late SyncCompactor compactorA;
    late MemberAckStore ackStoreA;
    late DriftBatchApplier applierA;
    late DriftBatchApplier applierC;
    late SyncBatchFactory factoryA;

    const testHouseholdId = 'house-resync-1';
    final initialDate = DateTime.utc(2026, 1, 1, 10, 0);

    setUp(() async {
      dbA = AppDatabase.memory();
      dbC = AppDatabase.memory();
      clockA = FakeClock(initialDate);
      clockC = FakeClock(initialDate);
      registry = SyncTableRegistryImpl();

      sourceA = DriftChangeSource(db: dbA, registry: registry);
      tombstoneStoreA = TombstoneStore(db: dbA, clock: clockA);

      ackStoreA = MemberAckStore(db: dbA, clock: clockA);

      compactorA = SyncCompactor(
        db: dbA,
        clock: clockA,
        policy: const CompactionPolicy(
          SecurityLimits(tombstoneRetention: Duration(days: 90)),
        ),
      );

      applierA = DriftBatchApplier(db: dbA, registry: registry, clock: clockA);
      applierC = DriftBatchApplier(db: dbC, registry: registry, clock: clockC);

      factoryA = SyncBatchFactory(
        db: dbA,
        changeSource: sourceA,
        tombstoneStore: tombstoneStoreA,
        compactor: compactorA,
        registry: registry,
        clock: clockA,
      );

      // Ativa casa nos 2 bancos
      await dbA
          .into(dbA.syncHouseholds)
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
      await dbC
          .into(dbC.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: testHouseholdId,
              name: 'Nossa Casa',
              localSiteId: 'site-c',
              sharedAreas: 'home,finance,catalog',
              createdAt: initialDate.toIso8601String(),
              joinedAt: initialDate.toIso8601String(),
              active: const Value(true),
            ),
          );

      // Registers members on both nodes
      for (final db in [dbA, dbC]) {
        await db.customStatement(
          '''
          INSERT INTO sync_members (id, household_id, site_id, name, is_active, joined_at, last_seen_at)
          VALUES (?, ?, ?, ?, ?, ?, ?);
          ''',
          [
            'm-a',
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
            'm-b',
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
            'm-c',
            testHouseholdId,
            'site-c',
            'Aparelho C',
            1,
            initialDate.toIso8601String(),
            initialDate.toIso8601String(),
          ],
        );
      }
    });

    tearDown(() async {
      await dbA.close();
      await dbC.close();
    });

    test('CA-5.7: Aparelho C restaurado com linha R apagada e compactada em A; A descarta R de C, e C aplica liveRowManifest apagando R', () async {
      // 1. Aparelho A possui linha viva L ('list-live') e linha R ('list-del')
      final hlcL = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 1,
        siteId: 'site-a',
      );
      final hlcR = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 2,
        siteId: 'site-a',
      );
      final hlcDel = Hlc(
        millis: initialDate.millisecondsSinceEpoch,
        counter: 3,
        siteId: 'site-a',
      );

      // Inserts L in A (row only; sync trigger writes version or insert with INSERT OR REPLACE)
      await dbA.customStatement(
        'INSERT INTO shopping_lists (id, name, created_at, updated_at) VALUES (?, ?, ?, ?);',
        [
          'list-live',
          'Supermercado',
          initialDate.toIso8601String(),
          initialDate.toIso8601String(),
        ],
      );
      await dbA.customStatement(
        'INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at) VALUES (?, ?, ?, ?, ?, ?);',
        [
          'shopping_lists',
          'list-live',
          'name',
          hlcL.pack(),
          'site-a',
          initialDate.toIso8601String(),
        ],
      );

      // A apaga R (registrando tombstone com hlcDel)
      await tombstoneStoreA.recordPurge(
        table: 'shopping_lists',
        rowId: 'list-del',
        hlc: hlcDel,
        purgedAt: initialDate,
      );

      // Members A, B, and C confirmed deletion (hlcDel)
      await ackStoreA.record(
        testHouseholdId,
        'site-a',
        VersionVector({'site-a': hlcDel}),
      );
      await ackStoreA.record(
        testHouseholdId,
        'site-b',
        VersionVector({'site-a': hlcDel}),
      );
      await ackStoreA.record(
        testHouseholdId,
        'site-c',
        VersionVector({'site-a': hlcDel}),
      );

      // Passam-se 91 dias e A executa compactor.compact()
      clockA.advance(const Duration(days: 91));
      final compReport = await compactorA.compact();
      expect(compReport.purgedTombstonesCount, 1);

      final horizonA = await compactorA.horizon();
      expect(horizonA.maxBySite['site-a'], equals(hlcDel));

      // 2. Aparelho C restaurado de backup antigo onde R ainda existe (hlcR <= horizonA)
      // Temporarily disables capture to simulate historical state restored from backup
      await dbC.customStatement(
        "INSERT OR REPLACE INTO settings (key, value) VALUES ('sync_applying_remote', '1');",
      );
      await dbC.customStatement(
        'INSERT INTO shopping_lists (id, name, created_at, updated_at) VALUES (?, ?, ?, ?);',
        [
          'list-del',
          'Feira Antiga',
          initialDate.toIso8601String(),
          initialDate.toIso8601String(),
        ],
      );
      await dbC.customStatement(
        'INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at) VALUES (?, ?, ?, ?, ?, ?);',
        [
          'shopping_lists',
          'list-del',
          'name',
          hlcR.pack(),
          'site-a',
          initialDate.toIso8601String(),
        ],
      );
      await dbC.customStatement(
        "DELETE FROM settings WHERE key = 'sync_applying_remote';",
      );

      // (Direction 1) C sends batch containing row R to A
      final batchFromC = SyncBatch(
        householdId: testHouseholdId,
        fromSiteId: 'site-c',
        senderVector: VersionVector({'site-a': hlcR}),
        changes: [
          ColumnVersion(
            table: 'shopping_lists',
            rowId: 'list-del',
            column: 'name',
            value: 'Feira Antiga',
            hlc: hlcR,
          ),
        ],
        purged: const [],
      );

      // A applies batch from C -> must discard R since R does not exist in A and hlcR <= horizonA
      final applyReportARes = await applierA.apply(batchFromC);
      expect(applyReportARes.isOk, isTrue);
      expect(applyReportARes.valueOrNull!.appliedChangesCount, 0);

      final listDelOnA = await dbA
          .customSelect(
            'SELECT * FROM shopping_lists WHERE id = ?;',
            variables: [Variable.withString('list-del')],
          )
          .get();
      expect(
        listDelOnA,
        isEmpty,
        reason: 'Compacted row R must not resurrect in A',
      );

      // (Direction 2) A generates sync batch for C using C vector (below A horizon)
      final cVector = VersionVector({'site-a': hlcR});
      final batchForCResult = await factoryA.forRecipient(cVector);
      expect(batchForCResult.isOk, isTrue);

      final batchForC = batchForCResult.valueOrNull!;
      expect(batchForC.liveRowManifest, isNotNull);
      expect(
        batchForC.liveRowManifest!['shopping_lists'],
        contains('list-live'),
      );
      expect(
        batchForC.liveRowManifest!['shopping_lists'],
        isNot(contains('list-del')),
      );

      // C aplica o lote vindo de A -> C deve inserir a linha viva L ('list-live') e DELETAR R ('list-del')
      final applyReportCRes = await applierC.apply(batchForC);
      expect(applyReportCRes.isOk, isTrue);
      expect(applyReportCRes.valueOrNull!.appliedChangesCount, greaterThan(0));

      final listDelOnC = await dbC
          .customSelect(
            'SELECT * FROM shopping_lists WHERE id = ?;',
            variables: [Variable.withString('list-del')],
          )
          .get();
      expect(
        listDelOnC,
        isEmpty,
        reason: 'Linha R ausente do liveRowManifest e <= horizonte deve ser apagada em C',
      );

      final listLiveOnC = await dbC
          .customSelect(
            'SELECT * FROM shopping_lists WHERE id = ?;',
            variables: [Variable.withString('list-live')],
          )
          .get();
      expect(
        listLiveOnC,
        isNotEmpty,
        reason: 'Live row L must be present in C after resync',
      );
    });
  });
}
