library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import '../seed_loader.dart';
import '../sync/tables/sync_tables.dart';
import '../sync/tables/sync_triggers.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ProductAliases,
    ProductDenials,
    Stores,
    Purchases,
    PurchaseItems,
    PricePoints,
    Categories,
    Expenses,
    Budgets,
    RecurringRules,
    Bills,
    BillPayments,
    ShoppingLists,
    ShoppingItems,
    Tasks,
    Recipes,
    RecipeIngredients,
    RecipeTags,
    StockItems,
    ChecklistItems,
    Settings,
    Consents,
    Attachments,
    SyncHouseholds,
    SyncMembers,
    SyncColumnVersions,
    SyncRowTombstones,
    SyncPeerVectors,
    SyncMemberAcks,
    SyncAppliedBundles,
    SyncCompactionHorizon,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Creates database in the device file.
  // coverage:ignore-start
  factory AppDatabase.defaultConnection() {
    return AppDatabase(
      LazyDatabase(() async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'my_sweet_home.db'));
        return NativeDatabase.createInBackground(file);
      }),
    );
  }
  // coverage:ignore-end

  /// Creates in-memory database for testing.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 7;

  static const List<String> searchIndexTriggers = [
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_products_ai AFTER INSERT ON products
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      SELECT 'product', new.id, new.canonical_name, ''
      WHERE new.is_archived = 0;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_products_au AFTER UPDATE ON products
    BEGIN
      DELETE FROM search_index WHERE kind = 'product' AND target_id = old.id AND body = '';
      INSERT INTO search_index(kind, target_id, title, body)
      SELECT 'product', new.id, new.canonical_name, ''
      WHERE new.is_archived = 0;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_products_ad AFTER DELETE ON products
    BEGIN
      DELETE FROM search_index WHERE kind = 'product' AND target_id = old.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_aliases_ai AFTER INSERT ON product_aliases
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('product', new.product_id, new.alias, new.normalized_alias);
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_aliases_au AFTER UPDATE ON product_aliases
    BEGIN
      DELETE FROM search_index WHERE kind = 'product' AND target_id = old.product_id AND title = old.alias;
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('product', new.product_id, new.alias, new.normalized_alias);
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_aliases_ad AFTER DELETE ON product_aliases
    BEGIN
      DELETE FROM search_index WHERE kind = 'product' AND target_id = old.product_id AND title = old.alias;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_expenses_ai AFTER INSERT ON expenses
    WHEN new.deleted_at IS NULL
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('expense', new.id, COALESCE(new.description, ''), COALESCE(new.notes, ''));
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_expenses_au AFTER UPDATE ON expenses
    BEGIN
      DELETE FROM search_index WHERE kind = 'expense' AND target_id = old.id;
      INSERT INTO search_index(kind, target_id, title, body)
      SELECT 'expense', new.id, COALESCE(new.description, ''), COALESCE(new.notes, '')
      WHERE new.deleted_at IS NULL;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_expenses_ad AFTER DELETE ON expenses
    BEGIN
      DELETE FROM search_index WHERE kind = 'expense' AND target_id = old.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_tasks_ai AFTER INSERT ON tasks
    WHEN new.deleted_at IS NULL
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('task', new.id, new.title, COALESCE(new.notes, ''));
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_tasks_au AFTER UPDATE ON tasks
    BEGIN
      DELETE FROM search_index WHERE kind = 'task' AND target_id = old.id;
      INSERT INTO search_index(kind, target_id, title, body)
      SELECT 'task', new.id, new.title, COALESCE(new.notes, '')
      WHERE new.deleted_at IS NULL;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_tasks_ad AFTER DELETE ON tasks
    BEGIN
      DELETE FROM search_index WHERE kind = 'task' AND target_id = old.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_recipes_ai AFTER INSERT ON recipes
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('recipe', new.id, new.title, COALESCE(new.instructions, ''));
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_recipes_au AFTER UPDATE ON recipes
    BEGIN
      DELETE FROM search_index WHERE kind = 'recipe' AND target_id = old.id;
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('recipe', new.id, new.title, COALESCE(new.instructions, ''));
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_recipes_ad AFTER DELETE ON recipes
    BEGIN
      DELETE FROM search_index WHERE kind = 'recipe' AND target_id = old.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_shopping_lists_ai AFTER INSERT ON shopping_lists
    WHEN new.is_archived = 0
    BEGIN
      INSERT INTO search_index(kind, target_id, title, body)
      VALUES ('shoppingList', new.id, new.name, '');
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_shopping_lists_au AFTER UPDATE ON shopping_lists
    BEGIN
      DELETE FROM search_index WHERE kind = 'shoppingList' AND target_id = old.id;
      INSERT INTO search_index(kind, target_id, title, body)
      SELECT 'shoppingList', new.id, new.name, ''
      WHERE new.is_archived = 0;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_search_shopping_lists_ad AFTER DELETE ON shopping_lists
    BEGIN
      DELETE FROM search_index WHERE kind = 'shoppingList' AND target_id = old.id;
    END;
    ''',
  ];

  static const List<String> searchIndexPopulateStatements = [
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'product', id, canonical_name, '' FROM products WHERE is_archived = 0;",
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'product', product_id, alias, normalized_alias FROM product_aliases;",
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'expense', id, COALESCE(description, ''), COALESCE(notes, '') FROM expenses WHERE deleted_at IS NULL;",
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'task', id, title, COALESCE(notes, '') FROM tasks WHERE deleted_at IS NULL;",
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'recipe', id, title, COALESCE(instructions, '') FROM recipes;",
    "INSERT INTO search_index(kind, target_id, title, body) SELECT 'shoppingList', id, name, '' FROM shopping_lists WHERE is_archived = 0;",
  ];

  static const List<String> additionalIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);',
    'CREATE INDEX IF NOT EXISTS idx_bill_payments_bill ON bill_payments(bill_id);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id);',
    'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);',
    'CREATE INDEX IF NOT EXISTS idx_sync_tombstones_purged ON sync_row_tombstones(purged_at);',
    'CREATE INDEX IF NOT EXISTS idx_sync_col_ver_site_hlc ON sync_column_versions(site_id, hlc);',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // Indexes as per 006-data-model.md §5
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pp_product_date ON price_points(product_id, observed_at DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pp_product_store ON price_points(product_id, store_id, observed_at DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_alias_norm ON product_aliases(normalized_alias);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_exp_month ON expenses(occurred_on);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_due ON tasks(due_at);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_bill_payments_due_status ON bill_payments(due_on, status);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_shopping_items_pos ON shopping_items(list_id, position);',
      );

      // Additional v7 indexes
      for (final stmt in additionalIndexes) {
        await customStatement(stmt);
      }

      // P2P sync triggers and indexes (F013)
      for (final stmt in SyncTriggers.createStatements) {
        await customStatement(stmt);
      }

      // FTS5 search_index virtual table and triggers (v7)
      await customStatement(
        'CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5('
        'kind UNINDEXED, target_id UNINDEXED, title, body, '
        "tokenize='trigram remove_diacritics 1'"
        ');',
      );
      for (final stmt in searchIndexTriggers) {
        await customStatement(stmt);
      }
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(settings, settings.testColumn);
      }
      if (from < 3) {
        await m.createTable(productDenials);
      }
      if (from < 4) {
        await m.createTable(stockItems);
        await m.createTable(checklistItems);
      }
      if (from < 5) {
        await m.addColumn(tasks, tasks.sourcePresetId);
      }
      if (from < 6) {
        await SeedIdentityMigration(this).remap();
        await m.createTable(syncHouseholds);
        await m.createTable(syncMembers);
        await m.createTable(syncColumnVersions);
        await m.createTable(syncRowTombstones);
        await m.createTable(syncPeerVectors);
        for (final stmt in SyncTriggers.createStatements) {
          await customStatement(stmt);
        }
      }
      if (from < 7) {
        final expenseCols = (await customSelect(
          'PRAGMA table_info(expenses);',
        ).get()).map((r) => r.read<String>('name')).toSet();
        if (!expenseCols.contains('notes')) {
          await customStatement('ALTER TABLE expenses ADD COLUMN notes TEXT;');
        }

        await m.createTable(syncMemberAcks);
        await m.createTable(syncAppliedBundles);
        await m.createTable(syncCompactionHorizon);

        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5('
          'kind UNINDEXED, target_id UNINDEXED, title, body, '
          "tokenize='trigram remove_diacritics 1'"
          ');',
        );

        for (final stmt in searchIndexTriggers) {
          await customStatement(stmt);
        }

        for (final stmt in searchIndexPopulateStatements) {
          await customStatement(stmt);
        }

        for (final stmt in additionalIndexes) {
          await customStatement(stmt);
        }

        await customStatement(
          "UPDATE sync_members SET is_active = 0 WHERE site_id LIKE 'probed\\_%' ESCAPE '\\' OR site_id = 'cached_peer';",
        );
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys.
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
  );
}
