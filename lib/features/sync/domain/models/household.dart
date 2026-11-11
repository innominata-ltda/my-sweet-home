import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';

/// Representation of a shared household in the domain.
final class Household {
  final String id;
  final String name;
  final String localSiteId;
  final Set<SyncArea> sharedAreas;
  final DateTime createdAt;
  final DateTime joinedAt;
  final bool active;

  const Household({
    required this.id,
    required this.name,
    required this.localSiteId,
    required this.sharedAreas,
    required this.createdAt,
    required this.joinedAt,
    this.active = true,
  });

  Household copyWith({
    String? id,
    String? name,
    String? localSiteId,
    Set<SyncArea>? sharedAreas,
    DateTime? createdAt,
    DateTime? joinedAt,
    bool? active,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      localSiteId: localSiteId ?? this.localSiteId,
      sharedAreas: sharedAreas ?? this.sharedAreas,
      createdAt: createdAt ?? this.createdAt,
      joinedAt: joinedAt ?? this.joinedAt,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          localSiteId == other.localSiteId &&
          active == other.active;

  @override
  int get hashCode => Object.hash(id, name, localSiteId, active);
}

/// Representation of a member device of household in the domain.
final class Member {
  final String id;
  final String householdId;
  final String siteId;
  final String name;
  final DateTime joinedAt;
  final DateTime? lastSeenAt;
  final bool active;

  const Member({
    required this.id,
    required this.householdId,
    required this.siteId,
    required this.name,
    required this.joinedAt,
    this.lastSeenAt,
    this.active = true,
  });

  Member copyWith({
    String? id,
    String? householdId,
    String? siteId,
    String? name,
    DateTime? joinedAt,
    DateTime? lastSeenAt,
    bool? active,
  }) {
    return Member(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      siteId: siteId ?? this.siteId,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          siteId == other.siteId &&
          householdId == other.householdId;

  @override
  int get hashCode => Object.hash(id, siteId, householdId);
}

/// Preview data of local records by area before joining a household (RN-314).
final class HouseholdJoinPreviewData {
  final int homeRecordsCount;
  final int financeRecordsCount;
  final int catalogRecordsCount;

  const HouseholdJoinPreviewData({
    this.homeRecordsCount = 0,
    this.financeRecordsCount = 0,
    this.catalogRecordsCount = 0,
  });

  int get totalRecordsCount =>
      homeRecordsCount + financeRecordsCount + catalogRecordsCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdJoinPreviewData &&
          runtimeType == other.runtimeType &&
          homeRecordsCount == other.homeRecordsCount &&
          financeRecordsCount == other.financeRecordsCount &&
          catalogRecordsCount == other.catalogRecordsCount;

  @override
  int get hashCode =>
      Object.hash(homeRecordsCount, financeRecordsCount, catalogRecordsCount);
}
