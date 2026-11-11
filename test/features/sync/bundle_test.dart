import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/bundle_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_key_store.dart';
import '../../../test/fakes/fake_settings_repository.dart';

void main() {
  group(
    'T-12 / RF-123 — Pacote de Atualização (.mshsync) (CA-4.1, CA-4.2)',
    () {
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

        // Criar a mesma casa em A e B
        final houseA = (await repoA.createHousehold(
          name: 'Casa Compartilhada',
          deviceName: 'Aparelho A',
          sharedAreas: {SyncArea.home, SyncArea.finance},
          key: sharedKey,
        )).valueOrNull!;

        // Cadastrar em B com o mesmo householdId mas siteId diferente
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
        );
      });

      tearDown(() async {
        await dbA.close();
        await dbB.close();
      });

      test('CA-4.1: Gerar pacote em A e aplicar 2x em B resulta em contagens estritamente iguais', () async {
        // 1. Inserir tarefas em A (o trigger de sync grava automaticamente em sync_column_versions)
        await dbA
            .into(dbA.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-sync-1',
                title: 'Limpar os filtros do ar',
                isCompleted: const Value(false),
                createdAt: const Value('2026-03-15T10:00:00Z'),
                updatedAt: const Value('2026-03-15T10:00:00Z'),
              ),
            );

        // 2. A gera o pacote
        final bundleResult = await transportA.generateBundle();
        expect(bundleResult.isOk, isTrue);
        final bundleBytes = bundleResult.valueOrNull!;
        expect(bundleBytes.isNotEmpty, isTrue);

        // 3. B aplica o pacote pela 1ª vez
        final firstApplyResult = await transportB.applyBundle(bundleBytes);
        expect(firstApplyResult.isOk, isTrue);

        final countTasksAfterFirst = await dbB.tasks.select().get();
        expect(countTasksAfterFirst.length, equals(1));
        expect(
          countTasksAfterFirst.first.title,
          equals('Limpar os filtros do ar'),
        );

        // 4. B applies exact same bundle 2nd time (idempotency - CA-4.1)
        final secondApplyResult = await transportB.applyBundle(bundleBytes);
        expect(secondApplyResult.isOk, isTrue);

        final countTasksAfterSecond = await dbB.tasks.select().get();
        expect(
          countTasksAfterSecond.length,
          equals(countTasksAfterFirst.length),
        );
        expect(
          countTasksAfterSecond.first.title,
          equals(countTasksAfterFirst.first.title),
        );
      });

      test('CA-4.2: Bundle tampered by 1 byte fails to apply and preserves database intact', () async {
        final bundleResult = await transportA.generateBundle();
        expect(bundleResult.isOk, isTrue);
        final validBytes = bundleResult.valueOrNull!;

        // Adulterar 1 byte no ciphertext
        final corrupted = Uint8List.fromList(validBytes);
        corrupted[corrupted.length - 10] ^= 0xFF;

        final applyResult = await transportB.applyBundle(corrupted);
        expect(applyResult.isErr, isTrue);
        expect(applyResult.failureOrNull, isA<IntegrityFailure>());

        // Database of B remains intact and empty of tasks
        final countTasks = await dbB.tasks.select().get();
        expect(countTasks, isEmpty);
      });
    },
  );
}
