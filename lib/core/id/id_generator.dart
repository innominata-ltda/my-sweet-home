/// ID generation abstraction — all ID creation MUST use [IdGenerator].
///
/// In production: UUID v7 (time-ordered).
/// In tests: [SequentialIdGenerator] (deterministic, inspectable, controllable).
/// (RN-005)
library;

// ---------------------------------------------------------------------------
// Port
// ---------------------------------------------------------------------------

/// Generates a new unique identifier for an entity.
abstract interface class IdGenerator {
  /// Returns a new unique ID as a string.
  String newId();
}

// ---------------------------------------------------------------------------
// Production adapter
// ---------------------------------------------------------------------------

/// Generates time-ordered UUIDs v7.
///
/// UUID v7 = 48-bit timestamp (ms) + rand_a (12 bits) + rand_b (62 bits).
/// Reference: RFC 9562 §5.7.
///
/// Format: `xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx`
/// where nibble 13 is '7' (version) and nibble 17 has bits 10xx (variant).
final class UuidV7Generator implements IdGenerator {
  const UuidV7Generator();

  @override
  String newId() => _generateV7();

  static String _generateV7() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 48-bit timestamp
    final tsHigh = (now >> 16) & 0xFFFFFFFF; // bits 47..16
    final tsLow = now & 0xFFFF; // bits 15..0

    // rand_a: 12 random bits
    final randA = _rand12();

    // rand_b: 62 random bits (across two 31-bit integers)
    final randBHigh = _rand31();
    final randBLow = _rand31();

    // version nibble = 7
    final ver7 = 0x7000 | randA;

    // variant bits 10xx (RFC 4122 / 9562)
    final variantBits = 0x8000 | (randBHigh & 0x3FFF);

    return [
      _hex8(tsHigh),
      '-',
      _hex4(tsLow),
      '-',
      _hex4(ver7),
      '-',
      _hex4(variantBits),
      '-',
      _hex4((randBHigh >> 14) & 0xFFFF),
      _hex8(randBLow & 0xFFFFFFFF),
    ].join();
  }

  // Simple generation without dart:math — uses DateTime for supplemental entropy
  static int _seed = 0;

  static int _rand31() {
    _seed = (_seed * 1664525 + 1013904223) & 0x7FFFFFFF;
    _seed ^= DateTime.now().microsecondsSinceEpoch & 0xFFFF;
    return _seed;
  }

  static int _rand12() => _rand31() & 0xFFF;

  static String _hex8(int n) =>
      n.toRadixString(16).padLeft(8, '0').substring(0, 8);
  static String _hex4(int n) => (n & 0xFFFF).toRadixString(16).padLeft(4, '0');
}
