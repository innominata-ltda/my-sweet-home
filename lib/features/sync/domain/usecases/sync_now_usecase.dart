library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

/// Use case triggered by "Sync now" button or app launch (RF-122, CA-3.1, CA-6.2, T-11).
class SyncNowUseCase {
  final SyncTransportPort _transport;

  const SyncNowUseCase(this._transport);

  /// Executes synchronization with devices on same network.
  Future<Result<SyncReport, Failure>> execute() {
    return _transport.syncNow();
  }
}
