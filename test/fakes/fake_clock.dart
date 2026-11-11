/// FakeClock: controllable clock for tests.
///
/// Injete em qualquer componente que receba [Clock]. Permite congelar o tempo
/// and advance deterministically without waiting for the real clock (CA-3.1).
library;

import 'package:my_sweet_home/core/time/clock.dart';

/// Implementation of [Clock] for tests — fixed time, manually advanceable.
///
/// Exemplo de uso:
/// ```dart
/// final clock = FakeClock(DateTime.utc(2026, 3, 10, 12, 0));
/// expect(clock.nowUtc(), DateTime.utc(2026, 3, 10, 12, 0));
/// clock.advance(const Duration(days: 1));
/// expect(clock.nowUtc(), DateTime.utc(2026, 3, 11, 12, 0));
/// ```
final class FakeClock extends Clock {
  FakeClock(DateTime initial)
    : _current = initial.isUtc ? initial : initial.toUtc();

  DateTime _current;

  @override
  DateTime nowUtc() => _current;

  @override
  DateTime nowLocal() => _current.toLocal();

  /// Advances the clock by [duration].
  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  /// Define o instante exato (em UTC).
  void setTo(DateTime instant) {
    _current = instant.isUtc ? instant : instant.toUtc();
  }
}
