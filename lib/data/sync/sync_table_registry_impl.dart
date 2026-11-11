library;

import '../../core/sync/domain/sync_table_registry.dart';

/// Canonical implementation of the table, area, and column registry for
/// household P2P sync (RF-121, RN-310..RN-313, RN-326, RN-327).
class SyncTableRegistryImpl implements SyncTableRegistry {
  final Map<String, SyncTableSpec> _specs;
  final Set<String> _localTables;

  SyncTableRegistryImpl({
    Map<String, SyncTableSpec>? specs,
    Set<String>? localTables,
  }) : _specs = Map.unmodifiable(specs ?? _defaultSpecs),
       _localTables = Set.unmodifiable(localTables ?? defaultLocalTables);

  @override
  Iterable<SyncTableSpec> get tables => _specs.values;

  @override
  SyncTableSpec? findTable(String table) => _specs[table];

  @override
  Set<String> get localTables => _localTables;

  @override
  bool isLocal(String table) => _localTables.contains(table);

  /// Returns active areas taking into account that catalog always accompanies
  /// any selected functional shared area (Home or Finance) (RN-311).
  /// If no functional area is selected, catalog is not shared in isolation.
  static Set<SyncArea> effectiveAreas(Set<SyncArea> selectedAreas) {
    final hasFunctionalArea =
        selectedAreas.contains(SyncArea.home) ||
        selectedAreas.contains(SyncArea.finance);
    if (!hasFunctionalArea) return const {};
    return {...selectedAreas, SyncArea.catalog};
  }

  /// Strictly local tables that must NOT be synchronized (RN-312).
  ///
  /// Includes settings, consents, local image attachments, local OCR denials,
  /// and sync infrastructure operational metadata.
  static const Set<String> defaultLocalTables = {
    'settings',
    'consents',
    'attachments',
    'product_denials',
    'sync_household',
    'sync_members',
    'sync_column_versions',
    'sync_row_tombstones',
    'sync_peer_vectors',
    'sync_member_acks',
    'sync_applied_bundles',
    'sync_compaction_horizon',
  };

  /// Canonical specifications of all shareable and derived app tables.
  static final Map<String, SyncTableSpec> _defaultSpecs = {
    // -------------------------------------------------------------------------
    // Shared catalog (RN-311: always synchronized if any area is active)
    // -------------------------------------------------------------------------
    'products': const SyncTableSpec(
      table: 'products',
      areaOf: _areaCatalog,
      naturalKey: ['canonical_name'],
    ),
    'product_aliases': const SyncTableSpec(
      table: 'product_aliases',
      areaOf: _areaCatalog,
      naturalKey: ['normalized_alias', 'product_id'],
    ),
    'stores': const SyncTableSpec(
      table: 'stores',
      areaOf: _areaCatalog,
      naturalKey: ['cnpj'],
    ),
    'categories': const SyncTableSpec(
      table: 'categories',
      areaOf: _areaCatalog,
      naturalKey: ['name', 'kind'],
    ),

    // -------------------------------------------------------------------------
    // Home area (RN-310)
    // -------------------------------------------------------------------------
    'shopping_lists': const SyncTableSpec(
      table: 'shopping_lists',
      areaOf: _areaHome,
    ),
    'shopping_items': const SyncTableSpec(
      table: 'shopping_items',
      areaOf: _areaHome,
    ),
    'tasks': const SyncTableSpec(
      table: 'tasks',
      areaOf: _areaHome,
      excludedColumns: {'remote_event_id', 'remote_etag', 'sync_state'},
    ),
    'recipes': const SyncTableSpec(
      table: 'recipes',
      areaOf: _areaHome,
      naturalKey: ['title'],
    ),
    'recipe_ingredients': const SyncTableSpec(
      table: 'recipe_ingredients',
      areaOf: _areaHome,
    ),
    'recipe_tags': const SyncTableSpec(
      table: 'recipe_tags',
      areaOf: _areaHome,
      naturalKey: ['recipe_id', 'tag'],
    ),
    'stock_items': const SyncTableSpec(
      table: 'stock_items',
      areaOf: _areaHome,
      naturalKey: ['product_id'],
    ),
    'checklist_items': const SyncTableSpec(
      table: 'checklist_items',
      areaOf: _areaHome,
    ),

    // -------------------------------------------------------------------------
    // Finance area (RN-310)
    // -------------------------------------------------------------------------
    'purchases': const SyncTableSpec(
      table: 'purchases',
      areaOf: _areaFinance,
      excludedColumns: {'receipt_image_path', 'receipt_key'},
    ),
    'purchase_items': const SyncTableSpec(
      table: 'purchase_items',
      areaOf: _areaFinance,
    ),
    'expenses': const SyncTableSpec(table: 'expenses', areaOf: _areaFinance),
    'budgets': const SyncTableSpec(
      table: 'budgets',
      areaOf: _areaFinance,
      naturalKey: ['year_month', 'category_id'],
    ),
    'bills': const SyncTableSpec(
      table: 'bills',
      areaOf: _areaFinance,
      naturalKey: ['title', 'due_day'],
    ),
    'bill_payments': const SyncTableSpec(
      table: 'bill_payments',
      areaOf: _areaFinance,
      naturalKey: ['bill_id', 'due_on'],
    ),

    // -------------------------------------------------------------------------
    // Dynamic area by type (RN-310, plan.md line 80)
    // -------------------------------------------------------------------------
    'recurring_rules': const SyncTableSpec(
      table: 'recurring_rules',
      areaOf: _areaRecurringRules,
    ),

    // -------------------------------------------------------------------------
    // Derived table (RN-327: never transmitted)
    // -------------------------------------------------------------------------
    'price_points': const SyncTableSpec(
      table: 'price_points',
      areaOf: _areaFinance,
      derived: true,
    ),
  };

  static SyncArea _areaCatalog(Map<String, Object?> _) => SyncArea.catalog;
  static SyncArea _areaHome(Map<String, Object?> _) => SyncArea.home;
  static SyncArea _areaFinance(Map<String, Object?> _) => SyncArea.finance;
  static SyncArea _areaRecurringRules(Map<String, Object?> row) {
    final kind = row['kind'];
    if (kind == 'task') {
      return SyncArea.home;
    }
    if (kind == 'expense' || kind == 'bill') {
      return SyncArea.finance;
    }
    throw ArgumentError.value(
      kind,
      'row["kind"]',
      'Unknown or invalid recurring rule kind for sync',
    );
  }
}
