library;

import 'dart:convert';
import 'dart:io';

import '../config/security_limits.dart';
import 'diagnostic_log_port.dart';

/// File-based implementation of [DiagnosticLogPort] (RN-432, RN-434, RN-435).
///
/// Keeps log file capped at [SecurityLimits.diagnosticLogMaxBytes] (default 1 MB),
/// trimming oldest lines when exceeding capacity limit.
final class FileDiagnosticLog implements DiagnosticLogPort {
  FileDiagnosticLog({required this.file, SecurityLimits? limits})
    : limits = limits ?? const SecurityLimits();

  final File file;
  final SecurityLimits limits;

  @override
  Future<void> record(DiagnosticEntry entry) async {
    final line = '${entry.encode()}\n';
    await file.parent.create(recursive: true);
    await file.writeAsString(line, mode: FileMode.append, flush: true);

    await _enforceMaxSizeBytes();
  }

  @override
  Future<List<DiagnosticEntry>> entries() async {
    if (!file.existsSync()) {
      return const [];
    }

    final lines = await file.readAsLines();
    final result = <DiagnosticEntry>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        result.add(DiagnosticEntry.decode(trimmed));
      } catch (_) {
        // Ignore corrupted lines
      }
    }
    return result;
  }

  @override
  Future<void> wipe() async {
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> _enforceMaxSizeBytes() async {
    if (!file.existsSync()) return;
    var length = file.lengthSync();
    if (length <= limits.diagnosticLogMaxBytes) return;

    final lines = await file.readAsLines();
    // Drop oldest lines until under max limit
    while (lines.isNotEmpty && length > limits.diagnosticLogMaxBytes) {
      final removed = lines.removeAt(0);
      length -= utf8.encode('$removed\n').length;
    }

    final newContent = lines.isEmpty ? '' : '${lines.join('\n')}\n';
    await file.writeAsString(newContent, flush: true);
  }
}
