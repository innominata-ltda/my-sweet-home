import 'package:drift/drift.dart' hide Column, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/sync_now_usecase.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_household_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'T-11 / RF-122 — Local Network Convergence (CA-3.1, CA-3.2, CA-6.2)',
    () {
      late AppDatabase dbA;
      late AppDatabase dbB;
      late FakeHouseholdRepository repoA;
      late FakeHouseholdRepository repoB;
      late FakeHouseholdKeyStore keyStoreA;
      late FakeHouseholdKeyStore keyStoreB;
      late ChangeCapture captureA;
      late ChangeCapture captureB;
      late DriftChangeSource sourceA;
      late DriftChangeSource sourceB;
      late TombstoneStore tombstoneStoreA;
      late TombstoneStore tombstoneStoreB;
      late DriftBatchApplier applierA;
      late DriftBatchApplier applierB;
      late LanSyncTransport transportA;
      late LanSyncTransport transportB;

      const testHouseholdId = 'house-sync-123';
      final commonKey = HouseholdKey(
        Uint8List.fromList(List.generate(32, (i) => 42)),
      );
      final now = DateTime.utc(2026, 10, 23, 10, 0);

      setUp(() async {
        dbA = AppDatabase.memory();
        dbB = AppDatabase.memory();

        final registry = SyncTableRegistryImpl();

        // Ativa casa no banco para ligar triggers de captura
        await dbA
            .into(dbA.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: testHouseholdId,
                name: 'Nossa Casa',
                localSiteId: 'site-a',
                sharedAreas: 'home,finance,catalog',
                createdAt: now.toIso8601String(),
                joinedAt: now.toIso8601String(),
                active: const Value(true),
              ),
            );
        await dbB
            .into(dbB.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: testHouseholdId,
                name: 'Nossa Casa',
                localSiteId: 'site-b',
                sharedAreas: 'home,finance,catalog',
                createdAt: now.toIso8601String(),
                joinedAt: now.toIso8601String(),
                active: const Value(true),
              ),
            );

        repoA = FakeHouseholdRepository(
          initialHousehold: Household(
            id: testHouseholdId,
            name: 'Nossa Casa',
            localSiteId: 'site-a',
            sharedAreas: const {SyncArea.home, SyncArea.finance},
            createdAt: now,
            joinedAt: now,
          ),
        );
        repoB = FakeHouseholdRepository(
          initialHousehold: Household(
            id: testHouseholdId,
            name: 'Nossa Casa',
            localSiteId: 'site-b',
            sharedAreas: const {SyncArea.home, SyncArea.finance},
            createdAt: now,
            joinedAt: now,
          ),
        );

        keyStoreA = FakeHouseholdKeyStore(commonKey);
        keyStoreB = FakeHouseholdKeyStore(commonKey);

        final clockA = FakeClock(now);
        final clockB = FakeClock(now);

        captureA = ChangeCapture(db: dbA, clock: clockA);
        captureB = ChangeCapture(db: dbB, clock: clockB);

        tombstoneStoreA = TombstoneStore(db: dbA);
        tombstoneStoreB = TombstoneStore(db: dbB);

        sourceA = DriftChangeSource(db: dbA, registry: registry);
        sourceB = DriftChangeSource(db: dbB, registry: registry);

        applierA = DriftBatchApplier(
          db: dbA,
          registry: registry,
          changeCapture: captureA,
          clock: clockA,
        );
        applierB = DriftBatchApplier(
          db: dbB,
          registry: registry,
          changeCapture: captureB,
          clock: clockB,
        );

        final codec = SyncBatchCodecImpl();

        transportA = LanSyncTransport(
          householdRepository: repoA,
          keyStore: keyStoreA,
          changeSource: sourceA,
          tombstoneStore: tombstoneStoreA,
          codec: codec,
          batchApplier: applierA,
        );

        transportB = LanSyncTransport(
          householdRepository: repoB,
          keyStore: keyStoreB,
          changeSource: sourceB,
          tombstoneStore: tombstoneStoreB,
          codec: codec,
          batchApplier: applierB,
        );
      });

      tearDown(() async {
        transportA.dispose();
        transportB.dispose();
        repoA.dispose();
        repoB.dispose();
        await dbA.close();
        await dbB.close();
      });

      test('CA-3.1: A e B na mesma rede; A atualiza item e B recebe via LanSyncTransport', () async {
        // 1. Inicia o servidor de B
        final startRes = await transportB.start();
        expect(startRes.isOk, isTrue);
        final portB = transportB.listeningPort!;
        expect(portB, greaterThan(0));

        // 2. Aparelho A registra B como par descoberto
        transportA.registerPeer(
          DiscoveredPeer(siteId: 'site-b', address: '127.0.0.1', port: portB),
        );

        // 3. A cria uma tarefa localmente
        await dbA
            .into(dbA.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-clean',
                title: 'Limpar cozinha',
                isCompleted: const Value(false),
                createdAt: Value(now.toIso8601String()),
                updatedAt: Value(now.toIso8601String()),
              ),
            );

        // 4. A triggers synchronization now
        final useCaseA = SyncNowUseCase(transportA);
        final syncRes = await useCaseA.execute();
        expect(syncRes.isOk, isTrue);
        expect(syncRes.valueOrNull!.sentChangesCount, greaterThan(0));
        expect(syncRes.valueOrNull!.peersContactedCount, 1);

        // 5. Aguarda processamento no socket de B
        await Future<void>.delayed(const Duration(milliseconds: 300));

        // B agora possui a tarefa criada por A (CA-3.1)
        final taskOnB = await (dbB.select(
          dbB.tasks,
        )..where((t) => t.id.equals('task-clean'))).getSingleOrNull();
        expect(taskOnB, isNotNull);
        expect(taskOnB!.title, 'Limpar cozinha');
      });

      test('CA-3.2: A and B edit offline for 3 days and converge without intervention on sync', () async {
        // Day 1: A creates a task and edits description
        final hlcA1 = Hlc.parse('2026-10-20T12:00:00.000Z:00001:site-a');
        final batchA1 = SyncBatch(
          householdId: testHouseholdId,
          fromSiteId: 'site-a',
          senderVector: VersionVector({'site-a': hlcA1}),
          changes: [
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-shared',
              column: 'title',
              value: 'Comprar frutas',
              hlc: hlcA1,
            ),
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-shared',
              column: 'is_completed',
              value: false,
              hlc: hlcA1,
            ),
          ],
        );
        await applierA.apply(batchA1);

        // Day 2: B offline marks task completed (higher HLC on is_completed)
        final hlcB2 = Hlc.parse('2026-10-21T15:00:00.000Z:00001:site-b');
        final batchB2 = SyncBatch(
          householdId: testHouseholdId,
          fromSiteId: 'site-b',
          senderVector: VersionVector({'site-b': hlcB2}),
          changes: [
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-shared',
              column: 'title',
              value: 'Comprar frutas',
              hlc: hlcA1,
            ),
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-shared',
              column: 'is_completed',
              value: true,
              hlc: hlcB2,
            ),
          ],
        );
        await applierB.apply(batchB2);

        // Day 3: A edits title with later HLC than A1 and B2
        final hlcA3 = Hlc.parse('2026-10-22T09:00:00.000Z:00001:site-a');
        final batchA3 = SyncBatch(
          householdId: testHouseholdId,
          fromSiteId: 'site-a',
          senderVector: VersionVector({'site-a': hlcA3}),
          changes: [
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-shared',
              column: 'title',
              value: 'Comprar frutas frescas',
              hlc: hlcA3,
            ),
          ],
        );
        await applierA.apply(batchA3);

        // Agora A e B sincronizam de volta: A aplica B2, B aplica A1 e A3
        final repB2onA = await applierA.apply(batchB2);
        expect(repB2onA.isOk, isTrue);
        final repA1onB = await applierB.apply(batchA1);
        expect(repA1onB.isOk, isTrue);
        final repA3onB = await applierB.apply(batchA3);
        expect(repA3onB.isOk, isTrue);

        // Perfect Convergence Verification (CA-3.2):
        final taskA = await (dbA.select(
          dbA.tasks,
        )..where((t) => t.id.equals('task-shared'))).getSingle();
        final taskB = await (dbB.select(
          dbB.tasks,
        )..where((t) => t.id.equals('task-shared'))).getSingle();

        expect(taskA.title, 'Comprar frutas frescas');
        expect(taskB.title, 'Comprar frutas frescas');
        expect(taskA.isCompleted, isTrue);
        expect(taskB.isCompleted, isTrue);
      });

      test('CA-6.2: Network failure during sync does not crash app and returns handled error', () async {
        // Registers peer with unreachable port (simulating network failure/timeout)
        transportA.registerPeer(
          const DiscoveredPeer(
            siteId: 'site-offline',
            address: '127.0.0.1',
            port: 1,
          ),
        );

        final useCaseA = SyncNowUseCase(transportA);
        final res = await useCaseA.execute();

        // Does not throw unhandled exception; returns Ok with 0 sent or handles normally
        expect(res.isOk, isTrue);
        expect(res.valueOrNull!.sentChangesCount, 0);
      });
    },
  );
}
