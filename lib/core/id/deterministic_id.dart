library;

import 'package:uuid/uuid.dart';

/// Abstraction for deterministic ID generation (UUID v5) — RN-324, RN-325.
///
/// Used for:
/// - Pre-loaded seed database: identical identity across all installs (RN-325, CA-5.5).
/// - Recurring occurrences: rule + date produces same identity on any device (RN-324, CA-5.4).
abstract interface class DeterministicIdGenerator {
  /// Generates a deterministic ID for a record from the seed database.
  ///
  /// [kind] identifies the entity type (e.g. 'product', 'product_alias', 'category').
  /// [naturalKey] is the unique natural key in seed (e.g. normalized canonical name).
  String forSeed(String kind, String naturalKey);

  /// Generates a deterministic ID for a materialized occurrence of a recurrence rule.
  ///
  /// [ruleId] is the recurrence rule ID.
  /// [isoDate] is the occurrence date in ISO-8601 format (YYYY-MM-DD).
  String forOccurrence(String ruleId, String isoDate);
}

/// Standard implementation of [DeterministicIdGenerator] using UUID v5.
///
/// Pure Dart, without I/O, stable across devices and platforms.
final class UuidV5DeterministicIdGenerator implements DeterministicIdGenerator {
  const UuidV5DeterministicIdGenerator({
    this.namespace = defaultNamespace,
    this.uuid = const Uuid(),
  });

  /// Root namespace for deterministic IDs in My Sweet Home.
  static const String defaultNamespace = '9b2c34ef-7e9b-4b9e-99cf-6bfa4ecf4601';

  final String namespace;
  final Uuid uuid;

  @override
  String forSeed(String kind, String naturalKey) {
    return uuid.v5(namespace, 'seed:$kind:$naturalKey');
  }

  @override
  String forOccurrence(String ruleId, String isoDate) {
    return uuid.v5(namespace, 'occurrence:$ruleId:$isoDate');
  }
}
