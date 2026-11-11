library;

import 'hlc.dart';

/// Version vector tracking highest known [Hlc] for each device ([siteId]).
final class VersionVector {
  /// Mapping of siteId → highest known Hlc from that site.
  final Map<String, Hlc> maxBySite;

  const VersionVector(this.maxBySite);

  /// Empty vector.
  static const empty = VersionVector({});

  /// Returns `true` if this vector covers the provided [Hlc].
  ///
  /// An HLC is covered if the vector has an entry for its [siteId]
  /// with HLC greater than or equal to [h].
  bool covers(Hlc h) {
    final siteHlc = maxBySite[h.siteId];
    if (siteHlc == null) return false;
    return siteHlc.compareTo(h) >= 0;
  }

  /// Merges this vector with another, retaining the maximum HLC per site.
  VersionVector merge(VersionVector other) {
    final merged = Map<String, Hlc>.from(maxBySite);
    for (final entry in other.maxBySite.entries) {
      final current = merged[entry.key];
      if (current == null || entry.value.compareTo(current) > 0) {
        merged[entry.key] = entry.value;
      }
    }
    return VersionVector(merged);
  }

  /// Returns an updated vector incorporating [Hlc] if it exceeds current value for site.
  VersionVector update(Hlc h) {
    final current = maxBySite[h.siteId];
    if (current == null || h.compareTo(current) > 0) {
      final next = Map<String, Hlc>.from(maxBySite)..[h.siteId] = h;
      return VersionVector(next);
    }
    return this;
  }

  /// Serializes to JSON map (siteId → packed HLC).
  Map<String, String> toJson() => {
    for (final entry in maxBySite.entries) entry.key: entry.value.pack(),
  };

  /// Reconstructs from JSON map.
  factory VersionVector.fromJson(Map<String, dynamic> json) {
    final map = <String, Hlc>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is String) {
        map[entry.key] = Hlc.parse(value);
      } else if (value is Hlc) {
        map[entry.key] = value;
      }
    }
    return VersionVector(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VersionVector) return false;
    if (maxBySite.length != other.maxBySite.length) return false;
    for (final entry in maxBySite.entries) {
      if (other.maxBySite[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    var h = 0;
    for (final entry in maxBySite.entries) {
      h ^= Object.hash(entry.key, entry.value);
    }
    return h;
  }

  @override
  String toString() => 'VersionVector($maxBySite)';
}
