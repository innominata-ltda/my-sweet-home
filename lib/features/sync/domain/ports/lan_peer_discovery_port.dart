library;

import 'package:my_sweet_home/core/result/result.dart';

/// Candidato a par descoberto na rede local via mDNS (RN-410, RN-411).
///
/// Contains address, port and rotating tag. NOT an authenticated peer
/// until it successfully passes mutual authentication handshake.
final class LanCandidate {
  final String address;
  final int port;
  final String tag;

  const LanCandidate({
    required this.address,
    required this.port,
    required this.tag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanCandidate &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          port == other.port &&
          tag == other.tag;

  @override
  int get hashCode => Object.hash(address, port, tag);

  @override
  String toString() => 'LanCandidate($address:$port, tag: $tag)';
}

/// Port for peer discovery and announcement on local network (mDNS / Zeroconf) (RF-122, RN-410, RN-411).
abstract interface class LanPeerDiscoveryPort {
  /// Starts announcement of this device and search for candidates on same local network.
  ///
  /// MUST NOT expose household identifier, device ID, or nickname in plaintext (RN-411).
  Future<Result<void, Failure>> start({
    required int port,
    required String advertisedTag,
  });

  /// Stops discovery and announcement of services on local network.
  Future<Result<void, Failure>> stop();

  /// Stream with dynamic list of candidates discovered on local network.
  Stream<List<LanCandidate>> watchCandidates();
}
