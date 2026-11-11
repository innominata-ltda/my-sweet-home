library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralizes all numeric and temporal security and performance limits
/// for the application (RN-431).
///
/// No other part of the codebase should define literals for these limits.
final class SecurityLimits {
  const SecurityLimits({
    this.maxBackupBytes = 200 * 1024 * 1024,
    this.kdfMemoryKibMin = 19456,
    this.kdfMemoryKibMax = 65536,
    this.kdfIterationsMin = 2,
    this.kdfIterationsMax = 10,
    this.kdfParallelismMin = 1,
    this.kdfParallelismMax = 4,
    this.kdfHashLength = 32,
    this.lanPreAuthMaxBytes = 4 * 1024,
    this.lanPreAuthTimeout = const Duration(seconds: 5),
    this.lanMaxMessageBytes = 16 * 1024 * 1024,
    this.lanReadTimeout = const Duration(seconds: 30),
    this.lanMaxConcurrentConnections = 2,
    this.lanMaxAuthFailures = 5,
    this.lanAuthFailureWindow = const Duration(minutes: 1),
    this.lanBanDuration = const Duration(minutes: 5),
    this.discoveryTagRotation = const Duration(hours: 24),
    this.tombstoneRetention = const Duration(days: 90),
    this.searchDebounce = const Duration(milliseconds: 250),
    this.diagnosticLogMaxBytes = 1024 * 1024,
  });

  /// Maximum supported backup archive size (200 MB) (RN-402).
  final int maxBackupBytes;

  /// Argon2id key derivation limits (RN-400).
  final int kdfMemoryKibMin;
  final int kdfMemoryKibMax;
  final int kdfIterationsMin;
  final int kdfIterationsMax;
  final int kdfParallelismMin;
  final int kdfParallelismMax;
  final int kdfHashLength;

  /// Local network pre-authentication phase limits (RN-404).
  final int lanPreAuthMaxBytes;
  final Duration lanPreAuthTimeout;

  /// Local network authenticated message limits (RN-405).
  final int lanMaxMessageBytes;
  final Duration lanReadTimeout;

  /// Maximum concurrent connections and rate-limiting policy on LAN (RN-406, RN-407).
  final int lanMaxConcurrentConnections;
  final int lanMaxAuthFailures;
  final Duration lanAuthFailureWindow;
  final Duration lanBanDuration;

  /// Discovery tag rotation interval on LAN (RN-411).
  final Duration discoveryTagRotation;

  /// Sync compaction tombstone retention (RN-428).
  final Duration tombstoneRetention;

  /// Search debouncing duration in the UI (RN-431).
  final Duration searchDebounce;

  /// Maximum local diagnostic log file size (1 MB) (RN-434).
  final int diagnosticLogMaxBytes;
}

/// Global provider for configurable security limits.
final securityLimitsProvider = Provider<SecurityLimits>(
  (_) => const SecurityLimits(),
);
