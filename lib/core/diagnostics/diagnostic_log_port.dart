library;

import 'dart:convert';

/// Severity levels for local diagnostic logging (RN-432).
enum DiagnosticLevel { warning, error }

/// Structured record of a diagnostic failure event (RN-432, RN-433).
///
/// NEVER copies freeform messages, raw SQL, parameters, or confidential user data.
final class DiagnosticEntry {
  const DiagnosticEntry({
    required this.atUtc,
    required this.level,
    required this.origin,
    required this.errorType,
    this.frames = const [],
  });

  /// Timestamp in UTC.
  final DateTime atUtc;

  /// Severity of the occurrence.
  final DiagnosticLevel level;

  /// Code origination point (e.g. 'expenses.save', 'backup.import').
  final String origin;

  /// Runtime type name of failure or exception (e.g. 'StorageFailure').
  final String errorType;

  /// Restricted stack trace with up to 8 frames from 'package:my_sweet_home/...' (RN-433).
  final List<String> frames;

  /// Canonical constructor from error: NEVER copies message, arguments, SQL, or toString() (RN-433).
  factory DiagnosticEntry.fromError({
    required DateTime atUtc,
    required DiagnosticLevel level,
    required String origin,
    required Object error,
    StackTrace? stack,
  }) {
    final frames = <String>[];
    if (stack != null) {
      final lines = stack.toString().split('\n');
      for (final line in lines) {
        final match = RegExp(r'(package:my_sweet_home/[^\s\)]+)')
            .firstMatch(line);
        if (match != null) {
          frames.add(match.group(1)!);
          if (frames.length >= 8) break;
        }
      }
    }

    return DiagnosticEntry(
      atUtc: atUtc.isUtc ? atUtc : atUtc.toUtc(),
      level: level,
      origin: origin,
      errorType: error.runtimeType.toString(),
      frames: frames,
    );
  }

  /// Serializes entry to single-line JSON format.
  String encode() {
    return jsonEncode({
      'at': atUtc.toIso8601String(),
      'level': level.name,
      'origin': origin,
      'errorType': errorType,
      'frames': frames,
    });
  }

  /// Deserializes a JSON line into [DiagnosticEntry].
  static DiagnosticEntry decode(String line) {
    final map = jsonDecode(line) as Map<String, dynamic>;
    return DiagnosticEntry(
      atUtc: DateTime.parse(map['at'] as String),
      level: DiagnosticLevel.values.byName(map['level'] as String),
      origin: map['origin'] as String,
      errorType: map['errorType'] as String,
      frames: (map['frames'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

/// Abstract port for local diagnostic logging (RN-432..RN-435).
abstract interface class DiagnosticLogPort {
  /// Records a new diagnostic entry.
  Future<void> record(DiagnosticEntry entry);

  /// Returns recorded diagnostic entries in chronological order.
  Future<List<DiagnosticEntry>> entries();

  /// Erases all diagnostic entries from the local device (RN-435).
  Future<void> wipe();
}
