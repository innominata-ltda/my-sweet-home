import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/lan_server_guard.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/fake_household_key_store.dart';
import '../../../fakes/fake_settings_repository.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('LAN Server Hardening (RN-403..RN-407, CA-2.1, CA-2.2, CA-2.4)', () {
    late AppDatabase dbServer;
    late AppDatabase dbClient;
    late FakeClock clock;
    late HouseholdKey sharedKey;
    late FakeHouseholdKeyStore serverKeyStore;
    late FakeHouseholdKeyStore clientKeyStore;
    late FakeSettingsRepository serverSettings;
    late FakeSettingsRepository clientSettings;
    late SyncTableRegistry registry;
    late SyncBatchCodecImpl codec;
    late LanServerGuard serverGuard;
    late SecurityLimits limits;

    late DriftHouseholdRepository serverRepo;
    late DriftHouseholdRepository clientRepo;
    late LanSyncTransport serverTransport;
    late LanSyncTransport clientTransport;

    setUp(() async {
      dbServer = AppDatabase.memory();
      dbClient = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 15, 12, 0));
      sharedKey = HouseholdKey(List.generate(32, (i) => i));

      serverKeyStore = FakeHouseholdKeyStore(sharedKey);
      clientKeyStore = FakeHouseholdKeyStore(sharedKey);
      serverSettings = FakeSettingsRepository();
      clientSettings = FakeSettingsRepository();
      registry = SyncTableRegistryImpl();
      codec = SyncBatchCodecImpl();

      limits = const SecurityLimits(
        lanPreAuthMaxBytes: 4096,
        lanPreAuthTimeout: Duration(seconds: 1),
        lanMaxMessageBytes: 16 * 1024 * 1024,
        lanReadTimeout: Duration(seconds: 5),
        lanMaxConcurrentConnections: 2,
        lanMaxAuthFailures: 5,
        lanAuthFailureWindow: Duration(minutes: 1),
        lanBanDuration: Duration(minutes: 5),
      );

      serverGuard = LanServerGuard(limits: limits, clock: clock);

      serverRepo = DriftHouseholdRepository(
        db: dbServer,
        keyStore: serverKeyStore,
        settingsRepository: serverSettings,
        clock: clock,
      );

      clientRepo = DriftHouseholdRepository(
        db: dbClient,
        keyStore: clientKeyStore,
        settingsRepository: clientSettings,
        clock: clock,
      );

      final house = (await serverRepo.createHousehold(
        name: 'Casa Segura',
        deviceName: 'Servidor',
        sharedAreas: {SyncArea.home, SyncArea.catalog},
        key: sharedKey,
      )).valueOrNull!;

      await dbClient
          .into(dbClient.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: house.id,
              name: 'Casa Segura',
              localSiteId: 'client-site',
              sharedAreas: 'catalog,home',
              createdAt: clock.nowUtc().toIso8601String(),
              joinedAt: clock.nowUtc().toIso8601String(),
              active: const Value(true),
            ),
          );

      serverTransport = LanSyncTransport(
        householdRepository: serverRepo,
        keyStore: serverKeyStore,
        changeSource: DriftChangeSource(db: dbServer, registry: registry),
        tombstoneStore: TombstoneStore(db: dbServer, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbServer,
          registry: registry,
          changeCapture: ChangeCapture(db: dbServer, clock: clock),
          clock: clock,
        ),
        clock: clock,
        limits: limits,
        serverGuard: serverGuard,
        preferredPort: 0, // ephemeral port assigned by OS
      );

      clientTransport = LanSyncTransport(
        householdRepository: clientRepo,
        keyStore: clientKeyStore,
        changeSource: DriftChangeSource(db: dbClient, registry: registry),
        tombstoneStore: TombstoneStore(db: dbClient, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbClient,
          registry: registry,
          changeCapture: ChangeCapture(db: dbClient, clock: clock),
          clock: clock,
        ),
        clock: clock,
        limits: limits,
        preferredPort: 0,
      );

      await serverTransport.start();
    });

    tearDown(() async {
      await serverTransport.stop();
      await clientTransport.stop();
      await dbServer.close();
      await dbClient.close();
    });

    test('CA-2.1: client without key attempts to send 10 MB; connection is closed and no data is applied', () async {
      final serverPort = serverTransport.serverPort;
      expect(serverPort, isNotNull);

      // Client connects on loopback
      final socket = await Socket.connect('127.0.0.1', serverPort!);

      // Attempts to send 10 MB without authenticating
      final payload10Mb = Uint8List(10 * 1024 * 1024);
      final header = ByteData(4)..setUint32(0, payload10Mb.length);

      var socketClosed = false;
      final doneCompleter = Completer<void>();
      socket.listen(
        (_) {},
        onDone: () {
          socketClosed = true;
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        },
        onError: (_) {
          socketClosed = true;
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        },
      );

      // Sends header declaring 10 MB
      socket.add(header.buffer.asUint8List());
      try {
        socket.add(payload10Mb.sublist(0, 8192));
        await socket.flush();
      } catch (_) {}

      // Awaits termination by server (<= 1s preAuth limit)
      await doneCompleter.future.timeout(const Duration(seconds: 3));
      expect(socketClosed, isTrue);

      // Verifies no change was applied to server database
      final tasks = await dbServer.select(dbServer.tasks).get();
      expect(tasks, isEmpty);
      socket.destroy();
    });

    test('CA-2.2: client with correct key completes handshake and applies batch successfully', () async {
      final serverPort = serverTransport.serverPort;
      expect(serverPort, isNotNull);

      // Inserts task on client
      await dbClient
          .into(dbClient.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-auth-1',
              title: 'Tarefa Segura via LAN v2',
              createdAt: const Value('2026-03-15T12:00:00Z'),
              updatedAt: const Value('2026-03-15T12:00:00Z'),
            ),
          );

      // Registers server as client peer
      clientTransport.registerPeer(
        DiscoveredPeer(
          siteId: 'server-site',
          address: '127.0.0.1',
          port: serverPort!,
        ),
      );

      // Executes sync from client to server
      final syncResult = await clientTransport.syncNow();
      expect(syncResult.isOk, isTrue);

      // Server applied task successfully
      final tasksOnServer = await (dbServer.select(
        dbServer.tasks,
      )..where((t) => t.id.equals('task-auth-1'))).getSingleOrNull();

      expect(tasksOnServer, isNotNull);
      expect(tasksOnServer!.title, equals('Tarefa Segura via LAN v2'));
    });
  });
}
