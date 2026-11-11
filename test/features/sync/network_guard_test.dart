import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_cloud_storage_port.dart';
import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_settings_repository.dart';

class _BlockingHttpOverrides extends HttpOverrides {
  int connectionAttemptCount = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    connectionAttemptCount++;
    throw const SocketException(
      'Bloqueado pelo NetworkGuard: nenhuma conexão externa autorizada',
    );
  }
}

void main() {
  group(
    'T-17 / CA-8.1 — Network Guard (Privacy and Blocking External Connections)',
    () {
      late AppDatabase db;
      late FakeSettingsRepository settingsRepo;
      late FakeHouseholdKeyStore keyStore;
      late FakeCloudStoragePort cloudPort;
      late FakeClock clock;
      late SyncTableRegistry registry;
      late SyncBatchCodecImpl codec;
      late HouseholdKey sharedKey;
      late _BlockingHttpOverrides overrides;

      setUp(() async {
        db = AppDatabase.memory();
        settingsRepo = FakeSettingsRepository(
          householdSyncAllowed: true,
          householdSyncRemoteAllowed: false, // Negado estritamente
        );
        sharedKey = HouseholdKey(List.generate(32, (i) => i));
        keyStore = FakeHouseholdKeyStore(sharedKey);
        cloudPort = FakeCloudStoragePort();
        clock = FakeClock(DateTime.utc(2026, 3, 15));
        registry = SyncTableRegistryImpl();
        codec = SyncBatchCodecImpl();

        overrides = _BlockingHttpOverrides();
        HttpOverrides.global = overrides;
      });

      tearDown(() async {
        HttpOverrides.global = null;
        await db.close();
      });

      test('CA-8.1: With active household and remote denied, no connection outside LAN is attempted', () async {
        final repo = DriftHouseholdRepository(
          db: db,
          keyStore: keyStore,
          settingsRepository: settingsRepo,
          clock: clock,
        );

        // Cria a casa ativa
        await repo.createHousehold(
          name: 'Casa Segura',
          deviceName: 'Meu Aparelho',
          sharedAreas: {SyncArea.home},
          key: sharedKey,
        );

        final remoteTransport = RemoteSyncTransport(
          householdRepository: repo,
          keyStore: keyStore,
          changeSource: DriftChangeSource(db: db, registry: registry),
          tombstoneStore: TombstoneStore(db: db, clock: clock),
          codec: codec,
          batchApplier: DriftBatchApplier(
            db: db,
            registry: registry,
            changeCapture: ChangeCapture(db: db, clock: clock),
            clock: clock,
          ),
          settingsRepository: settingsRepo,
          cloudStoragePort: cloudPort,
          clock: clock,
        );

        // Trigger sync attempt
        final result = await remoteTransport.syncNow();

        // Confirms transport fails strictly with permission failure
        expect(result.isErr, isTrue);

        // Confirms no external HTTP or socket connection was opened
        expect(overrides.connectionAttemptCount, 0);
        expect(cloudPort.uploadCallCount, 0);
        expect(cloudPort.downloadCallCount, 0);
        expect(cloudPort.listCallCount, 0);
      });
    },
  );
}
