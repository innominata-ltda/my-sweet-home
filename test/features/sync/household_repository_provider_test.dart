import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/data/bundle_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/household_repository_provider.dart';
import 'package:my_sweet_home/features/sync/data/remote_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/secure_household_key_store.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/create_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/leave_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/set_areas_usecase.dart';

import '../../fakes/fake_cloud_storage_port.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  group('household_repository_provider DI', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(const SystemClock()),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(householdSyncRemoteAllowed: true),
          ),
          cloudStoragePortProvider.overrideWithValue(FakeCloudStoragePort()),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('resolve todos os providers de sync com suas portas', () {
      expect(
        container.read(householdKeyStoreProvider),
        isA<SecureHouseholdKeyStore>(),
      );
      expect(container.read(syncBatchCodecProvider), isA<SyncBatchCodecImpl>());
      expect(
        container.read(householdRepositoryProvider),
        isA<DriftHouseholdRepository>(),
      );
      expect(
        container.read(bundleSyncTransportProvider),
        isA<BundleSyncTransport>(),
      );
      expect(
        container.read(remoteSyncTransportProvider),
        isA<RemoteSyncTransport>(),
      );
      expect(
        container.read(createHouseholdUseCaseProvider),
        isA<CreateHouseholdUseCase>(),
      );
      expect(
        container.read(leaveHouseholdUseCaseProvider),
        isA<LeaveHouseholdUseCase>(),
      );
      expect(container.read(setAreasUseCaseProvider), isA<SetAreasUseCase>());
    });
  });
}
