library;

import 'package:my_sweet_home/core/result/result.dart';

/// Executed synchronization report (RF-122, CA-3.1, T-11).
final class SyncReport {
  final int sentChangesCount;
  final int appliedChangesCount;
  final int peersContactedCount;

  const SyncReport({
    this.sentChangesCount = 0,
    this.appliedChangesCount = 0,
    this.peersContactedCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncReport &&
          runtimeType == other.runtimeType &&
          sentChangesCount == other.sentChangesCount &&
          appliedChangesCount == other.appliedChangesCount &&
          peersContactedCount == other.peersContactedCount;

  @override
  int get hashCode =>
      Object.hash(sentChangesCount, appliedChangesCount, peersContactedCount);
}

/// Representation of a node/device discovered on local network (mDNS / Wi-Fi).
final class DiscoveredPeer {
  final String siteId;
  final String? name;
  final String address;
  final int port;

  const DiscoveredPeer({
    required this.siteId,
    this.name,
    required this.address,
    required this.port,
  });
}

/// Household synchronization transport port (RF-122, CA-3.1, CA-6.2, T-11).
abstract interface class SyncTransportPort {
  /// Starts announcement and listening for devices on local network.
  Future<Result<void, Failure>> start();

  /// Stops announcement and synchronization server.
  Future<Result<void, Failure>> stop();

  /// Triggers immediate synchronization against known peers (RF-122, CA-3.1, CA-6.2).
  Future<Result<SyncReport, Failure>> syncNow();

  /// Observa os aparelhos conectados ou descobertos na mesma rede.
  Stream<List<DiscoveredPeer>> watchPeers();
}
