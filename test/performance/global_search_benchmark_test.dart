import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_global_search_repository.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';

void main() {
  group('Global Search Benchmark & Performance (CA-5.4, CA-5.8, RN-256, RN-427)', () {
    late AppDatabase db;
    late DriftGlobalSearchRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      repository = DriftGlobalSearchRepository(db);

      // Populates search_index with 10,000 records distributed across types
      // usando CTE recursivo de alto desempenho
      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 5000
        )
        INSERT INTO search_index(kind, target_id, title, body)
        SELECT 'product', 'prod_' || x, 
               CASE WHEN x = 2500 THEN 'Arroz Parboilizado Especial' ELSE 'Produto Diversos ' || x END, 
               CASE WHEN x = 2500 THEN 'arroz parboilizado pacote' ELSE 'categoria produto ' || x END
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 4000
        )
        INSERT INTO search_index(kind, target_id, title, body)
        SELECT 'expense', 'exp_' || x, 
               CASE WHEN x = 2000 THEN 'Supermercado Compra Arroz' ELSE 'Despesa Corrente ' || x END, 
               CASE WHEN x = 2000 THEN 'arroz e feijao' ELSE 'notas fiscais ' || x END
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 500
        )
        INSERT INTO search_index(kind, target_id, title, body)
        SELECT 'recipe', 'rec_' || x, 
               CASE WHEN x = 250 THEN 'Arroz de Forno Prático' ELSE 'Receita Deliciosa ' || x END, 
               'Cozinhe o alimento com temperos'
        FROM cnt;
      ''');

      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 500
        )
        INSERT INTO search_index(kind, target_id, title, body)
        SELECT 'task', 'task_' || x, 
               CASE WHEN x = 100 THEN 'Comprar Arroz no mercado' ELSE 'Tarefa Doméstica ' || x END, 
               'Lembrar de comprar marca boa'
        FROM cnt;
      ''');

      await db.customStatement('ANALYZE;');
    });

    tearDown(() async {
      await db.close();
    });

    test('CA-5.8: Search for "arroz" with 10,000 records responds in < 200 ms', () async {
      final stopwatch = Stopwatch()..start();
      final result = await repository.search('arroz');
      stopwatch.stop();

      expect(result.isOk, isTrue);
      final results = result.valueOrNull!;
      expect(results.items, isNotEmpty);

      final grouped = results.groupedByType;
      expect(grouped[GlobalSearchResultType.product], isNotEmpty);
      expect(grouped[GlobalSearchResultType.expense], isNotEmpty);
      expect(grouped[GlobalSearchResultType.recipe], isNotEmpty);
      expect(grouped[GlobalSearchResultType.task], isNotEmpty);

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason:
            'CA-5.8 / RN-256: A busca com 10.000 registros deve responder em < 200 ms (levou ${stopwatch.elapsedMilliseconds} ms)',
      );
    });

    test(
      'Search with 1-2 characters (LIKE) on search_index responds in < 200 ms',
      () async {
        final stopwatch = Stopwatch()..start();
        final result = await repository.search('ar');
        stopwatch.stop();

        expect(result.isOk, isTrue);
        expect(result.valueOrNull!.items, isNotEmpty);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'Short search with 1-2 chars should respond in < 200 ms',
        );
      },
    );

    test(
      'CA-5.4: FTS5 search query does not use SCAN on normal tables',
      () async {
        final planRows = await db
            .customSelect(
              'EXPLAIN QUERY PLAN SELECT kind, target_id, title, body FROM search_index WHERE search_index MATCH \'"arroz"\' LIMIT 100;',
            )
            .get();

        for (final row in planRows) {
          final detail = row.read<String>('detail');
          if (detail.startsWith('SCAN')) {
            expect(
              detail.contains('VIRTUAL TABLE INDEX'),
              isTrue,
              reason: 'CA-5.4: FTS5 deve usar VIRTUAL TABLE INDEX: $detail',
            );
          }
        }
      },
    );
  });
}
