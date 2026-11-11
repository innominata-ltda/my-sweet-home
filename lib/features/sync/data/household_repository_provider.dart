import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/core/sync/domain/sync_applied_event.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/applied_bundle_ledger.dart';
import 'package:my_sweet_home/features/sync/data/bonsoir_lan_peer_discovery.dart';
import 'package:my_sweet_home/features/sync/data/bundle_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/calendar_owner_guard.dart';
import 'package:my_sweet_home/features/sync/data/composite_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/remote_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/secure_household_key_store.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/data/x25519_pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/lan_server_guard.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_batch_codec.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/create_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/join_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/leave_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/remove_member_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/set_areas_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/sync_now_usecase.dart';

final householdKeyStoreProvider = Provider<HouseholdKeyStore>((ref) {
  return SecureHouseholdKeyStore();
});

final syncBatchCodecProvider = Provider<SyncBatchCodec>((ref) {
  return SyncBatchCodecImpl();
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final idGen = ref.watch(idGeneratorProvider);

  return DriftHouseholdRepository(
    db: db,
    keyStore: keyStore,
    settingsRepository: settingsRepo,
    clock: clock,
    idGenerator: idGen,
  );
});

final batchApplierProvider = Provider<BatchApplier>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final registry = SyncTableRegistryImpl();

  return DriftBatchApplier(
    db: db,
    registry: registry,
    changeCapture: ChangeCapture(db: db, clock: clock),
    clock: clock,
  );
});

final syncAppliedEventsStreamProvider = StreamProvider<SyncAppliedEvent>((ref) {
  try {
    final applier = ref.watch(batchApplierProvider);
    return applier.onBatchApplied;
  } catch (_) {
    return const Stream.empty();
  }
});

final appliedBundleLedgerProvider = Provider<AppliedBundleLedger>((ref) {
  final db = ref.watch(databaseProvider);
  return AppliedBundleLedger(db);
});

final bundleSyncTransportProvider = Provider<BundleSyncTransport>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final repo = ref.watch(householdRepositoryProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  final codec = ref.watch(syncBatchCodecProvider);
  final registry = SyncTableRegistryImpl();

  return BundleSyncTransport(
    householdRepository: repo,
    keyStore: keyStore,
    changeSource: DriftChangeSource(db: db, registry: registry),
    tombstoneStore: TombstoneStore(db: db, clock: clock),
    codec: codec,
    batchApplier: ref.watch(batchApplierProvider),
    appliedBundleLedger: ref.watch(appliedBundleLedgerProvider),
    clock: clock,
  );
});

final remoteSyncTransportProvider = Provider<RemoteSyncTransport>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final repo = ref.watch(householdRepositoryProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  final codec = ref.watch(syncBatchCodecProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final cloudStorage = ref.watch(cloudStoragePortProvider);
  final registry = SyncTableRegistryImpl();

  return RemoteSyncTransport(
    householdRepository: repo,
    keyStore: keyStore,
    changeSource: DriftChangeSource(db: db, registry: registry),
    tombstoneStore: TombstoneStore(db: db, clock: clock),
    codec: codec,
    batchApplier: ref.watch(batchApplierProvider),
    settingsRepository: settingsRepo,
    cloudStoragePort: cloudStorage,
    clock: clock,
  );
});

final createHouseholdUseCaseProvider = Provider<CreateHouseholdUseCase>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return CreateHouseholdUseCase(repository: repo);
});

final leaveHouseholdUseCaseProvider = Provider<LeaveHouseholdUseCase>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return LeaveHouseholdUseCase(repo);
});

final setAreasUseCaseProvider = Provider<SetAreasUseCase>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return SetAreasUseCase(repo);
});

final joinHouseholdUseCaseProvider = Provider<JoinHouseholdUseCase>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return JoinHouseholdUseCase(repository: repo);
});

final lanPeerDiscoveryProvider = Provider<LanPeerDiscoveryPort>((ref) {
  return BonsoirLanPeerDiscovery();
});

final lanServerGuardProvider = Provider<LanServerGuard>((ref) {
  final limits = ref.watch(securityLimitsProvider);
  final clock = ref.watch(clockProvider);
  return LanServerGuard(limits: limits, clock: clock);
});

final lanSyncTransportProvider = Provider<LanSyncTransport>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final repo = ref.watch(householdRepositoryProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  final codec = ref.watch(syncBatchCodecProvider);
  final discovery = ref.watch(lanPeerDiscoveryProvider);
  final limits = ref.watch(securityLimitsProvider);
  final serverGuard = ref.watch(lanServerGuardProvider);
  final registry = SyncTableRegistryImpl();

  final transport = LanSyncTransport(
    householdRepository: repo,
    keyStore: keyStore,
    changeSource: DriftChangeSource(db: db, registry: registry),
    tombstoneStore: TombstoneStore(db: db, clock: clock),
    codec: codec,
    batchApplier: ref.watch(batchApplierProvider),
    peerDiscovery: discovery,
    preferredPort: LanSyncTransport.defaultPort,
    clock: clock,
    db: db,
    limits: limits,
    serverGuard: serverGuard,
  );
  ref.onDispose(transport.stop);
  return transport;
});

final compositeSyncTransportProvider = Provider<CompositeSyncTransport>((ref) {
  final lanTransport = ref.watch(lanSyncTransportProvider);
  final remoteTransport = ref.watch(remoteSyncTransportProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  return CompositeSyncTransport(
    lanTransport: lanTransport,
    remoteTransport: remoteTransport,
    settingsRepository: settingsRepo,
  );
});

final syncNowUseCaseProvider = Provider<SyncNowUseCase>((ref) {
  final transport = ref.watch(compositeSyncTransportProvider);
  return SyncNowUseCase(transport);
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  return RemoveMemberUseCase(repository: repo, keyStore: keyStore);
});

final pairingChannelProvider = Provider<PairingChannel>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  final keyStore = ref.watch(householdKeyStoreProvider);
  final clock = ref.watch(clockProvider);
  final idGen = ref.watch(idGeneratorProvider);
  return X25519PairingChannel(
    householdRepository: repo,
    keyStore: keyStore,
    clock: clock,
    idGenerator: idGen,
  );
});

final calendarOwnerGuardProvider = Provider<CalendarOwnerGuard>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  return CalendarOwnerGuard(householdRepository: repo, db: db, clock: clock);
});
