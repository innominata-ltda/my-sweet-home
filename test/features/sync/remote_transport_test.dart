import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/remote_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_cloud_storage_port.dart';
import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  group('T-17 / RF-127 — Asynchronous Remote Transport (ADR-0011, CA-8.1, CA-8.2)', () {
    late AppDatabase dbA;
    late AppDatabase dbB;
    late FakeHouseholdKeyStore keyStoreA;
    late FakeHouseholdKeyStore keyStoreB;
    late FakeSettingsRepository settingsRepoA;
    late FakeSettingsRepository settingsRepoB;
    late FakeClock clock;
    late SyncTableRegistry registry;
    late SyncBatchCodecImpl codec;
    late HouseholdKey sharedKey;
    late FakeCloudStoragePort cloudMailbox;

    late DriftHouseholdRepository repoA;
    late DriftHouseholdRepository repoB;
    late RemoteSyncTransport transportA;
    late RemoteSyncTransport transportB;

    setUp(() async {
      dbA = AppDatabase.memory();
      dbB = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 15, 10, 0));
      registry = SyncTableRegistryImpl();
      codec = SyncBatchCodecImpl();
      sharedKey = HouseholdKey(List.generate(32, (i) => i));
      cloudMailbox = FakeCloudStoragePort();

      keyStoreA = FakeHouseholdKeyStore(sharedKey);
      keyStoreB = FakeHouseholdKeyStore(sharedKey);
      settingsRepoA = FakeSettingsRepository(householdSyncRemoteAllowed: true);
      settingsRepoB = FakeSettingsRepository(householdSyncRemoteAllowed: true);

      repoA = DriftHouseholdRepository(
        db: dbA,
        keyStore: keyStoreA,
        settingsRepository: settingsRepoA,
        clock: clock,
      );

      repoB = DriftHouseholdRepository(
        db: dbB,
        keyStore: keyStoreB,
        settingsRepository: settingsRepoB,
        clock: clock,
      );

      final houseA = (await repoA.createHousehold(
        name: 'Casa Compartilhada',
        deviceName: 'Aparelho A',
        sharedAreas: {SyncArea.home, SyncArea.finance},
        key: sharedKey,
      )).valueOrNull!;

      await dbB
          .into(dbB.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: houseA.id,
              name: 'Casa Compartilhada',
              localSiteId: 'site-device-b',
              sharedAreas: 'catalog,home,finance',
              createdAt: clock.nowUtc().toIso8601String(),
              joinedAt: clock.nowUtc().toIso8601String(),
              active: const Value(true),
            ),
          );
      await keyStoreB.write(sharedKey);

      transportA = RemoteSyncTransport(
        householdRepository: repoA,
        keyStore: keyStoreA,
        changeSource: DriftChangeSource(db: dbA, registry: registry),
        tombstoneStore: TombstoneStore(db: dbA, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbA,
          registry: registry,
          changeCapture: ChangeCapture(db: dbA, clock: clock),
          clock: clock,
        ),
        settingsRepository: settingsRepoA,
        cloudStoragePort: cloudMailbox,
        clock: clock,
      );

      transportB = RemoteSyncTransport(
        householdRepository: repoB,
        keyStore: keyStoreB,
        changeSource: DriftChangeSource(db: dbB, registry: registry),
        tombstoneStore: TombstoneStore(db: dbB, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbB,
          registry: registry,
          changeCapture: ChangeCapture(db: dbB, clock: clock),
          clock: clock,
        ),
        settingsRepository: settingsRepoB,
        cloudStoragePort: cloudMailbox,
        clock: clock,
      );
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    test(
      'start, stop and watchPeers behave as static async transport',
      () async {
        expect((await transportA.start()).isOk, isTrue);
        expect((await transportA.stop()).isOk, isTrue);
        expect(await transportA.watchPeers().first, isEmpty);
      },
    );

    test(
      'CA-8.1: consentimento negado impede qualquer tráfego com a nuvem',
      () async {
        settingsRepoA.householdSyncRemoteAllowed = false;

        final res = await transportA.syncNow();
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<PermissionFailure>());

        expect(cloudMailbox.uploadCallCount, 0);
        expect(cloudMailbox.downloadCallCount, 0);
        expect(cloudMailbox.listCallCount, 0);
      },
    );

    test('without active household does not execute undue sync', () async {
      final emptyDb = AppDatabase.memory();
      addTearDown(emptyDb.close);
      final emptyRepo = DriftHouseholdRepository(
        db: emptyDb,
        keyStore: FakeHouseholdKeyStore(null),
        settingsRepository: settingsRepoA,
        clock: clock,
      );

      final emptyTransport = RemoteSyncTransport(
        householdRepository: emptyRepo,
        keyStore: FakeHouseholdKeyStore(null),
        changeSource: DriftChangeSource(db: emptyDb, registry: registry),
        tombstoneStore: TombstoneStore(db: emptyDb, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: emptyDb,
          registry: registry,
          changeCapture: ChangeCapture(db: emptyDb, clock: clock),
          clock: clock,
        ),
        settingsRepository: settingsRepoA,
        cloudStoragePort: cloudMailbox,
        clock: clock,
      );

      final report = await emptyTransport.syncNow();
      expect(report.isOk, isTrue);
      expect(report.valueOrNull!.sentChangesCount, 0);
    });

    test(
      'with active household but no key in keystore returns HouseholdFailure',
      () async {
        final missingKeyStore = FakeHouseholdKeyStore(null);
        final missingKeyTransport = RemoteSyncTransport(
          householdRepository: repoA,
          keyStore: missingKeyStore,
          changeSource: DriftChangeSource(db: dbA, registry: registry),
          tombstoneStore: TombstoneStore(db: dbA, clock: clock),
          codec: codec,
          batchApplier: DriftBatchApplier(
            db: dbA,
            registry: registry,
            changeCapture: ChangeCapture(db: dbA, clock: clock),
            clock: clock,
          ),
          settingsRepository: settingsRepoA,
          cloudStoragePort: cloudMailbox,
          clock: clock,
        );

        final res = await missingKeyTransport.syncNow();
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<HouseholdFailure>());
      },
    );

    test('irrelevant, own or corrupted files in cloud are ignored', () async {
      final houseA = (await repoA.getHousehold()).valueOrNull!;
      // 1. File from another household or invalid extension
      cloudMailbox.remoteFiles['sync_outra-casa_site1_123.syncbatch'] = 'blob';
      cloudMailbox.remoteFiles['sync_${houseA.id}_site1_123.txt'] = 'ignorado';
      // 2. Own device file
      cloudMailbox
              .remoteFiles['sync_${houseA.id}_${houseA.localSiteId}_123.syncbatch'] =
          'ignorado';
      // 3. Other device file with invalid content (non-base64)
      cloudMailbox
              .remoteFiles['sync_${houseA.id}_site-device-outro_123.syncbatch'] =
          'invalid-base64!';

      final report = await transportA.syncNow();
      expect(report.isOk, isTrue);
      expect(report.valueOrNull!.appliedChangesCount, 0);
    });

    test('CA-8.2: A modifies data offline and uploads; 1h later B opens and receives all asynchronously', () async {
      // 1. Aparelho A cadastra uma tarefa na casa
      await dbA
          .into(dbA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-remota-1',
              title: 'Trocar filtro de água',
              createdAt: Value(clock.nowUtc().toIso8601String()),
              updatedAt: Value(clock.nowUtc().toIso8601String()),
            ),
          );

      // 2. Aparelho A sincroniza para a caixa postal na nuvem
      final reportA = await transportA.syncNow();
      expect(reportA.isOk, isTrue);
      expect(reportA.valueOrNull!.sentChangesCount, greaterThanOrEqualTo(1));

      // Verify file was saved encrypted in storage
      expect(cloudMailbox.remoteFiles, isNotEmpty);
      final remoteFileName = cloudMailbox.remoteFiles.keys.first;
      expect(remoteFileName, contains('.syncbatch'));

      // 3. Simulates closing app A (A offline) and 1 hour advance
      clock.advance(const Duration(hours: 1));

      // 4. Aparelho B abre o app em outra rede e executa syncNow()
      final reportB = await transportB.syncNow();
      expect(reportB.isOk, isTrue);
      expect(reportB.valueOrNull!.appliedChangesCount, greaterThanOrEqualTo(1));

      // 5. Verifica que B recebeu a tarefa sem que A estivesse online simultaneamente
      final taskOnB = await (dbB.select(
        dbB.tasks,
      )..where((t) => t.id.equals('task-remota-1'))).getSingleOrNull();

      expect(taskOnB, isNotNull);
      expect(taskOnB!.title, 'Trocar filtro de água');
    });

    test(
      'T-B02: falha em uploadBackup propaga o erro e não reporta sucesso falso',
      () async {
        await dbA
            .into(dbA.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-upload-fail',
                title: 'Tarefa que vai falhar upload',
                createdAt: Value(clock.nowUtc().toIso8601String()),
                updatedAt: Value(clock.nowUtc().toIso8601String()),
              ),
            );

        cloudMailbox.shouldFail = true;

        final res = await transportA.syncNow();
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<NetworkFailure>());
      },
    );

    test(
      'T-B02: failure in listBackups propagates error without silencing',
      () async {
        cloudMailbox.shouldFail = true;

        final res = await transportA.syncNow();
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<NetworkFailure>());
      },
    );

    test('T-B02: peersContactedCount is 0 when no batch from another device is received', () async {
      // Nenhum arquivo no storage
      cloudMailbox.remoteFiles.clear();

      final report = await transportA.syncNow();
      expect(report.isOk, isTrue);
      expect(report.valueOrNull!.peersContactedCount, 0);
    });
  });
}
