import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/bonsoir_lan_peer_discovery.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/data/lan/discovery_tag.dart';
import 'package:my_sweet_home/features/sync/data/lan/frame_reader.dart';
import 'package:my_sweet_home/features/sync/data/lan/lan_auth_handshake.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/lan_server_guard.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/fake_household_key_store.dart';
import '../../../fakes/fake_lan_peer_discovery.dart';
import '../../../fakes/fake_settings_repository.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('LAN Peer Registration & Privacy (RN-410..RN-412, CA-2.8, CA-2.9, CA-2.10)', () {
    late HouseholdKey sharedKey;
    late DateTime today;
    late FakeClock clock;
    late SyncTableRegistry registry;
    late SyncBatchCodecImpl codec;
    late SecurityLimits limits;

    setUp(() {
      sharedKey = HouseholdKey(List.generate(32, (i) => i ^ 0x42));
      today = DateTime.utc(2026, 10, 30, 12, 0);
      clock = FakeClock(today);
      registry = SyncTableRegistryImpl();
      codec = SyncBatchCodecImpl();
      limits = const SecurityLimits(
        lanPreAuthMaxBytes: 4096,
        lanPreAuthTimeout: Duration(seconds: 1),
        lanMaxMessageBytes: 16 * 1024 * 1024,
        lanReadTimeout: Duration(seconds: 5),
      );
    });

    test('CA-2.9: mDNS announcement does not reveal householdId, siteId or nickname; tag rotates every 24h', () async {
      final discoveryTag = DiscoveryTag(sharedKey);
      final tagToday = await discoveryTag.tagFor(clock.nowUtc());

      final service = BonsoirLanPeerDiscovery.buildService(
        port: 42424,
        advertisedTag: tagToday,
      );

      // mDNS announcement contains only the rotating tag
      // Without leaking householdId, siteId or nickname in plaintext
      expect(service.name, 'MSH-$tagToday');
      expect(service.attributes.keys, equals(['tag']));
      expect(service.attributes['tag'], tagToday);
      expect(service.attributes.containsKey('householdId'), isFalse);
      expect(service.attributes.containsKey('siteId'), isFalse);
      expect(service.attributes.containsKey('name'), isFalse);
      expect(service.attributes.containsKey('deviceName'), isFalse);

      // Rotates tag on the following day (FakeClock)
      clock.advance(const Duration(days: 1));
      final tagTomorrow = await discoveryTag.tagFor(clock.nowUtc());
      expect(tagToday, isNot(equals(tagTomorrow)));
    });

    test('CA-2.8: device connecting without being advertised or paired does not enter peer list or sync_members', () async {
      final dbServer = AppDatabase.memory();
      final serverKeyStore = FakeHouseholdKeyStore(sharedKey);
      final serverSettings = FakeSettingsRepository();
      final serverRepo = DriftHouseholdRepository(
        db: dbServer,
        keyStore: serverKeyStore,
        settingsRepository: serverSettings,
        clock: clock,
      );

      final house = (await serverRepo.createHousehold(
        name: 'Casa Segura',
        deviceName: 'Servidor Oficial',
        sharedAreas: {SyncArea.home, SyncArea.finance},
        key: sharedKey,
      )).valueOrNull!;

      final serverGuard = LanServerGuard(limits: limits, clock: clock);
      final serverTransport = LanSyncTransport(
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
        preferredPort: 0,
      );

      await serverTransport.start();
      final serverPort = serverTransport.serverPort!;

      // Intruder or unannounced device connects directly via socket
      final clientSocket = await Socket.connect('127.0.0.1', serverPort);
      final clientReader = FrameReader(clientSocket);
      final handshake = LanAuthHandshake(
        key: sharedKey,
        randomBytes: Uint8List.new,
      );

      // Completes handshake with household key but unknown siteId and nickname
      final clientAuthRes = await handshake.runAsClient(
        clientReader,
        clientSocket,
        limits,
        localSiteId: 'unannounced-site-999',
        localDeviceName: 'Aparelho Desconhecido',
      );
      expect(clientAuthRes.isOk, isTrue);

      final session = clientAuthRes.valueOrNull!;

      // Sends a valid batch
      final batch = SyncBatch(
        householdId: house.id,
        fromSiteId: 'unannounced-site-999',
        senderVector: const VersionVector({}),
      );
      final sealRes = await codec.seal(batch, session.sessionKey);
      final batchBytes = sealRes.valueOrNull!;

      final header = ByteData(4)..setUint32(0, batchBytes.length);
      clientSocket.add(header.buffer.asUint8List());
      clientSocket.add(batchBytes);
      await clientSocket.flush();

      // Awaits connection termination
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await clientReader.cancel();
      clientSocket.destroy();

      // CA-2.8: Does not appear in server peer list
      expect(
        serverTransport.peers.any((p) => p.siteId == 'unannounced-site-999'),
        isFalse,
      );

      // Server sync_members remains unchanged (only original local member)
      final members = (await serverRepo.getMembers()).valueOrNull!;
      expect(members.any((m) => m.siteId == 'unannounced-site-999'), isFalse);
      expect(members.length, 1);
      expect(members.first.siteId, house.localSiteId);

      await serverTransport.stop();
      await dbServer.close();
    });

    test('CA-2.10: two devices advertise, recognize mDNS tag, perform handshake and register peer with exchanged nickname in session', () async {
      final dbA = AppDatabase.memory();
      final dbB = AppDatabase.memory();

      final repoA = DriftHouseholdRepository(
        db: dbA,
        keyStore: FakeHouseholdKeyStore(sharedKey),
        settingsRepository: FakeSettingsRepository(),
        clock: clock,
      );
      final repoB = DriftHouseholdRepository(
        db: dbB,
        keyStore: FakeHouseholdKeyStore(sharedKey),
        settingsRepository: FakeSettingsRepository(),
        clock: clock,
      );

      final houseA = (await repoA.createHousehold(
        name: 'Casa Segura',
        deviceName: 'Celular de Alice',
        sharedAreas: {SyncArea.home, SyncArea.finance},
        key: sharedKey,
      )).valueOrNull!;

      await dbB
          .into(dbB.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: houseA.id,
              name: 'Casa Segura',
              localSiteId: 'site-b',
              sharedAreas: 'home,finance',
              createdAt: today.toIso8601String(),
              joinedAt: today.toIso8601String(),
              active: const Value(true),
            ),
          );
      await dbB
          .into(dbB.syncMembers)
          .insert(
            SyncMembersCompanion.insert(
              id: 'member-b-local',
              householdId: houseA.id,
              siteId: 'site-b',
              name: 'Tablet de Bob',
              joinedAt: today.toIso8601String(),
              lastSeenAt: Value(today.toIso8601String()),
              isActive: const Value(true),
            ),
          );

      final discoveryA = FakeLanPeerDiscovery();
      final discoveryB = FakeLanPeerDiscovery();

      final transportA = LanSyncTransport(
        householdRepository: repoA,
        keyStore: FakeHouseholdKeyStore(sharedKey),
        changeSource: DriftChangeSource(db: dbA, registry: registry),
        tombstoneStore: TombstoneStore(db: dbA, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbA,
          registry: registry,
          changeCapture: ChangeCapture(db: dbA, clock: clock),
          clock: clock,
        ),
        peerDiscovery: discoveryA,
        clock: clock,
        limits: limits,
        preferredPort: 0,
      );

      final transportB = LanSyncTransport(
        householdRepository: repoB,
        keyStore: FakeHouseholdKeyStore(sharedKey),
        changeSource: DriftChangeSource(db: dbB, registry: registry),
        tombstoneStore: TombstoneStore(db: dbB, clock: clock),
        codec: codec,
        batchApplier: DriftBatchApplier(
          db: dbB,
          registry: registry,
          changeCapture: ChangeCapture(db: dbB, clock: clock),
          clock: clock,
        ),
        peerDiscovery: discoveryB,
        clock: clock,
        limits: limits,
        preferredPort: 0,
      );

      await transportA.start();
      await transportB.start();
      await pumpEventQueue();

      final portA = transportA.serverPort!;
      final portB = transportB.serverPort!;

      // Both advertise with today rotating tag
      final todayTag = await DiscoveryTag(sharedKey).tagFor(today);
      expect(discoveryA.currentAdvertisedTag, todayTag);
      expect(discoveryB.currentAdvertisedTag, todayTag);

      // Mutual discovery of mDNS candidates
      discoveryA.emitCandidates([
        LanCandidate(address: '127.0.0.1', port: portB, tag: todayTag),
      ]);
      discoveryB.emitCandidates([
        LanCandidate(address: '127.0.0.1', port: portA, tag: todayTag),
      ]);

      // Awaits mutual handshake and secure nickname exchange
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // CA-2.10: Device A recognizes peer B and displays its nickname ('Tablet de Bob')
      final peersA = await transportA.watchPeers().first;
      expect(peersA.any((p) => p.siteId == 'site-b'), isTrue);
      final peerBOnA = peersA.firstWhere((p) => p.siteId == 'site-b');
      expect(peerBOnA.name, 'Tablet de Bob');
      expect(peerBOnA.address, '127.0.0.1');
      expect(peerBOnA.port, portB);

      // Device B recognizes peer A and displays its nickname ('Celular de Alice')
      final peersB = await transportB.watchPeers().first;
      expect(peersB.any((p) => p.siteId == houseA.localSiteId), isTrue);
      final peerAOnB = peersB.firstWhere((p) => p.siteId == houseA.localSiteId);
      expect(peerAOnB.name, 'Celular de Alice');
      expect(peerAOnB.address, '127.0.0.1');
      expect(peerAOnB.port, portA);

      await transportA.stop();
      await transportB.stop();
      await dbA.close();
      await dbB.close();
    });
  });
}
