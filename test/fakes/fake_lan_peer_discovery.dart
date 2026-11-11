library;

import 'dart:async';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/lan_peer_discovery_port.dart';

/// Fake for unit and integration tests of LAN discovery without real mDNS (RN-410, RN-411).
class FakeLanPeerDiscovery implements LanPeerDiscoveryPort {
  bool isStarted = false;
  String? currentAdvertisedTag;
  int? currentPort;

  final List<LanCandidate> _candidates = [];
  final _controller = StreamController<List<LanCandidate>>.broadcast();

  void emitCandidates(List<LanCandidate> candidates) {
    _candidates
      ..clear()
      ..addAll(candidates);
    _controller.add(List.unmodifiable(_candidates));
  }

  @override
  Future<Result<void, Failure>> start({
    required int port,
    required String advertisedTag,
  }) async {
    isStarted = true;
    currentPort = port;
    currentAdvertisedTag = advertisedTag;
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> stop() async {
    isStarted = false;
    currentPort = null;
    currentAdvertisedTag = null;
    _candidates.clear();
    _controller.add(const []);
    return const Ok(null);
  }

  @override
  Stream<List<LanCandidate>> watchCandidates() async* {
    yield List.unmodifiable(_candidates);
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
