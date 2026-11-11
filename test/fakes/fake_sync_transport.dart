library;

import 'dart:async';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

/// Fake of [SyncTransportPort] for unit, architecture, and widget tests.
class FakeSyncTransport implements SyncTransportPort {
  bool isStarted = false;
  bool shouldFailOnSync = false;
  SyncReport reportToReturn = const SyncReport(
    sentChangesCount: 2,
    appliedChangesCount: 3,
    peersContactedCount: 1,
  );

  final List<DiscoveredPeer> _peers = [];
  final _peersController = StreamController<List<DiscoveredPeer>>.broadcast();

  List<DiscoveredPeer> get peers => List.unmodifiable(_peers);

  void setPeers(List<DiscoveredPeer> peers) {
    _peers.clear();
    _peers.addAll(peers);
    _peersController.add(List.unmodifiable(_peers));
  }

  @override
  Future<Result<void, Failure>> start() async {
    isStarted = true;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> stop() async {
    isStarted = false;
    return const Ok(null);
  }

  @override
  Future<Result<SyncReport, Failure>> syncNow() async {
    if (shouldFailOnSync) {
      return const Err(NetworkFailure(isOffline: false));
    }
    return Ok(reportToReturn);
  }

  @override
  Stream<List<DiscoveredPeer>> watchPeers() async* {
    yield List.unmodifiable(_peers);
    yield* _peersController.stream;
  }

  void dispose() {
    _peersController.close();
  }
}
