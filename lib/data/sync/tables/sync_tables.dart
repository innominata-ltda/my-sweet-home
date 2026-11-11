library;

// coverage:ignore-file
import 'package:drift/drift.dart';

/// Shared household.
class SyncHouseholds extends Table {
  @override
  String get tableName => 'sync_household';

  /// Household UUID.
  TextColumn get id => text()();

  /// Household name (e.g., "Family Home").
  TextColumn get name => text()();

  /// Local device site ID in this household.
  TextColumn get localSiteId => text().named('local_site_id')();

  /// Active shared areas separated by commas (e.g., "catalog,home,finance").
  TextColumn get sharedAreas => text().named('shared_areas')();

  /// Household creation timestamp (ISO-8601 UTC).
  TextColumn get createdAt => text().named('created_at')();

  /// Timestamp when this device joined the household (ISO-8601 UTC).
  TextColumn get joinedAt => text().named('joined_at')();

  /// Whether synchronization is active on this device.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Household member devices.
class SyncMembers extends Table {
  @override
  String get tableName => 'sync_members';

  /// Member UUID.
  TextColumn get id => text()();

  /// Foreign key to household.
  TextColumn get householdId => text()
      .named('household_id')
      .references(SyncHouseholds, #id, onDelete: KeyAction.cascade)();

  /// Unique device site ID.
  TextColumn get siteId => text().named('site_id')();

  /// Visible device nickname (RN-306).
  TextColumn get name => text()();

  /// Household join timestamp (ISO-8601 UTC).
  TextColumn get joinedAt => text().named('joined_at')();

  /// Last timestamp this device was seen during sync.
  TextColumn get lastSeenAt => text().nullable().named('last_seen_at')();

  /// Whether the device is still an active member (deactivated when removed).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {householdId, siteId},
  ];
}

/// Column versions for field-level LWW-register (RN-320, RN-321).
class SyncColumnVersions extends Table {
  @override
  String get tableName => 'sync_column_versions';

  /// Database table name.
  TextColumn get tableNameCol => text().named('table_name')();

  /// Primary key of the row.
  TextColumn get rowId => text().named('row_id')();

  /// Column name.
  TextColumn get columnName => text().named('column_name')();

  /// Lexicographically packed HLC.
  TextColumn get hlc => text()();

  /// Device site ID that originated the change.
  TextColumn get siteId => text().named('site_id')();

  /// Local record timestamp (ISO-8601 UTC).
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column> get primaryKey => {tableNameCol, rowId, columnName};
}

/// Tombstones for rows permanently deleted after trash purge (RN-322).
class SyncRowTombstones extends Table {
  @override
  String get tableName => 'sync_row_tombstones';

  /// Unique tombstone ID.
  TextColumn get id => text()();

  /// Table name of the purged row.
  TextColumn get tableNameCol => text().named('table_name')();

  /// Primary key of the purged row.
  TextColumn get rowId => text().named('row_id')();

  /// HLC of the purge moment.
  TextColumn get hlc => text()();

  /// Purge timestamp (ISO-8601 UTC).
  TextColumn get purgedAt => text().named('purged_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {tableNameCol, rowId},
  ];
}

/// Known version vectors per device in the household.
class SyncPeerVectors extends Table {
  @override
  String get tableName => 'sync_peer_vectors';

  /// Household ID.
  TextColumn get householdId => text().named('household_id')();

  /// Remote device site ID.
  TextColumn get siteId => text().named('site_id')();

  /// Highest known HLC for this device.
  TextColumn get hlc => text()();

  /// Last update timestamp of this vector (ISO-8601 UTC).
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column> get primaryKey => {householdId, siteId};
}

/// Sync acknowledgments (acks) per member and origin (RN-428, SPEC-016).
class SyncMemberAcks extends Table {
  @override
  String get tableName => 'sync_member_acks';

  TextColumn get householdId => text().named('household_id')();
  TextColumn get memberSiteId => text().named('member_site_id')();
  TextColumn get originSiteId => text().named('origin_site_id')();
  TextColumn get hlc => text()();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column> get primaryKey => {householdId, memberSiteId, originSiteId};
}

/// Sync bundles (.mshsync) already applied for idempotency (RN-413, SPEC-016).
class SyncAppliedBundles extends Table {
  @override
  String get tableName => 'sync_applied_bundles';

  TextColumn get digest => text()();
  TextColumn get appliedAt => text().named('applied_at')();

  @override
  Set<Column> get primaryKey => {digest};
}

/// Compaction horizon per household and origin site (RN-429, SPEC-016).
class SyncCompactionHorizon extends Table {
  @override
  String get tableName => 'sync_compaction_horizon';

  TextColumn get householdId => text().named('household_id')();
  TextColumn get originSiteId => text().named('origin_site_id')();
  TextColumn get hlc => text()();

  @override
  Set<Column> get primaryKey => {householdId, originSiteId};
}
