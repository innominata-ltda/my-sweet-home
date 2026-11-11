library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/remote_sync_transport.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

/// Composite transport orchestrating local (LAN) and remote (cloud) synchronization
/// according to user preferences (ADR-0011, RF-122, RF-127).
///
/// **Prioridade 1:** Rede local LAN (imediata, zero internet, P2P).
/// **Priority 2:** Async remote via user cloud if `household_sync_remote`
/// estiver permitido (RN-333, CA-8.1, CA-8.2).
class CompositeSyncTransport implements SyncTransportPort {
  final LanSyncTransport lanTransport;
  final RemoteSyncTransport remoteTransport;
  final SettingsRepository settingsRepository;

  CompositeSyncTransport({
    required this.lanTransport,
    required this.remoteTransport,
    required this.settingsRepository,
  });

  @override
  Future<Result<void, Failure>> start() async {
    return lanTransport.start();
  }

  @override
  Future<Result<void, Failure>> stop() async {
    await remoteTransport.stop();
    return lanTransport.stop();
  }

  @override
  Stream<List<DiscoveredPeer>> watchPeers() => lanTransport.watchPeers();

  @override
  Future<Result<SyncReport, Failure>> syncNow() async {
    // 1. Executes local network synchronization (LAN)
    final lanResult = await lanTransport.syncNow();

    // 2. Checks whether remote synchronization (cloud) is permitted by user
    final isRemoteAllowed = await settingsRepository
        .isHouseholdSyncRemoteAllowed();
    if (!isRemoteAllowed) {
      return lanResult;
    }

    // 3. Executes remote synchronization via user cloud
    final remoteResult = await remoteTransport.syncNow();

    // 4. Result handling and error propagation
    if (remoteResult.isErr) {
      final lanReport = lanResult.valueOrNull;
      if (lanResult.isErr ||
          lanReport == null ||
          (lanReport.peersContactedCount == 0 &&
              lanReport.sentChangesCount == 0 &&
              lanReport.appliedChangesCount == 0)) {
        return remoteResult;
      }
    }

    if (lanResult.isErr && remoteResult.isOk) {
      return remoteResult;
    }

    final lanReport = lanResult.valueOrNull ?? const SyncReport();
    final remoteReport = remoteResult.valueOrNull ?? const SyncReport();

    return Ok(
      SyncReport(
        sentChangesCount:
            lanReport.sentChangesCount + remoteReport.sentChangesCount,
        appliedChangesCount:
            lanReport.appliedChangesCount + remoteReport.appliedChangesCount,
        peersContactedCount:
            lanReport.peersContactedCount + remoteReport.peersContactedCount,
      ),
    );
  }
}
