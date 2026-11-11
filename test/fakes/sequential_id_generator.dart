/// SequentialIdGenerator: deterministic ID generator for tests.
///
/// Generates IDs in `id-001`, `id-002`, etc. format — stable, short,
/// readable in test logs, and without randomness (RN-005).
// ignore_for_file: prefer_initializing_formals
library;

import 'package:my_sweet_home/core/id/id_generator.dart';

/// Implementation of [IdGenerator] for tests — sequential and predictable IDs.
///
/// Usage example:
/// ```dart
/// final gen = SequentialIdGenerator();
/// expect(gen.newId(), 'id-001');
/// expect(gen.newId(), 'id-002');
/// gen.reset();
/// expect(gen.newId(), 'id-001');
/// ```
final class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator({String prefix = 'id', int start = 1})
    : _prefix = prefix,
      _counter = start;

  final String _prefix;
  int _counter;

  @override
  String newId() {
    final id = '$_prefix-${_counter.toString().padLeft(3, '0')}';
    _counter++;
    return id;
  }

  /// Reinicia o contador para o valor inicial.
  void reset({int start = 1}) {
    _counter = start;
  }
}
