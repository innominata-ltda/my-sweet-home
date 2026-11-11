import '../../../core/config/security_limits.dart';
import '../../../core/time/clock.dart';

/// Security guard for LAN server against connection exhaustion and brute-force (RN-406, RN-407).
final class LanServerGuard {
  final SecurityLimits limits;
  final Clock clock;

  int _activeConnections = 0;
  final Map<String, List<DateTime>> _failuresByAddress = {};
  final Map<String, DateTime> _bannedUntilByAddress = {};

  LanServerGuard({required this.limits, required this.clock});

  /// Attempts to acquire a slot for connection from [remoteAddress].
  ///
  /// Returns `false` if address is banned or if concurrent connection
  /// limit has been reached.
  bool tryAcquire(String remoteAddress) {
    final now = clock.nowUtc();

    // 1. Check if banned
    final bannedUntil = _bannedUntilByAddress[remoteAddress];
    if (bannedUntil != null) {
      if (now.isBefore(bannedUntil)) {
        return false;
      }
      _bannedUntilByAddress.remove(remoteAddress);
    }

    // 2. Check concurrent connection limit
    if (_activeConnections >= limits.lanMaxConcurrentConnections) {
      return false;
    }

    _activeConnections++;
    return true;
  }

  /// Releases previously acquired connection slot.
  void release() {
    if (_activeConnections > 0) {
      _activeConnections--;
    }
  }

  /// Records authentication/handshake failure for [remoteAddress].
  ///
  /// If number of failures within window [SecurityLimits.lanAuthFailureWindow]
  /// reaches [SecurityLimits.lanMaxAuthFailures], IP is banned for [SecurityLimits.lanBanDuration].
  void recordAuthFailure(String remoteAddress) {
    final now = clock.nowUtc();
    final cutoff = now.subtract(limits.lanAuthFailureWindow);

    final failures = _failuresByAddress.putIfAbsent(remoteAddress, () => []);
    failures.add(now);
    failures.removeWhere((timestamp) => timestamp.isBefore(cutoff));

    if (failures.length >= limits.lanMaxAuthFailures) {
      _bannedUntilByAddress[remoteAddress] = now.add(limits.lanBanDuration);
      _failuresByAddress.remove(remoteAddress);
    }
  }
}
