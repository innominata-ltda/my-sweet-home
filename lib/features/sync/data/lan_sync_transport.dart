library;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_batch_factory.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/lan/discovery_tag.dart';
import 'package:my_sweet_home/features/sync/data/lan/frame_reader.dart';
import 'package:my_sweet_home/features/sync/data/lan/lan_auth_handshake.dart';
import 'package:my_sweet_home/features/sync/domain/lan_server_guard.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_batch_codec.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

/// Implementation of local network (Wi-Fi / LAN) synchronization transport
/// via sockets TCP e pacotes cifrados com AES-256-GCM (RF-122, CA-3.1, CA-3.2, CA-6.2, T-11).
class LanSyncTransport implements SyncTransportPort {
  static const int defaultPort = 42424;

  final HouseholdRepository householdRepository;
  final HouseholdKeyStore keyStore;
  final ChangeSource changeSource;
  final TombstoneStore tombstoneStore;
  final SyncBatchCodec codec;
  final BatchApplier batchApplier;
  final SyncBatchFactory? batchFactory;
  final LanPeerDiscoveryPort? peerDiscovery;
  final int preferredPort;
  final Clock clock;
  final AppDatabase? db;
  final SecurityLimits limits;
  final LanServerGuard? serverGuard;
  final Uint8List Function(int)? randomBytes;

  ServerSocket? _serverSocket;
  StreamSubscription<List<LanCandidate>>? _discoverySub;
  final Map<String, LanCandidate> _candidates = {};
  final List<DiscoveredPeer> _peers = [];
  final _peersController = StreamController<List<DiscoveredPeer>>.broadcast();

  LanSyncTransport({
    required this.householdRepository,
    required this.keyStore,
    required this.changeSource,
    required this.tombstoneStore,
    required this.codec,
    required this.batchApplier,
    this.batchFactory,
    this.peerDiscovery,
    this.preferredPort = 0,
    this.clock = const SystemClock(),
    this.db,
    this.limits = const SecurityLimits(),
    this.serverGuard,
    this.randomBytes,
  });

  /// Open TCP port of server (useful for loopback tests with ephemeral port).
  int? get serverPort => _serverSocket?.port;

  /// Manually adds discovered peer (useful for loopback tests and IP fallback, RF-122).
  void registerPeer(DiscoveredPeer peer) {
    _peers.removeWhere(
      (p) =>
          p.siteId == peer.siteId ||
          (p.address == peer.address && p.port == peer.port),
    );
    _peers.add(peer);
    _peersController.add(List.unmodifiable(_peers));
    if (db != null && !peer.address.startsWith('127.')) {
      unawaited(
        db!.customStatement(
          '''
          INSERT OR REPLACE INTO settings (key, value)
          VALUES (?, ?);
          ''',
          ['sync_peer_${peer.siteId}_ip', '${peer.address}:${peer.port}'],
        ),
      );
    }
    unawaited(
      householdRepository.upsertMember(
        siteId: peer.siteId,
        deviceName: (peer.name != null && peer.name!.isNotEmpty)
            ? peer.name!
            : 'Aparelho Descoberto',
        lastSeenAt: clock.nowUtc(),
      ),
    );
  }

  List<DiscoveredPeer> get peers => List.unmodifiable(_peers);

  /// Limpa a lista de pares.
  void clearPeers() {
    _peers.clear();
    _peersController.add(const []);
  }

  int? get listeningPort => _serverSocket?.port;

  @override
  Future<Result<void, Failure>> start() async {
    try {
      if (_serverSocket == null) {
        final portToBind = preferredPort > 0 ? preferredPort : defaultPort;
        try {
          _serverSocket = await ServerSocket.bind(
            InternetAddress.anyIPv4,
            portToBind,
          );
        } catch (_) {
          _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        }
        _serverSocket!.listen(
          _handleIncomingConnection,
          onError: (e) {
            // Falhas de rede registradas silenciosamente sem derrubar o app (CA-6.2)
          },
        );
      }

      if (peerDiscovery != null) {
        final householdRes = await householdRepository.getHousehold();
        final household = householdRes.valueOrNull;
        final keyRes = await keyStore.read();
        final key = keyRes.valueOrNull;
        if (household != null && key != null && _serverSocket != null) {
          await _discoverySub?.cancel();
          final discoveryTag = DiscoveryTag(key);
          final todayTag = await discoveryTag.tagFor(clock.nowUtc());

          _discoverySub = peerDiscovery!.watchCandidates().listen((candidates) {
            unawaited(_onCandidatesDiscovered(candidates, household, key));
          });

          await peerDiscovery!.start(
            port: _serverSocket!.port,
            advertisedTag: todayTag,
          );
        }
      }

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Falha ao iniciar servidor LAN: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> stop() async {
    try {
      await _discoverySub?.cancel();
      _discoverySub = null;
      _candidates.clear();
      await peerDiscovery?.stop();

      await _serverSocket?.close();
      _serverSocket = null;
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Falha ao parar servidor LAN: $e', cause: e),
      );
    }
  }

  Future<void> _onCandidatesDiscovered(
    List<LanCandidate> candidates,
    Household household,
    HouseholdKey key,
  ) async {
    final acceptedTags = await DiscoveryTag(key).acceptedAt(clock.nowUtc());
    _candidates.clear();
    for (final candidate in candidates) {
      if (acceptedTags.contains(candidate.tag)) {
        if (candidate.address == '127.0.0.1' &&
            candidate.port == _serverSocket?.port) {
          continue;
        }
        _candidates['${candidate.address}:${candidate.port}'] = candidate;
      }
    }

    // Tenta autenticar e registrar novos candidatos anunciados (CA-2.10)
    for (final candidate in _candidates.values.toList()) {
      final alreadyRegistered = _peers.any(
        (p) => p.address == candidate.address && p.port == candidate.port,
      );
      if (!alreadyRegistered) {
        unawaited(_authenticateAndRegisterCandidate(candidate, household, key));
      }
    }
  }

  Future<String> _resolveLocalDeviceName(Household household) async {
    final membersRes = await householdRepository.getMembers();
    final members = membersRes.valueOrNull ?? [];
    for (final m in members) {
      if (m.siteId == household.localSiteId && m.name.isNotEmpty) {
        return m.name;
      }
    }
    return household.name;
  }

  Future<void> _authenticateAndRegisterCandidate(
    LanCandidate candidate,
    Household household,
    HouseholdKey key,
  ) async {
    Socket? socket;
    FrameReader? reader;
    try {
      final localDeviceName = await _resolveLocalDeviceName(household);
      socket = await Socket.connect(
        candidate.address,
        candidate.port,
        timeout: limits.lanPreAuthTimeout,
      );
      reader = FrameReader(socket);
      final handshake = LanAuthHandshake(
        key: key,
        randomBytes: _getRandomBytes,
      );
      final authRes = await handshake.runAsClient(
        reader,
        socket,
        limits,
        localSiteId: household.localSiteId,
        localDeviceName: localDeviceName,
      );
      if (authRes.isOk) {
        final session = authRes.valueOrNull!;
        final remoteSiteId = session.remoteSiteId;
        final remoteName = session.remoteDeviceName;
        if (remoteSiteId != null && remoteSiteId.isNotEmpty) {
          final peer = DiscoveredPeer(
            siteId: remoteSiteId,
            name: (remoteName != null && remoteName.isNotEmpty)
                ? remoteName
                : 'Aparelho Descoberto',
            address: candidate.address,
            port: candidate.port,
          );
          registerPeer(peer);
        }
      }
    } catch (_) {
      // Ignore temporary connection failures
    } finally {
      await reader?.cancel();
      socket?.destroy();
    }
  }

  @override
  Stream<List<DiscoveredPeer>> watchPeers() async* {
    yield List.unmodifiable(_peers);
    yield* _peersController.stream;
  }

  Future<void> _writeMessage(Socket socket, Uint8List data) async {
    final header = ByteData(4)..setUint32(0, data.length);
    socket.add(header.buffer.asUint8List());
    socket.add(data);
    await socket.flush();
  }

  String? _findPeerDeviceName(String siteId) {
    try {
      final match = _peers.firstWhere((p) => p.siteId == siteId);
      if (match.name != null && match.name!.isNotEmpty) return match.name;
    } catch (_) {}
    return null;
  }

  Uint8List _getRandomBytes(int count) {
    if (randomBytes != null) return randomBytes!(count);
    final rand = Random.secure();
    return Uint8List.fromList(List.generate(count, (_) => rand.nextInt(256)));
  }

  /// Handles inbound connection from another device on LAN (bidirectional).
  Future<void> _handleIncomingConnection(Socket socket) async {
    final remoteIp = socket.remoteAddress.address;
    final guard = serverGuard;
    if (guard != null && !guard.tryAcquire(remoteIp)) {
      socket.destroy();
      return;
    }

    final reader = FrameReader(socket);
    try {
      final householdRes = await householdRepository.getHousehold();
      final household = householdRes.valueOrNull;
      final keyRes = await keyStore.read();
      final key = keyRes.valueOrNull;

      if (household == null || key == null) {
        socket.destroy();
        return;
      }

      // Mutual authentication via challenge-response (RN-403, RN-404, CA-2.1)
      final localDeviceName = await _resolveLocalDeviceName(household);
      final handshake = LanAuthHandshake(
        key: key,
        randomBytes: _getRandomBytes,
      );

      final authResult = await handshake.runAsServer(
        reader,
        socket,
        limits,
        localSiteId: household.localSiteId,
        localDeviceName: localDeviceName,
      );
      if (authResult.isErr) {
        guard?.recordAuthFailure(remoteIp);
        socket.destroy();
        return;
      }
      await socket.flush();

      final session = authResult.valueOrNull!;

      // Check whether peer is announced candidate or already paired member (RN-410, CA-2.8, CA-2.10)
      final membersRes = await householdRepository.getMembers();
      final members = membersRes.valueOrNull ?? [];
      final handshakeSiteId = session.remoteSiteId;
      final isHandshakePaired =
          handshakeSiteId != null &&
          handshakeSiteId.isNotEmpty &&
          members.any((m) => m.siteId == handshakeSiteId);
      final announcedCandidate = _candidates.values
          .cast<LanCandidate?>()
          .firstWhere((c) => c?.address == remoteIp, orElse: () => null);
      final isAnnounced = announcedCandidate != null;

      if ((isAnnounced || isHandshakePaired) &&
          handshakeSiteId != null &&
          handshakeSiteId.isNotEmpty) {
        final regAddress =
            announcedCandidate?.address ?? socket.remoteAddress.address;
        final regPort =
            announcedCandidate?.port ??
            (preferredPort > 0 ? preferredPort : defaultPort);
        final peerName =
            (session.remoteDeviceName != null &&
                session.remoteDeviceName!.isNotEmpty)
            ? session.remoteDeviceName!
            : (_findPeerDeviceName(handshakeSiteId) ?? 'Aparelho Conectado');

        registerPeer(
          DiscoveredPeer(
            siteId: handshakeSiteId,
            name: peerName,
            address: regAddress,
            port: regPort,
          ),
        );
        await householdRepository.upsertMember(
          siteId: handshakeSiteId,
          deviceName: peerName,
          lastSeenAt: clock.nowUtc(),
        );
      }

      // Read post-authentication binary packet (RN-405, CA-2.2)
      final payload = await reader.next(
        maxBytes: limits.lanMaxMessageBytes,
        timeout: limits.lanReadTimeout,
      );

      if (payload != null && payload.isNotEmpty) {
        final openResult = await codec.open(payload, session.sessionKey);
        if (openResult.isOk) {
          final batch = openResult.valueOrNull!;
          if (batch.householdId == household.id) {
            await batchApplier.apply(batch);

            final effectiveSiteId =
                (session.remoteSiteId != null &&
                    session.remoteSiteId!.isNotEmpty)
                ? session.remoteSiteId!
                : batch.fromSiteId;

            final isPaired = members.any((m) => m.siteId == effectiveSiteId);

            if (isAnnounced || isPaired) {
              final regAddress =
                  announcedCandidate?.address ?? socket.remoteAddress.address;
              final regPort =
                  announcedCandidate?.port ??
                  (preferredPort > 0 ? preferredPort : defaultPort);
              final peerName =
                  (session.remoteDeviceName != null &&
                      session.remoteDeviceName!.isNotEmpty)
                  ? session.remoteDeviceName!
                  : (_findPeerDeviceName(effectiveSiteId) ??
                        'Aparelho Conectado');

              registerPeer(
                DiscoveredPeer(
                  siteId: effectiveSiteId,
                  name: peerName,
                  address: regAddress,
                  port: regPort,
                ),
              );
              await householdRepository.upsertMember(
                siteId: effectiveSiteId,
                deviceName: peerName,
                lastSeenAt: clock.nowUtc(),
              );
            }

            // Reply back with local changes of this device (two-way sync)
            try {
              final SyncBatch responseBatch;
              if (batchFactory != null) {
                final factoryRes = await batchFactory!.forRecipient(
                  batch.senderVector,
                );
                responseBatch =
                    factoryRes.valueOrNull ??
                    SyncBatch(
                      householdId: household.id,
                      fromSiteId: household.localSiteId,
                      senderVector: await changeSource.localVector(),
                      changes:
                          (await changeSource.changesNotCoveredBy(
                            batch.senderVector,
                            household.sharedAreas,
                          )).valueOrNull ??
                          [],
                      purged: await tombstoneStore.getAllTombstones(),
                    );
              } else {
                final localChangesRes = await changeSource.changesNotCoveredBy(
                  batch.senderVector,
                  household.sharedAreas,
                );
                final localChanges = localChangesRes.valueOrNull ?? [];
                final tombstones = await tombstoneStore.getAllTombstones();
                final localVector = await changeSource.localVector();

                responseBatch = SyncBatch(
                  householdId: household.id,
                  fromSiteId: household.localSiteId,
                  senderVector: localVector,
                  changes: localChanges,
                  purged: tombstones,
                );
              }

              final sealRes = await codec.seal(
                responseBatch,
                session.sessionKey,
              );
              if (sealRes.isOk) {
                final responseBytes = sealRes.valueOrNull!;
                await _writeMessage(socket, responseBytes);
              }
            } catch (_) {
              // Resposta opcional/best-effort
            }
          }
        }
      }
    } catch (_) {
      // Ignora falhas isoladas de socket para robustez (CA-6.2)
    } finally {
      guard?.release();
      await reader.cancel();
      socket.destroy();
    }
  }

  @override
  Future<Result<SyncReport, Failure>> syncNow() async {
    try {
      final householdRes = await householdRepository.getHousehold();
      final household = householdRes.valueOrNull;
      if (household == null) {
        return const Ok(SyncReport());
      }

      final keyRes = await keyStore.read();
      final key = keyRes.valueOrNull;
      if (key == null) {
        return const Err(HouseholdFailure('Chave da casa ausente.'));
      }

      // Attempt to recover saved known IPs if in-memory list is empty
      if (_peers.isEmpty && db != null) {
        try {
          final cachedIps = await db!
              .customSelect(
                "SELECT value FROM settings WHERE key LIKE 'sync_peer_%_ip';",
              )
              .get();
          for (final row in cachedIps) {
            final val = row.read<String>('value');
            final parts = val.split(':');
            if (parts.isNotEmpty) {
              final addr = parts[0];
              final port = parts.length > 1
                  ? int.tryParse(parts[1]) ??
                        (preferredPort > 0 ? preferredPort : 42424)
                  : (preferredPort > 0 ? preferredPort : 42424);
              registerPeer(
                DiscoveredPeer(
                  siteId: 'cached_peer',
                  name: 'Aparelho Conhecido',
                  address: addr,
                  port: port,
                ),
              );
            }
          }
        } catch (_) {}
      }

      // If still empty but valid announced candidates exist, include for contact (RN-410)
      if (_peers.isEmpty && _candidates.isNotEmpty) {
        for (final candidate in _candidates.values) {
          _peers.add(
            DiscoveredPeer(
              siteId: 'candidate_${candidate.address}_${candidate.port}',
              name: 'Aparelho Anunciado',
              address: candidate.address,
              port: candidate.port,
            ),
          );
        }
      }

      if (_peers.isEmpty) {
        return const Ok(SyncReport());
      }

      var sentCount = 0;
      var contacted = 0;

      for (final peer in List<DiscoveredPeer>.from(_peers)) {
        Socket? clientSocket;
        FrameReader? reader;
        try {
          clientSocket = await Socket.connect(
            peer.address,
            peer.port,
            timeout: limits.lanPreAuthTimeout,
          );
          contacted++;
          reader = FrameReader(clientSocket);

          // Mutual authentication via challenge-response (RN-403, RN-404, CA-2.1)
          final localDeviceName = await _resolveLocalDeviceName(household);
          final handshake = LanAuthHandshake(
            key: key,
            randomBytes: _getRandomBytes,
          );
          final authResult = await handshake.runAsClient(
            reader,
            clientSocket,
            limits,
            localSiteId: household.localSiteId,
            localDeviceName: localDeviceName,
          );
          if (authResult.isErr) {
            continue;
          }

          final session = authResult.valueOrNull!;

          // 1. Generate batch with changes we have
          final SyncBatch batch;
          if (batchFactory != null) {
            final factoryRes = await batchFactory!.forRecipient(null);
            batch =
                factoryRes.valueOrNull ??
                SyncBatch(
                  householdId: household.id,
                  fromSiteId: household.localSiteId,
                  senderVector: await changeSource.localVector(),
                  changes:
                      (await changeSource.changesNotCoveredBy(
                        const VersionVector({}),
                        household.sharedAreas,
                      )).valueOrNull ??
                      [],
                  purged: await tombstoneStore.getAllTombstones(),
                );
          } else {
            final changesRes = await changeSource.changesNotCoveredBy(
              const VersionVector({}),
              household.sharedAreas,
            );
            final changes = changesRes.valueOrNull ?? [];
            final tombstones = await tombstoneStore.getAllTombstones();
            final localVector = await changeSource.localVector();

            batch = SyncBatch(
              householdId: household.id,
              fromSiteId: household.localSiteId,
              senderVector: localVector,
              changes: changes,
              purged: tombstones,
            );
          }

          final sealRes = await codec.seal(batch, session.sessionKey);
          if (sealRes.isOk) {
            final bytes = sealRes.valueOrNull!;
            await _writeMessage(clientSocket, bytes);
            sentCount += batch.changes.length;

            // 2. Read response with server changes (two-way sync)
            try {
              final responseBytes = await reader.next(
                maxBytes: limits.lanMaxMessageBytes,
                timeout: limits.lanReadTimeout,
              );
              if (responseBytes != null && responseBytes.isNotEmpty) {
                final openRes = await codec.open(
                  responseBytes,
                  session.sessionKey,
                );
                if (openRes.isOk) {
                  final responseBatch = openRes.valueOrNull!;
                  if (responseBatch.householdId == household.id) {
                    await batchApplier.apply(responseBatch);
                    final peerName =
                        (session.remoteDeviceName != null &&
                            session.remoteDeviceName!.isNotEmpty)
                        ? session.remoteDeviceName!
                        : ((peer.name != null && peer.name!.isNotEmpty)
                              ? peer.name!
                              : 'Aparelho Conectado');
                    final effectiveSiteId =
                        (session.remoteSiteId != null &&
                            session.remoteSiteId!.isNotEmpty)
                        ? session.remoteSiteId!
                        : responseBatch.fromSiteId;
                    registerPeer(
                      DiscoveredPeer(
                        siteId: effectiveSiteId,
                        name: peerName,
                        address: peer.address,
                        port: peer.port,
                      ),
                    );
                    await householdRepository.upsertMember(
                      siteId: effectiveSiteId,
                      deviceName: peerName,
                      lastSeenAt: clock.nowUtc(),
                    );
                  }
                }
              }
            } catch (_) {
              // Tolerante se o par for unidirecional ou falhar ao responder
            }
          }

          // Update contacted member in local database with authenticated data
          final effectivePeerName =
              (session.remoteDeviceName != null &&
                  session.remoteDeviceName!.isNotEmpty)
              ? session.remoteDeviceName!
              : ((peer.name != null && peer.name!.isNotEmpty)
                    ? peer.name!
                    : 'Aparelho Conectado');
          final effectivePeerSiteId =
              (session.remoteSiteId != null && session.remoteSiteId!.isNotEmpty)
              ? session.remoteSiteId!
              : peer.siteId;
          await householdRepository.upsertMember(
            siteId: effectivePeerSiteId,
            deviceName: effectivePeerName,
            lastSeenAt: clock.nowUtc(),
          );
        } catch (e) {
          // Network error with specific peer does not abort overall synchronization (CA-6.2)
        } finally {
          await reader?.cancel();
          clientSocket?.destroy();
        }
      }

      return Ok(
        SyncReport(sentChangesCount: sentCount, peersContactedCount: contacted),
      );
    } catch (e) {
      return const Err(NetworkFailure(isOffline: false));
    }
  }

  void dispose() {
    stop();
    _peersController.close();
  }
}
