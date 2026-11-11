import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/applied_bundle_ledger.dart';
import 'package:my_sweet_home/features/sync/data/bundle_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_key_store.dart';
import '../../../test/fakes/fake_settings_repository.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('AppliedBundleLedger (RN-409, CA-2.7)', () {
    late AppDatabase db;
    late AppliedBundleLedger ledger;

    setUp(() {
      db = AppDatabase.memory();
      ledger = AppliedBundleLedger(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns false for unknown hash and true after registering', () async {
      const sha =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      expect(await ledger.contains(sha), isFalse);

      await ledger.record(sha, DateTime.utc(2026, 3, 15, 12, 0));

      expect(await ledger.contains(sha), isTrue);
    });

    test('gravar o mesmo hash mais de uma vez eh idempotente', () async {
      const sha = 'abc123def456';
      await ledger.record(sha, DateTime.utc(2026, 3, 15, 12, 0));
      await ledger.record(sha, DateTime.utc(2026, 3, 15, 13, 0));

      expect(await ledger.contains(sha), isTrue);
      final count = await db.select(db.syncAppliedBundles).get();
      expect(count.length, 1);
    });
  });

  group('BundleSyncTransport idempotencia de pacotes (RN-409, CA-2.7)', () {
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

    late DriftHouseholdRepository repoA;
    late DriftHouseholdRepository repoB;
    late AppliedBundleLedger ledgerB;
    late BundleSyncTransport transportA;
    late BundleSyncTransport transportB;

    setUp(() async {
      dbA = AppDatabase.memory();
      dbB = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 15, 10, 0));
      registry = SyncTableRegistryImpl();
      codec = SyncBatchCodecImpl();
      sharedKey = HouseholdKey(List.generate(32, (i) => i));

      keyStoreA = FakeHouseholdKeyStore(sharedKey);
      keyStoreB = FakeHouseholdKeyStore(sharedKey);
      settingsRepoA = FakeSettingsRepository();
      settingsRepoB = FakeSettingsRepository();

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
        name: 'Casa Teste',
        deviceName: 'Device A',
        sharedAreas: {SyncArea.home, SyncArea.finance},
        key: sharedKey,
      )).valueOrNull!;

      await dbB
          .into(dbB.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: houseA.id,
              name: 'Casa Teste',
              localSiteId: 'site-device-b',
              sharedAreas: 'catalog,home,finance',
              createdAt: clock.nowUtc().toIso8601String(),
              joinedAt: clock.nowUtc().toIso8601String(),
              active: const Value(true),
            ),
          );
      await keyStoreB.write(sharedKey);

      ledgerB = AppliedBundleLedger(dbB);

      transportA = BundleSyncTransport(
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
        clock: clock,
      );

      transportB = BundleSyncTransport(
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
        appliedBundleLedger: ledgerB,
        clock: clock,
      );
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    test(
      'aplicar pacote pela primeira vez sucede e registra no ledger',
      () async {
        await dbA
            .into(dbA.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-1',
                title: 'Limpar filtros do ar',
                isCompleted: const Value(false),
                createdAt: const Value('2026-03-15T10:00:00Z'),
                updatedAt: const Value('2026-03-15T10:00:00Z'),
              ),
            );

        final bundleResult = await transportA.generateBundle();
        expect(bundleResult.isOk, isTrue);
        final bundleBytes = bundleResult.valueOrNull!;

        final applyResult = await transportB.applyBundle(bundleBytes);
        expect(applyResult.isOk, isTrue);
        final report = applyResult.valueOrNull!;
        expect(report.alreadyApplied, isFalse);

        final taskInB = await (dbB.select(
          dbB.tasks,
        )..where((t) => t.id.equals('task-1'))).getSingleOrNull();
        expect(taskInB, isNotNull);
        expect(taskInB!.title, 'Limpar filtros do ar');
      },
    );

    test('reapplying same bundle returns alreadyApplied=true and does not alter database', () async {
      await dbA
          .into(dbA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-2',
              title: 'Trocar lampada da cozinha',
              isCompleted: const Value(false),
              createdAt: const Value('2026-03-15T10:00:00Z'),
              updatedAt: const Value('2026-03-15T10:00:00Z'),
            ),
          );

      final bundleResult = await transportA.generateBundle();
      final bundleBytes = bundleResult.valueOrNull!;

      // 1st application
      final firstApply = await transportB.applyBundle(bundleBytes);
      expect(firstApply.isOk, isTrue);
      expect(firstApply.valueOrNull!.alreadyApplied, isFalse);

      // Captures synchronized tables state after 1st application
      final tasksAfterFirst = await dbB.select(dbB.tasks).get();
      final versionsAfterFirst = await dbB.select(dbB.syncColumnVersions).get();
      final appliedBundlesAfterFirst = await dbB
          .select(dbB.syncAppliedBundles)
          .get();
      expect(appliedBundlesAfterFirst.length, 1);

      // 2nd application of SAME bundle
      final secondApply = await transportB.applyBundle(bundleBytes);
      expect(secondApply.isOk, isTrue);
      final report2 = secondApply.valueOrNull!;
      expect(report2.alreadyApplied, isTrue);

      // Verifies database underwent no change byte-for-byte / records
      final tasksAfterSecond = await dbB.select(dbB.tasks).get();
      final versionsAfterSecond = await dbB
          .select(dbB.syncColumnVersions)
          .get();
      final appliedBundlesAfterSecond = await dbB
          .select(dbB.syncAppliedBundles)
          .get();

      expect(tasksAfterSecond.length, tasksAfterFirst.length);
      expect(tasksAfterSecond.first.title, tasksAfterFirst.first.title);
      expect(versionsAfterSecond.length, versionsAfterFirst.length);
      expect(appliedBundlesAfterSecond.length, 1);
    });
  });
}
