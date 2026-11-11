library;

/// Generates and manages SQLite triggers for sync change capture.
///
/// Each trigger has an activation gate:
/// `(SELECT COUNT(*) FROM sync_household WHERE active = 1) > 0`
/// `AND (SELECT value FROM settings WHERE key = 'sync_applying_remote') IS NOT '1'`
///
/// This ensures:
/// 1. In installations without an active household, triggers remain DISABLED by default (zero overhead);
/// 2. When applying remote changes, no echo (infinite loop) is generated.
abstract final class SyncTriggers {
  /// Mapping of syncable tables and their monitored columns.
  static const Map<String, List<String>> syncedTablesAndColumns = {
    'products': [
      'canonical_name',
      'category_id',
      'default_unit',
      'package_size_milli',
      'is_archived',
    ],
    'product_aliases': ['product_id', 'alias', 'normalized_alias', 'source'],
    'stores': ['name', 'cnpj', 'address', 'latitude', 'longitude'],
    'purchases': [
      'store_id',
      'purchased_at',
      'total_cents',
      'discount_cents',
      'payment_method',
      'source',
      'expense_id',
      'deleted_at',
    ],
    'purchase_items': [
      'purchase_id',
      'product_id',
      'raw_description',
      'quantity_milli',
      'unit',
      'unit_price_cents',
      'total_price_cents',
      'ean',
      'position',
    ],
    'categories': [
      'name',
      'kind',
      'icon_key',
      'color_hex',
      'is_system',
      'sort_order',
    ],
    'expenses': [
      'category_id',
      'amount_cents',
      'occurred_on',
      'description',
      'notes',
      'recurring_rule_id',
      'bill_id',
      'purchase_id',
      'deleted_at',
    ],
    'budgets': [
      'year_month',
      'category_id',
      'limit_cents',
      'base_income_cents',
      'extra_income_cents',
    ],
    'recurring_rules': [
      'kind',
      'rrule',
      'starts_on',
      'ends_on',
      'amount_cents',
      'category_id',
      'title',
      'last_materialized_on',
    ],
    'bills': [
      'title',
      'amount_cents',
      'is_amount_variable',
      'due_day',
      'category_id',
      'payment_method',
      'reminder_days_before',
      'is_active',
    ],
    'bill_payments': [
      'bill_id',
      'due_on',
      'paid_on',
      'amount_cents',
      'status',
      'expense_id',
    ],
    'shopping_lists': ['name', 'store_id', 'is_archived'],
    'shopping_items': [
      'list_id',
      'product_id',
      'free_text',
      'quantity_milli',
      'unit',
      'estimated_price_cents',
      'is_checked',
      'checked_at',
      'position',
      'source',
    ],
    'tasks': [
      'title',
      'notes',
      'category_id',
      'due_at',
      'all_day',
      'is_completed',
      'completed_at',
      'recurring_rule_id',
      'deleted_at',
    ],
    'recipes': [
      'title',
      'instructions',
      'prep_minutes',
      'servings',
      'photo_path',
      'is_favorite',
    ],
    'recipe_ingredients': [
      'recipe_id',
      'product_id',
      'raw_text',
      'quantity_milli',
      'unit',
      'position',
    ],
    'recipe_tags': ['recipe_id', 'tag'],
    'stock_items': [
      'product_id',
      'quantity_milli',
      'unit',
      'low_stock_threshold_milli',
      'last_restocked_at',
    ],
    'checklist_items': ['room_category', 'title', 'is_marked', 'position'],
  };

  /// List of all SQL DDL statements to create sync triggers.
  static List<String> get createStatements {
    final statements = <String>[];

    // Auxiliary indexes for fast queries on sync_column_versions
    statements.add(
      'CREATE INDEX IF NOT EXISTS idx_sync_col_ver_table_row ON sync_column_versions(table_name, row_id);',
    );
    statements.add(
      'CREATE INDEX IF NOT EXISTS idx_sync_col_ver_site_hlc ON sync_column_versions(site_id, hlc);',
    );
    statements.add(
      'CREATE INDEX IF NOT EXISTS idx_sync_tomb_table_row ON sync_row_tombstones(table_name, row_id);',
    );

    for (final entry in syncedTablesAndColumns.entries) {
      final table = entry.key;
      final columns = entry.value;
      final rowIdExprNew = (table == 'recipe_tags')
          ? "NEW.recipe_id || ':' || NEW.tag"
          : 'NEW.id';
      final rowIdExprOld = (table == 'recipe_tags')
          ? "OLD.recipe_id || ':' || OLD.tag"
          : 'OLD.id';

      // 1. Trigger AFTER INSERT
      final insertLines = columns
          .map((col) {
            return '''
  INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at)
  VALUES (
    '$table',
    $rowIdExprNew,
    '$col',
    COALESCE(
      (SELECT value FROM settings WHERE key = 'sync_current_hlc'),
      strftime('%Y-%m-%dT%H:%M:%fZ', 'now') || ':00000:' || (SELECT local_site_id FROM sync_household WHERE active = 1 LIMIT 1)
    ),
    (SELECT local_site_id FROM sync_household WHERE active = 1 LIMIT 1),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  );''';
          })
          .join('\n');

      final insertTrigger =
          '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_insert
AFTER INSERT ON $table
WHEN (SELECT COUNT(*) FROM sync_household WHERE active = 1) > 0
  AND (SELECT value FROM settings WHERE key = 'sync_applying_remote') IS NOT '1'
BEGIN
$insertLines
END;''';
      statements.add(insertTrigger);

      // 2. Trigger AFTER UPDATE
      final updateLines = columns
          .map((col) {
            return '''
  INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at)
  SELECT
    '$table',
    $rowIdExprNew,
    '$col',
    COALESCE(
      (SELECT value FROM settings WHERE key = 'sync_current_hlc'),
      strftime('%Y-%m-%dT%H:%M:%fZ', 'now') || ':00000:' || (SELECT local_site_id FROM sync_household WHERE active = 1 LIMIT 1)
    ),
    (SELECT local_site_id FROM sync_household WHERE active = 1 LIMIT 1),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE NEW.$col IS NOT OLD.$col;''';
          })
          .join('\n');

      final updateTrigger =
          '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_update
AFTER UPDATE ON $table
WHEN (SELECT COUNT(*) FROM sync_household WHERE active = 1) > 0
  AND (SELECT value FROM settings WHERE key = 'sync_applying_remote') IS NOT '1'
BEGIN
$updateLines
END;''';
      statements.add(updateTrigger);

      // 3. Trigger AFTER DELETE (registra em sync_row_tombstones)
      final deleteTrigger =
          '''
CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_delete
AFTER DELETE ON $table
WHEN (SELECT COUNT(*) FROM sync_household WHERE active = 1) > 0
  AND (SELECT value FROM settings WHERE key = 'sync_applying_remote') IS NOT '1'
BEGIN
  INSERT OR REPLACE INTO sync_row_tombstones (id, table_name, row_id, hlc, purged_at)
  VALUES (
    lower(hex(randomblob(16))),
    '$table',
    $rowIdExprOld,
    COALESCE(
      (SELECT value FROM settings WHERE key = 'sync_current_hlc'),
      strftime('%Y-%m-%dT%H:%M:%fZ', 'now') || ':00000:' || (SELECT local_site_id FROM sync_household WHERE active = 1 LIMIT 1)
    ),
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  );
END;''';
      statements.add(deleteTrigger);
    }

    return statements;
  }
}
