// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, avoid_print

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main() {
  final file = File('test/fixtures/db/v5.sqlite');
  if (file.existsSync()) {
    file.deleteSync();
  }
  file.parent.createSync(recursive: true);

  final db = sqlite3.open(file.path);

  // Schema v5 DDL
  db.execute('''
    PRAGMA foreign_keys = OFF;

    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      canonical_name TEXT NOT NULL,
      category_id TEXT,
      default_unit TEXT NOT NULL,
      package_size_milli INTEGER,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );

    CREATE TABLE product_aliases (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      alias TEXT NOT NULL,
      normalized_alias TEXT NOT NULL,
      source TEXT NOT NULL,
      created_at TEXT,
      UNIQUE(normalized_alias, product_id)
    );

    CREATE TABLE product_denials (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      raw_text TEXT NOT NULL,
      normalized_text TEXT NOT NULL,
      created_at TEXT,
      UNIQUE(normalized_text, product_id)
    );

    CREATE TABLE stores (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      cnpj TEXT,
      address TEXT,
      latitude REAL,
      longitude REAL,
      created_at TEXT,
      updated_at TEXT,
      UNIQUE(cnpj)
    );

    CREATE TABLE purchases (
      id TEXT PRIMARY KEY,
      store_id TEXT,
      purchased_at TEXT NOT NULL,
      total_cents INTEGER NOT NULL,
      discount_cents INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT,
      receipt_image_path TEXT,
      receipt_key TEXT,
      source TEXT NOT NULL,
      expense_id TEXT,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE purchase_items (
      id TEXT PRIMARY KEY,
      purchase_id TEXT NOT NULL,
      product_id TEXT,
      raw_description TEXT NOT NULL,
      quantity_milli INTEGER NOT NULL,
      unit TEXT NOT NULL,
      unit_price_cents INTEGER NOT NULL,
      total_price_cents INTEGER NOT NULL,
      ean TEXT,
      position INTEGER NOT NULL
    );

    CREATE TABLE price_points (
      id TEXT PRIMARY KEY,
      product_id TEXT,
      store_id TEXT,
      purchase_item_id TEXT,
      observed_at TEXT NOT NULL,
      unit_price_cents INTEGER NOT NULL,
      normalized_price_cents INTEGER NOT NULL,
      quantity_milli INTEGER NOT NULL,
      unit TEXT NOT NULL,
      source TEXT NOT NULL
    );

    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color_hex TEXT NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );

    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      amount_cents INTEGER NOT NULL,
      category_id TEXT,
      occurred_on TEXT NOT NULL,
      description TEXT,
      source TEXT NOT NULL,
      payment_method TEXT,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE budgets (
      id TEXT PRIMARY KEY,
      year_month TEXT NOT NULL,
      category_id TEXT,
      limit_cents INTEGER NOT NULL,
      base_income_cents INTEGER NOT NULL DEFAULT 0,
      extra_income_cents INTEGER NOT NULL DEFAULT 0,
      UNIQUE(year_month, category_id)
    );

    CREATE TABLE recurring_rules (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      amount_cents INTEGER,
      category_id TEXT,
      frequency TEXT NOT NULL,
      interval_value INTEGER NOT NULL DEFAULT 1,
      by_month_day INTEGER,
      start_date TEXT NOT NULL,
      end_date TEXT,
      kind TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      last_materialized_on TEXT,
      created_at TEXT,
      updated_at TEXT
    );

    CREATE TABLE bills (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount_cents INTEGER,
      is_amount_variable INTEGER NOT NULL,
      due_day INTEGER NOT NULL,
      category_id TEXT,
      payment_method TEXT,
      reminder_days_before INTEGER NOT NULL DEFAULT 3,
      is_active INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE bill_payments (
      id TEXT PRIMARY KEY,
      bill_id TEXT NOT NULL,
      due_on TEXT NOT NULL,
      amount_cents INTEGER NOT NULL,
      paid_at TEXT,
      status TEXT NOT NULL,
      expense_id TEXT,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE shopping_lists (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE shopping_items (
      id TEXT PRIMARY KEY,
      list_id TEXT,
      product_id TEXT,
      free_text TEXT,
      quantity_milli INTEGER,
      unit TEXT,
      estimated_price_cents INTEGER,
      is_checked INTEGER NOT NULL DEFAULT 0,
      checked_at TEXT,
      source TEXT NOT NULL,
      position INTEGER NOT NULL
    );

    CREATE TABLE tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      notes TEXT,
      category_id TEXT,
      due_at TEXT,
      all_day INTEGER NOT NULL DEFAULT 1,
      is_completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      recurring_rule_id TEXT,
      remote_event_id TEXT,
      remote_etag TEXT,
      sync_state TEXT,
      source_preset_id TEXT,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE recipes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      instructions TEXT,
      prep_minutes INTEGER,
      servings INTEGER NOT NULL DEFAULT 2,
      photo_path TEXT,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );

    CREATE TABLE recipe_ingredients (
      id TEXT PRIMARY KEY,
      recipe_id TEXT,
      product_id TEXT,
      raw_text TEXT NOT NULL,
      quantity_milli INTEGER,
      unit TEXT,
      position INTEGER NOT NULL
    );

    CREATE TABLE recipe_tags (
      recipe_id TEXT NOT NULL,
      tag TEXT NOT NULL,
      PRIMARY KEY(recipe_id, tag)
    );

    CREATE TABLE stock_items (
      id TEXT PRIMARY KEY,
      product_id TEXT,
      quantity_milli INTEGER NOT NULL DEFAULT 0,
      unit TEXT NOT NULL,
      min_quantity_milli INTEGER,
      location TEXT,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE checklist_items (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      is_checked INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT,
      test_column TEXT
    );

    CREATE TABLE consents (
      key TEXT PRIMARY KEY,
      granted INTEGER NOT NULL,
      granted_at TEXT,
      revoked_at TEXT
    );

    CREATE TABLE attachments (
      id TEXT PRIMARY KEY,
      path TEXT NOT NULL,
      kind TEXT,
      owner_type TEXT,
      owner_id TEXT,
      created_at TEXT
    );

    PRAGMA user_version = 5;
  ''');

  // Populating data
  const now = '2026-10-22T12:00:00.000Z';

  // 1. Category
  db.execute(
    "INSERT INTO categories VALUES ('cat-mercado', 'Mercado', 'shopping_cart', '#4CAF50', 0, '$now', '$now')",
  );

  // 2. Seed Product (v5 non-deterministic ID)
  const oldSeedProdId = 'legacy-seed-prod-001';
  const oldSeedAliasId = 'legacy-seed-alias-001';
  db.execute(
    "INSERT INTO products VALUES ('$oldSeedProdId', 'Arroz Branco Agulhinha', 'cat-mercado', 'kg', 1000, 0, '$now', '$now')",
  );
  db.execute(
    "INSERT INTO product_aliases VALUES ('$oldSeedAliasId', '$oldSeedProdId', 'Arroz Branco Agulhinha', 'arroz branco agulhinha', 'seed', '$now')",
  );

  // 3. Custom User Product
  const userProdId = 'custom-user-prod-001';
  const userAliasId = 'custom-user-alias-001';
  db.execute(
    "INSERT INTO products VALUES ('$userProdId', 'Caf\\u00e9 Especial do Sul', 'cat-mercado', 'un', 250, 0, '$now', '$now')",
  );
  db.execute(
    "INSERT INTO product_aliases VALUES ('$userAliasId', '$userProdId', 'Caf\\u00e9 Especial do Sul', 'cafe especial do sul', 'user', '$now')",
  );

  // 4. Store
  db.execute(
    "INSERT INTO stores VALUES ('store-1', 'Supermercado Central', '12345678000199', 'Rua das Flores, 123', -23.55, -46.63, '$now', '$now')",
  );

  // 5. Purchase and item referencing seed product
  db.execute(
    "INSERT INTO purchases VALUES ('purch-1', 'store-1', '$now', 2500, 0, 'pix', NULL, NULL, 'manual', NULL, '$now', '$now', NULL)",
  );
  db.execute(
    "INSERT INTO purchase_items VALUES ('pi-1', 'purch-1', '$oldSeedProdId', 'Arroz Agulhinha 1kg', 1000, 'kg', 2500, 2500, '7891234567890', 1)",
  );

  // 6. Observed price referencing seed product
  db.execute(
    "INSERT INTO price_points VALUES ('pp-1', '$oldSeedProdId', 'store-1', 'pi-1', '$now', 2500, 2500, 1000, 'kg', 'purchase')",
  );

  // 7. Expense and budget
  db.execute(
    "INSERT INTO expenses VALUES ('exp-1', 5000, 'cat-mercado', '2026-10-22', 'Compras do m\\u00eas', 'manual', 'pix', '$now', '$now', NULL)",
  );
  db.execute(
    "INSERT INTO budgets VALUES ('bgt-1', '2026-10', 'cat-mercado', 100000, 0, 0)",
  );

  // 8. Shopping list and item
  db.execute(
    "INSERT INTO shopping_lists VALUES ('list-1', 'Compras da Semana', 0, '$now', '$now', NULL)",
  );
  db.execute(
    "INSERT INTO shopping_items VALUES ('s-item-1', 'list-1', '$oldSeedProdId', NULL, 2000, 'kg', NULL, 0, NULL, 'manual', 1)",
  );

  // 9. Task with source_preset_id
  db.execute(
    "INSERT INTO tasks VALUES ('task-1', 'Lavar lou\\u00e7a', 'Nota v5', 'cat-mercado', '$now', 1, 0, NULL, NULL, NULL, NULL, NULL, 'sweep-floor', '$now', '$now', NULL)",
  );

  // 10. Recipe and ingredient
  db.execute(
    "INSERT INTO recipes VALUES ('rec-1', 'Arroz Soltinho', 'Receita b\\u00e1sica', 20, 4, NULL, 0, '$now', '$now')",
  );
  db.execute(
    "INSERT INTO recipe_ingredients VALUES ('rec-ing-1', 'rec-1', '$oldSeedProdId', 'Arroz Agulhinha', 500, 'g', 1)",
  );
  db.execute("INSERT INTO recipe_tags VALUES ('rec-1', 'basico')");

  // 11. Stock item
  db.execute(
    "INSERT INTO stock_items VALUES ('stock-1', '$oldSeedProdId', 3000, 'kg', 1000, 'Despensa', '$now', '$now', NULL)",
  );

  // 12. Checklist
  db.execute(
    "INSERT INTO checklist_items VALUES ('check-1', 'Conferir despensa', 1, 1, '$now', '$now', NULL)",
  );

  // 13. Contas fixas e pagamentos
  db.execute(
    "INSERT INTO bills VALUES ('bill-1', 'Internet Fibra', 12000, 0, 10, 'cat-mercado', 'pix', 3, 1)",
  );
  db.execute(
    "INSERT INTO bill_payments VALUES ('pay-1', 'bill-1', '2026-10-10', 12000, '$now', 'paid', NULL, '$now', '$now', NULL)",
  );

  // 14. Settings e Consents
  db.execute(
    "INSERT INTO settings VALUES ('theme_mode', 'system', '$now', 'migration_v5_test')",
  );
  db.execute("INSERT INTO consents VALUES ('analytics', 1, '$now', NULL)");

  db.dispose();
  print('v5.sqlite gerado com sucesso em ${file.path}');
}
