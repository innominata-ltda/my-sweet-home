library;

import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';

/// In-memory fake of [DiagnosticLogPort] for unit and architecture tests.
final class FakeDiagnosticLog implements DiagnosticLogPort {
  final List<DiagnosticEntry> _entries = [];

  @override
  Future<void> record(DiagnosticEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<DiagnosticEntry>> entries() async {
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> wipe() async {
    _entries.clear();
  }
}
