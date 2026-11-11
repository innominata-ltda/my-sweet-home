import 'dart:io';

import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/lan/discovery_tag.dart';
import 'package:my_sweet_home/features/sync/data/lan/frame_reader.dart';
import 'package:my_sweet_home/features/sync/data/lan/lan_auth_handshake.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_household_repository.dart';
import '../../fakes/fake_lan_peer_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'LanPeerDiscovery and LanSyncTransport Integration (RF-122, CA-3.1)',
    () {
      late AppDatabase db;
      late FakeHouseholdRepository repo;
      late FakeHouseholdKeyStore keyStore;
      late FakeLanPeerDiscovery fakeDiscovery;
      late LanSyncTransport transport;

      const testHouseholdId = 'house-discovery-123';
      final commonKey = HouseholdKey(
        Uint8List.fromList(List.generate(32, (i) => 7)),
      );
      final now = DateTime.utc(2026, 10, 27, 10, 0);

      setUp(() async {
        db = AppDatabase.memory();
        final registry = SyncTableRegistryImpl();
        final clock = FakeClock(now);

        await db
            .into(db.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: testHouseholdId,
                name: 'Casa dos Amigos',
                localSiteId: 'site-local-1',
                sharedAreas: 'home,finance,catalog',
                createdAt: now.toIso8601String(),
                joinedAt: now.toIso8601String(),
                active: const Value(true),
              ),
            );

        repo = FakeHouseholdRepository(
          initialHousehold: Household(
            id: testHouseholdId,
            name: 'Casa dos Amigos',
            localSiteId: 'site-local-1',
            sharedAreas: const {SyncArea.home, SyncArea.finance},
            createdAt: now,
            joinedAt: now,
          ),
        );

        keyStore = FakeHouseholdKeyStore(commonKey);
        fakeDiscovery = FakeLanPeerDiscovery();

        transport = LanSyncTransport(
          householdRepository: repo,
          keyStore: keyStore,
          changeSource: DriftChangeSource(db: db, registry: registry),
          tombstoneStore: TombstoneStore(db: db, clock: clock),
          codec: SyncBatchCodecImpl(),
          batchApplier: DriftBatchApplier(
            db: db,
            registry: registry,
            changeCapture: ChangeCapture(db: db, clock: clock),
            clock: clock,
          ),
          peerDiscovery: fakeDiscovery,
          clock: clock,
        );
      });

      tearDown(() async {
        transport.dispose();
        fakeDiscovery.dispose();
        repo.dispose();
        await db.close();
      });

      test(
        'start() inicia anúncio mDNS com etiqueta anônima e porta do socket',
        () async {
          expect(fakeDiscovery.isStarted, isFalse);

          final startRes = await transport.start();
          expect(startRes.isOk, isTrue);

          expect(fakeDiscovery.isStarted, isTrue);
          final expectedTag = await DiscoveryTag(commonKey).tagFor(now);
          expect(fakeDiscovery.currentAdvertisedTag, expectedTag);
          expect(fakeDiscovery.currentPort, transport.listeningPort);
          expect(transport.listeningPort, greaterThan(0));
        },
      );

      test('candidates announced with correct tag are authenticated and registered as peer (CA-2.10)', () async {
        final serverSocketB = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final portB = serverSocketB.port;
        serverSocketB.listen((socket) async {
          final reader = FrameReader(socket);
          final handshake = LanAuthHandshake(
            key: commonKey,
            randomBytes: Uint8List.new,
          );
          await handshake.runAsServer(
            reader,
            socket,
            const SecurityLimits(),
            localSiteId: 'site-remote-2',
            localDeviceName: 'Aparelho Amigo 2',
          );
          await socket.flush();
          await socket.close();
        });

        await transport.start();
        await pumpEventQueue();

        final todayTag = await DiscoveryTag(commonKey).tagFor(now);
        fakeDiscovery.emitCandidates([
          LanCandidate(address: '127.0.0.1', port: portB, tag: todayTag),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        final peers = await transport.watchPeers().first;
        expect(peers.length, 1);
        expect(peers.first.siteId, 'site-remote-2');
        expect(peers.first.name, 'Aparelho Amigo 2');
        expect(peers.first.address, '127.0.0.1');
        expect(peers.first.port, portB);

        await serverSocketB.close();
      });

      test('stop() interrompe a descoberta e desativa o servidor', () async {
        await transport.start();
        expect(fakeDiscovery.isStarted, isTrue);
        expect(transport.listeningPort, isNotNull);

        final stopRes = await transport.stop();
        expect(stopRes.isOk, isTrue);
        expect(fakeDiscovery.isStarted, isFalse);
        expect(transport.listeningPort, isNull);
      });

      test('syncNow envia lote para pares descobertos via mDNS', () async {
        // 1. Configure remote node (B)
        final dbB = AppDatabase.memory();
        await dbB
            .into(dbB.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: testHouseholdId,
                name: 'Casa dos Amigos',
                localSiteId: 'site-remote-b',
                sharedAreas: 'home,finance,catalog',
                createdAt: now.toIso8601String(),
                joinedAt: now.toIso8601String(),
                active: const Value(true),
              ),
            );
        final clockB = FakeClock(now);
        final registry = SyncTableRegistryImpl();
        final repoB = FakeHouseholdRepository(
          initialHousehold: Household(
            id: testHouseholdId,
            name: 'Casa dos Amigos',
            localSiteId: 'site-remote-b',
            sharedAreas: const {SyncArea.home, SyncArea.finance},
            createdAt: now,
            joinedAt: now,
          ),
        );
        final keyStoreB = FakeHouseholdKeyStore(commonKey);
        final fakeDiscoveryB = FakeLanPeerDiscovery();
        final transportB = LanSyncTransport(
          householdRepository: repoB,
          keyStore: keyStoreB,
          changeSource: DriftChangeSource(db: dbB, registry: registry),
          tombstoneStore: TombstoneStore(db: dbB, clock: clockB),
          codec: SyncBatchCodecImpl(),
          batchApplier: DriftBatchApplier(
            db: dbB,
            registry: registry,
            changeCapture: ChangeCapture(db: dbB, clock: clockB),
            clock: clockB,
          ),
          peerDiscovery: fakeDiscoveryB,
          clock: clockB,
        );

        await transportB.start();
        final portB = transportB.listeningPort!;

        // 2. Start local node (A) and simulate mutual mDNS discovery of nodes A and B
        await transport.start();
        await pumpEventQueue();

        final todayTag = await DiscoveryTag(commonKey).tagFor(now);
        fakeDiscovery.emitCandidates([
          LanCandidate(address: '127.0.0.1', port: portB, tag: todayTag),
        ]);
        fakeDiscoveryB.emitCandidates([
          LanCandidate(
            address: '127.0.0.1',
            port: transport.listeningPort!,
            tag: todayTag,
          ),
        ]);
        await pumpEventQueue();

        // 3. Cria dado local em A
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-sync-mdns',
                title: 'Tarefa via mDNS',
                isCompleted: const Value(false),
                createdAt: Value(now.toIso8601String()),
                updatedAt: Value(now.toIso8601String()),
              ),
            );

        // 4. Trigger sync now in A
        final reportRes = await transport.syncNow();
        expect(reportRes.isOk, isTrue);
        final report = reportRes.valueOrNull!;
        expect(report.peersContactedCount, 1);
        expect(report.sentChangesCount, greaterThan(0));

        // 5. Await application in B
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final taskOnB = await (dbB.select(
          dbB.tasks,
        )..where((t) => t.id.equals('task-sync-mdns'))).getSingleOrNull();
        expect(taskOnB, isNotNull);
        expect(taskOnB!.title, 'Tarefa via mDNS');

        // 6. Verifica que A registrou B e B registrou A na lista de aparelhos membros
        final membersOnA = (await repo.getMembers()).valueOrNull!;
        expect(membersOnA.any((m) => m.siteId == 'site-remote-b'), isTrue);

        final membersOnB = (await repoB.getMembers()).valueOrNull!;
        expect(membersOnB.any((m) => m.siteId == 'site-local-1'), isTrue);

        // Limpeza
        fakeDiscoveryB.dispose();
        transportB.dispose();
        repoB.dispose();
        await dbB.close();
      });
    },
  );
}
