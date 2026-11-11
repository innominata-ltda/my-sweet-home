library;

/// Household sharing functional areas (RN-310, RN-311).
enum SyncArea {
  /// Shared catalog (products, aliases, categories, stores).
  /// Always shared whenever any area is enabled (RN-311).
  catalog,

  /// Home area: shopping lists, recipes, tasks, pantry, checklist.
  home,

  /// Finance area: purchases, prices, expenses, fixed bills, payments, budgets.
  finance,
}

/// Specification of a table participating in synchronization.
final class SyncTableSpec {
  /// SQLite database table name.
  final String table;

  /// Function mapping a specific table row to its functional area.
  /// Required because certain tables (e.g. recurring_rules) belong to 'finance'
  /// or 'home' depending on the rule kind.
  final SyncArea Function(Map<String, Object?> row) areaOf;

  /// Set of local columns that MUST NOT be synchronized (RN-312).
  /// E.g. remote_event_id, receipt_image_path.
  final Set<String> excludedColumns;

  /// Natural key columns for duplicate resolution and merging (RN-326).
  final List<String>? naturalKey;

  /// If `true`, derived table whose data is not transmitted (e.g. price_points) (RN-327).
  final bool derived;

  const SyncTableSpec({
    required this.table,
    required this.areaOf,
    this.excludedColumns = const {},
    this.naturalKey,
    this.derived = false,
  });
}

/// Contract for registry of synchronizable tables.
abstract interface class SyncTableRegistry {
  /// Returns specifications of all registered tables.
  Iterable<SyncTableSpec> get tables;

  /// Looks up table specification by name, or returns `null` if not synchronizable.
  SyncTableSpec? findTable(String table);

  /// Returns set of strictly local table names (RN-312).
  Set<String> get localTables;

  /// Returns `true` if table is strictly local (neither synchronizable nor derived).
  bool isLocal(String table);
}
