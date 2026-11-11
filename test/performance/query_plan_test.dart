import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  group('Query Plan Performance (T-I02 / CA-5.4)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();

      // Populates main tables with 10,000 rows via fast recursive CTE
      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO categories(id, name, kind, icon_key, is_system)
        SELECT 'cat_' || x, 'Categoria ' || x, 'expense', 'shopping_cart', 0
        FROM cnt WHERE x <= 50;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO expenses(id, category_id, amount_cents, occurred_on, description)
        SELECT 'exp_' || x, 'cat_' || ((x % 50) + 1), 1000 + (x % 5000), '2026-10-' || printf('%02d', (x % 28) + 1), 'Despesa ' || x
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO bills(id, title, amount_cents, is_amount_variable, due_day)
        SELECT 'bill_' || x, 'Conta ' || x, 5000, 0, (x % 28) + 1
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO bill_payments(id, bill_id, due_on, status, amount_cents)
        SELECT 'bp_' || x, 'bill_' || x, '2026-10-' || printf('%02d', (x % 28) + 1), 'pending', 5000
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO tasks(id, title, due_at, all_day, is_completed)
        SELECT 'task_' || x, 'Tarefa ' || x, '2026-10-29T' || printf('%02d', (x % 24)) || ':00:00Z', 1, 0
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO shopping_lists(id, name, is_archived)
        SELECT 'list_' || x, 'Lista ' || x, 0
        FROM cnt WHERE x <= 50;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO shopping_items(id, list_id, position, source)
        SELECT 'sitem_' || x, 'list_' || ((x % 50) + 1), x, 'manual'
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO products(id, canonical_name, default_unit, is_archived)
        SELECT 'prod_' || x, 'Produto Arroz ' || x, 'kg', 0
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO price_points(id, product_id, observed_at, unit_price_cents, normalized_price_cents, quantity_milli, unit, source)
        SELECT 'pp_' || x, 'prod_' || ((x % 100) + 1), '2026-10-' || printf('%02d', (x % 28) + 1) || 'T12:00:00Z', 2500, 2500, 1000, 'kg', 'manual'
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO search_index(kind, target_id, title, body)
        SELECT 'product', 'prod_' || x, 'Arroz Integral ' || x, 'Cereal organico pacote'
        FROM cnt;
      ''');

      // Updates SQLite statistics for optimal query plan selection
      await db.customStatement('ANALYZE;');
    });

    tearDown(() async {
      await db.close();
    });

    void assertNoFullTableScan(
      List<QueryRow> planRows,
      String queryDescription,
    ) {
      for (final row in planRows) {
        final detail = row.read<String>('detail');
        if (detail.startsWith('SCAN')) {
          final isIndexed =
              detail.contains('USING INDEX') ||
              detail.contains('USING COVERING INDEX') ||
              detail.contains('VIRTUAL TABLE INDEX');
          expect(
            isIndexed,
            isTrue,
            reason:
                'CA-5.4: Consulta de "$queryDescription" usa SCAN completo sem índice: $detail',
          );
        }
      }
    }

    test('dashboard queries do not use full table SCAN (CA-5.4)', () async {
      // 1. Recent expenses by date (Dashboard)
      final expPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id, amount_cents FROM expenses WHERE occurred_on >= '2026-10-01' ORDER BY occurred_on DESC LIMIT 50;",
          )
          .get();
      assertNoFullTableScan(expPlan, 'Recent expenses on dashboard');

      // 2. Bills of the month (Dashboard)
      final billsPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id, amount_cents FROM bill_payments WHERE due_on = '2026-10-10' AND status = 'pending';",
          )
          .get();
      assertNoFullTableScan(billsPlan, 'Bills of the month on dashboard');

      // 3. Today tasks (Dashboard)
      final tasksPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id, title FROM tasks WHERE due_at >= '2026-10-29T00:00:00Z' ORDER BY due_at ASC LIMIT 50;",
          )
          .get();
      assertNoFullTableScan(tasksPlan, 'Today tasks on dashboard');
    });

    test('list queries do not use full table SCAN (CA-5.4)', () async {
      // 1. Shopping list items ordered by position
      final itemsPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id FROM shopping_items WHERE list_id = 'list_1' ORDER BY position;",
          )
          .get();
      assertNoFullTableScan(itemsPlan, 'Shopping list items');

      // 2. Expenses by category
      final expCatPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id FROM expenses WHERE category_id = 'cat_1';",
          )
          .get();
      assertNoFullTableScan(expCatPlan, 'Expenses by category');

      // 3. Payments of a bill
      final billPaymentsPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id FROM bill_payments WHERE bill_id = 'bill_1';",
          )
          .get();
      assertNoFullTableScan(billPaymentsPlan, 'Payments of a bill');

      // 4. Product price history
      final ppPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT id, unit_price_cents FROM price_points WHERE product_id = 'prod_1' ORDER BY observed_at DESC LIMIT 10;",
          )
          .get();
      assertNoFullTableScan(ppPlan, 'Product price history');
    });

    test('global search FTS5 ("arroz") uses virtual index without SCAN on normal table (CA-5.4)', () async {
      final searchPlan = await db
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT target_id, kind, title FROM search_index WHERE search_index MATCH 'arroz*' LIMIT 20;",
          )
          .get();
      assertNoFullTableScan(searchPlan, 'Busca FTS5 com termo arroz');
    });
  });
}
