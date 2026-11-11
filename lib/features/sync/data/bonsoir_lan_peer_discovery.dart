library;

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';

/// Implementation of mDNS / Zeroconf discovery service via Bonsoir package (RF-122, CA-3.1, RN-411, ADR-0010).
class BonsoirLanPeerDiscovery implements LanPeerDiscoveryPort {
  static const String serviceType = '_mshsync._tcp';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  final Map<String, LanCandidate> _candidatesByService = {};
  final _candidatesController =
      StreamController<List<LanCandidate>>.broadcast();

  String? _advertisedTag;

  /// Builds mDNS service without exposing household ID, device ID or nickname (RN-411, CA-2.9).
  static BonsoirService buildService({
    required int port,
    required String advertisedTag,
  }) {
    return BonsoirService(
      name: 'MSH-$advertisedTag',
      type: serviceType,
      port: port,
      attributes: {'tag': advertisedTag},
    );
  }

  @override
  Future<Result<void, Failure>> start({
    required int port,
    required String advertisedTag,
  }) async {
    try {
      await stop();

      _advertisedTag = advertisedTag;

      // 1. Starts broadcast without exposing household ID, device ID or nickname (RN-411)
      final service = buildService(port: port, advertisedTag: advertisedTag);

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();
      await _broadcast!.start();

      // 2. Inicia a escuta (Discovery) de outros candidatos na rede
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.initialize();

      _discoverySub = _discovery!.eventStream?.listen(_onDiscoveryEvent);
      await _discovery!.start();

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao iniciar descoberta LAN mDNS: $e',
          cause: e,
        ),
      );
    }
  }

  void _onDiscoveryEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      // When a service is found, requests IP and TXT attribute resolution
      event.service.resolve(_discovery!.serviceResolver);
    } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
      _handleResolvedService(event.service);
    } else if (event is BonsoirDiscoveryServiceUpdatedEvent) {
      _handleResolvedService(event.service);
    } else if (event is BonsoirDiscoveryServiceLostEvent) {
      _candidatesByService.remove(event.service.name);
      _emitCandidates();
    }
  }

  void _handleResolvedService(BonsoirService service) {
    final tag = service.attributes['tag'];
    if (tag == null || tag.isEmpty) {
      return;
    }

    // Ignores this device's own broadcast
    if (tag == _advertisedTag) {
      return;
    }

    // Gets resolved address prioritizing IPv4
    String? ip;
    for (final addr in service.hostAddresses) {
      if (addr.contains('.') && !addr.contains(':')) {
        ip = addr;
        break;
      }
    }
    ip ??=
        (service.hostAddresses.isNotEmpty
            ? service.hostAddresses.first
            : null) ??
        service.hostname;
    if (ip == null || service.port <= 0) return;

    _candidatesByService[service.name] = LanCandidate(
      address: ip,
      port: service.port,
      tag: tag,
    );
    _emitCandidates();
  }

  void _emitCandidates() {
    _candidatesController.add(List.unmodifiable(_candidatesByService.values));
  }

  @override
  Future<Result<void, Failure>> stop() async {
    try {
      await _discoverySub?.cancel();
      _discoverySub = null;

      if (_discovery != null && !_discovery!.isStopped) {
        await _discovery!.stop();
      }
      _discovery = null;

      if (_broadcast != null && !_broadcast!.isStopped) {
        await _broadcast!.stop();
      }
      _broadcast = null;

      _candidatesByService.clear();
      _emitCandidates();

      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao parar descoberta LAN mDNS: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Stream<List<LanCandidate>> watchCandidates() async* {
    yield List.unmodifiable(_candidatesByService.values);
    yield* _candidatesController.stream;
  }
}
