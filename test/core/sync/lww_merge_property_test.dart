import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/lww_merge.dart';

void main() {
  group('LwwMerge — Teste de Propriedade (CA-5.2, RN-323)', () {
    const merge = LwwMerge();

    test('500 permutations with duplication converge to exact same final state', () {
      // 1. Creates a universe of concurrent changes with overlaps
      final versions = <ColumnVersion>[
        // Produto 1: canonical_name editado por 3 aparelhos em tempos diferentes
        ColumnVersion(
          table: 'products',
          rowId: 'prod-1',
          column: 'canonical_name',
          value: 'Café Torrado A',
          hlc: Hlc(millis: 1000, counter: 0, siteId: 'dev-1'),
        ),
        ColumnVersion(
          table: 'products',
          rowId: 'prod-1',
          column: 'canonical_name',
          value: 'Café Torrado B',
          hlc: Hlc(millis: 1020, counter: 0, siteId: 'dev-2'),
        ),
        ColumnVersion(
          table: 'products',
          rowId: 'prod-1',
          column: 'canonical_name',
          value: 'Café Torrado Vencedor C', // Vencedor de canonical_name
          hlc: Hlc(millis: 1050, counter: 0, siteId: 'dev-3'),
        ),
        // Produto 1: default_unit editado concorrentemente
        ColumnVersion(
          table: 'products',
          rowId: 'prod-1',
          column: 'default_unit',
          value: 'un',
          hlc: Hlc(millis: 1000, counter: 1, siteId: 'dev-1'),
        ),
        ColumnVersion(
          table: 'products',
          rowId: 'prod-1',
          column: 'default_unit',
          value: 'kg', // Vencedor de default_unit
          hlc: Hlc(millis: 1010, counter: 0, siteId: 'dev-2'),
        ),
        // Item de lista: quantidade e comprado
        ColumnVersion(
          table: 'shopping_items',
          rowId: 'item-1',
          column: 'quantity_milli',
          value: 1000,
          hlc: Hlc(millis: 1000, counter: 0, siteId: 'dev-1'),
        ),
        ColumnVersion(
          table: 'shopping_items',
          rowId: 'item-1',
          column: 'quantity_milli',
          value: 2000, // Vencedor quantity_milli
          hlc: Hlc(millis: 1030, counter: 0, siteId: 'dev-2'),
        ),
        ColumnVersion(
          table: 'shopping_items',
          rowId: 'item-1',
          column: 'is_bought',
          value: 1, // Vencedor is_bought
          hlc: Hlc(millis: 1040, counter: 0, siteId: 'dev-3'),
        ),
        // Expense: amount, category, and concurrent deletion
        ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'amount_cents',
          value: 4500,
          hlc: Hlc(millis: 1000, counter: 0, siteId: 'dev-1'),
        ),
        ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'amount_cents',
          value: 4800, // Vencedor amount_cents
          hlc: Hlc(millis: 1025, counter: 0, siteId: 'dev-2'),
        ),
        ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'category_id',
          value: 'cat-alimentacao', // Vencedor category_id
          hlc: Hlc(millis: 1020, counter: 0, siteId: 'dev-1'),
        ),
        ColumnVersion(
          table: 'expenses',
          rowId: 'exp-1',
          column: 'deleted_at',
          value: '2026-10-22T10:30:00.000Z', // Vencedor deleted_at
          hlc: Hlc(millis: 1080, counter: 0, siteId: 'dev-1'),
        ),
        // Tarefa: empate estrito de millis e counter com desempate por siteId ('dev-b' > 'dev-a')
        ColumnVersion(
          table: 'tasks',
          rowId: 'task-1',
          column: 'title',
          value: 'Comprar pão dev-a',
          hlc: Hlc(millis: 1000, counter: 0, siteId: 'dev-a'),
        ),
        ColumnVersion(
          table: 'tasks',
          rowId: 'task-1',
          column: 'title',
          value: 'Comprar pão dev-b', // Vencedor task-1 title por siteId
          hlc: Hlc(millis: 1000, counter: 0, siteId: 'dev-b'),
        ),
      ];

      // 2. Calculates expected canonical state (ground truth)
      final expectedValues = <String, Object?>{};
      final expectedHlcs = <String, Hlc>{};

      for (final v in versions) {
        final currentHlc = expectedHlcs[v.key];
        if (currentHlc == null || v.hlc.compareTo(currentHlc) > 0) {
          expectedHlcs[v.key] = v.hlc;
          expectedValues[v.key] = v.value;
        }
      }

      // 3. Runs 500 random permutations with duplications and partitioning
      final rng = Random(42); // Fixed seed for deterministic reproducibility

      for (var iter = 0; iter < 500; iter++) {
        // Creates copy and adds random duplications (1 to 5 duplicate versions)
        final permutedList = List<ColumnVersion>.from(versions);
        final numDups = rng.nextInt(5) + 1;
        for (var d = 0; d < numDups; d++) {
          final chosen = versions[rng.nextInt(versions.length)];
          permutedList.add(chosen);
        }

        // Embaralha
        permutedList.shuffle(rng);

        // Divide aleatoriamente em 1 a 4 lotes (batches)
        final numBatches = rng.nextInt(4) + 1;
        final batches = <List<ColumnVersion>>[];
        final batchSize = (permutedList.length / numBatches).ceil();
        for (var b = 0; b < permutedList.length; b += batchSize) {
          final end = (b + batchSize < permutedList.length)
              ? b + batchSize
              : permutedList.length;
          batches.add(permutedList.sublist(b, end));
        }

        // Simulates node applying batch by batch
        final localByKey = <String, Hlc>{};
        final localValues = <String, Object?>{};

        for (final batch in batches) {
          final winners = merge.winners(batch, localByKey);
          for (final w in winners) {
            localByKey[w.key] = w.hlc;
            localValues[w.key] = w.value;
          }
        }

        // Verify final state converged 100% to ground truth
        expect(
          localValues.length,
          equals(expectedValues.length),
          reason: 'Iteration $iter failed on final keys count',
        );

        for (final entry in expectedValues.entries) {
          expect(
            localValues[entry.key],
            equals(entry.value),
            reason:
                'Iteration $iter failed for ${entry.key}: '
                'esperado "${entry.value}", obtido "${localValues[entry.key]}"',
          );
        }
      }
    });
  });
}
