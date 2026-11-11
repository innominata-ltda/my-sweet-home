import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/sync_applied_event.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';

import '../../fakes/fake_clock.dart';

void main() {
  const householdId = 'hh-9999-5555';
  const localSiteId = 'site-local-1111';
  const remoteSiteId = 'site-remote-2222';

  late AppDatabase db;
  late FakeClock clock;
  late ChangeCapture changeCapture;
  late DriftBatchApplier applier;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 10, 22, 12, 0, 0));
    db = AppDatabase.memory();
    changeCapture = ChangeCapture(db: db, clock: clock);

    await changeCapture.activateHousehold(
      householdId: householdId,
      name: 'Casa Teste',
      localSiteId: localSiteId,
    );

    applier = DriftBatchApplier(
      db: db,
      registry: SyncTableRegistryImpl(),
      changeCapture: changeCapture,
      clock: clock,
    );

    // Cria categoria base para satisfazer FKs
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-alimentacao',
            name: 'Alimentação',
            kind: 'both',
            iconKey: 'cart',
            colorHex: const Value('0xFF0000'),
          ),
        );
  });

  tearDown(() async {
    applier.dispose();
    await db.close();
  });

  group('CA-5.7 / RN-328 — Atomicidade de lote e rollback em falha', () {
    test('Dado lote interrompido / corrompido, nada e aplicado e o banco fica intacto; proximo lote completa normalmente', () async {
      // Estado inicial do banco: 1 produto
      const initialProdId = 'prod-inicial';
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: initialProdId,
              canonicalName: 'Café Torrado',
              categoryId: const Value('cat-alimentacao'),
              defaultUnit: 'un',
            ),
          );

      final initialCvCount = await changeCapture.countCapturedVersions();

      // 1. Attempts to apply batch with one valid change and another for invalid table
      final hlc1 = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final corruptedBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc1}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-novo-1',
            column: 'canonical_name',
            value: 'Açúcar Cristal',
            hlc: hlc1,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-novo-1',
            column: 'category_id',
            value: 'cat-alimentacao',
            hlc: hlc1,
          ),
          // Invalid change: unknown / non-existent table
          ColumnVersion(
            table: 'tabela_maliciosa_ou_invalida',
            rowId: 'row-x',
            column: 'nome',
            value: 'Hack',
            hlc: hlc1,
          ),
        ],
      );

      final result1 = await applier.apply(corruptedBatch);
      expect(result1.isErr, isTrue);

      // Verifies NOTHING from batch 1 was written: prod-novo-1 DOES NOT exist!
      final prod1 = await (db.select(
        db.products,
      )..where((p) => p.id.equals('prod-novo-1'))).get();
      expect(prod1, isEmpty);

      // No additional column version written
      final cvCountAfterFailed = await changeCapture.countCapturedVersions();
      expect(cvCountAfterFailed, equals(initialCvCount));

      // Peer vector was NOT updated
      final peerVectors = await db
          .customSelect('SELECT * FROM sync_peer_vectors')
          .get();
      expect(peerVectors, isEmpty);

      // 2. Now sends next batch complete and intact
      clock.advance(const Duration(minutes: 5));
      final hlc2 = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 2,
        siteId: remoteSiteId,
      );

      final validBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc2}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-novo-1',
            column: 'canonical_name',
            value: 'Açúcar Cristal 1kg',
            hlc: hlc2,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-novo-1',
            column: 'category_id',
            value: 'cat-alimentacao',
            hlc: hlc2,
          ),
        ],
      );

      final result2 = await applier.apply(validBatch);
      expect(result2.isOk, isTrue);
      expect(result2.valueOrNull!.appliedChangesCount, equals(2));

      // New product now exists with correct data
      final prodNovo = await (db.select(
        db.products,
      )..where((p) => p.id.equals('prod-novo-1'))).getSingle();
      expect(prodNovo.canonicalName, equals('Açúcar Cristal 1kg'));
      expect(prodNovo.categoryId, equals('cat-alimentacao'));

      // Vetor de peer agora gravado
      final peerRows = await db
          .customSelect(
            'SELECT site_id, hlc FROM sync_peer_vectors WHERE site_id = ?',
            variables: [Variable.withString(remoteSiteId)],
          )
          .get();
      expect(peerRows.length, equals(1));
      expect(peerRows.first.data['hlc'], equals(hlc2.pack()));
    });

    test(
      'rejects unknown column with error and rolls back completely',
      () async {
        final hlc = Hlc(
          millis: clock.nowUtc().millisecondsSinceEpoch,
          counter: 1,
          siteId: remoteSiteId,
        );

        final batch = SyncBatch(
          householdId: householdId,
          fromSiteId: remoteSiteId,
          senderVector: VersionVector({remoteSiteId: hlc}),
          changes: [
            ColumnVersion(
              table: 'products',
              rowId: 'prod-fail',
              column: 'coluna_inexistente',
              value: 'valor',
              hlc: hlc,
            ),
          ],
        );

        final res = await applier.apply(batch);
        expect(res.isErr, isTrue);

        final prods = await (db.select(
          db.products,
        )..where((p) => p.id.equals('prod-fail'))).get();
        expect(prods, isEmpty);
      },
    );

    test('rejects incompatible protocol version (CA-5.8, RN-329)', () async {
      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final batchV2 = SyncBatch(
        protocolVersion: 2, // incompatible
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-v2',
            column: 'canonical_name',
            value: 'Feijão',
            hlc: hlc,
          ),
        ],
      );

      final res = await applier.apply(batchV2);
      expect(res.isErr, isTrue);
      expect(
        res.failureOrNull.toString().toLowerCase(),
        contains('update the app to synchronize with the household'),
      );

      final prods = await (db.select(
        db.products,
      )..where((p) => p.id.equals('prod-v2'))).get();
      expect(prods, isEmpty);
    });
  });

  group('Remote Echo — Trigger suppression during apply', () {
    test('ao aplicar mudanca remota, triggers locais NAO disparam versoes locais (zero eco)', () async {
      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-sem-eco',
            column: 'canonical_name',
            value: 'Sabão em Pó',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-sem-eco',
            column: 'category_id',
            value: 'cat-alimentacao',
            hlc: hlc,
          ),
        ],
      );

      final res = await applier.apply(batch);
      expect(res.isOk, isTrue);

      // Versions written in sync_column_versions must have site_id = remoteSiteId
      // and NOT site_id = localSiteId (which would happen if trigger fired)
      final versions = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-sem-eco',
      );

      expect(versions.length, equals(2));
      for (final v in versions) {
        expect(v.siteId, equals(remoteSiteId));
        expect(v.hlc, equals(hlc));
      }

      // Verify guard was restored to 0
      expect(await changeCapture.isApplyingRemote(), isFalse);
    });
  });

  group('LWW por coluna (RN-320, RN-321)', () {
    test('edicoes concorrentes em campos diferentes sao ambas preservadas (RN-321)', () async {
      const taskId = 'task-lww-1';

      // 1. Cria tarefa inicial
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Lavar Louça',
              notes: const Value('Esponja amarela'),
              categoryId: const Value('cat-alimentacao'),
            ),
          );

      final hlcBase = Hlc(
        millis: DateTime.utc(2026, 10, 22, 10, 0, 0).millisecondsSinceEpoch,
        counter: 0,
        siteId: localSiteId,
      );

      // Records initial versions
      await captureInitialVersion(
        db,
        'tasks',
        taskId,
        'title',
        hlcBase,
        localSiteId,
      );
      await captureInitialVersion(
        db,
        'tasks',
        taskId,
        'notes',
        hlcBase,
        localSiteId,
      );

      // 2. Local edits 'title' at 10:10
      final hlcLocal = Hlc(
        millis: DateTime.utc(2026, 10, 22, 10, 10, 0).millisecondsSinceEpoch,
        counter: 1,
        siteId: localSiteId,
      );
      await captureInitialVersion(
        db,
        'tasks',
        taskId,
        'title',
        hlcLocal,
        localSiteId,
      );
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(title: Value('Lavar Louça e Panelas')),
      );

      // 3. Remote edited 'notes' at 10:15
      final hlcRemote = Hlc(
        millis: DateTime.utc(2026, 10, 22, 10, 15, 0).millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final remoteBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlcRemote}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'notes',
            value: 'Usar detergente neutro',
            hlc: hlcRemote,
          ),
        ],
      );

      final applyRes = await applier.apply(remoteBatch);
      expect(applyRes.isOk, isTrue);

      // Ambos os campos foram preservados!
      final taskFinal = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();

      expect(taskFinal.title, equals('Lavar Louça e Panelas'));
      expect(taskFinal.notes, equals('Usar detergente neutro'));
    });

    test(
      'edicoes no mesmo campo: maior HLC vence, menor e descartado (RN-320)',
      () async {
        const taskId = 'task-lww-conflito';

        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: taskId,
                title: 'Título Antigo',
                categoryId: const Value('cat-alimentacao'),
              ),
            );

        // Local has version at 12:00
        final hlcLocalRecente = Hlc(
          millis: DateTime.utc(2026, 10, 22, 12, 0, 0).millisecondsSinceEpoch,
          counter: 1,
          siteId: localSiteId,
        );
        await captureInitialVersion(
          db,
          'tasks',
          taskId,
          'title',
          hlcLocalRecente,
          localSiteId,
        );
        await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
          const TasksCompanion(title: Value('Título Local Vencedor')),
        );

        // Remote sends earlier version at 11:30
        final hlcRemotoAntigo = Hlc(
          millis: DateTime.utc(2026, 10, 22, 11, 30, 0).millisecondsSinceEpoch,
          counter: 1,
          siteId: remoteSiteId,
        );

        final batch = SyncBatch(
          householdId: householdId,
          fromSiteId: remoteSiteId,
          senderVector: VersionVector({remoteSiteId: hlcRemotoAntigo}),
          changes: [
            ColumnVersion(
              table: 'tasks',
              rowId: taskId,
              column: 'title',
              value: 'Título Remoto Perdedor',
              hlc: hlcRemotoAntigo,
            ),
          ],
        );

        final res = await applier.apply(batch);
        expect(res.isOk, isTrue);
        expect(res.valueOrNull!.appliedChangesCount, equals(0));

        // Local title prevailed
        final task = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.title, equals('Título Local Vencedor'));
      },
    );

    test('column excluded by registry is not applied', () async {
      const taskId = 'task-excl';

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Tarefa',
              categoryId: const Value('cat-alimentacao'),
            ),
          );

      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      // 'remote_event_id' is excluded column in tasks (RN-312)
      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'remote_event_id',
            value: 'calendar-event-999',
            hlc: hlc,
          ),
        ],
      );

      final res = await applier.apply(batch);
      expect(res.isOk, isTrue);
      expect(res.valueOrNull!.appliedChangesCount, equals(0));

      final task = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.remoteEventId, isNull);
    });
  });

  group('Tabela de chave composta (recipe_tags)', () {
    test('aplica insert e delete em recipe_tags corretamente', () async {
      // 1. Cria receita base
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(
              id: 'recipe-1',
              title: 'Bolo de Cenoura',
              instructions: const Value('Bata tudo no liquidificador'),
            ),
          );

      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      // 2. Insere tag remota
      final batchInsert = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'recipe_tags',
            rowId: 'recipe-1:sobremesa',
            column: 'recipe_id',
            value: 'recipe-1',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'recipe_tags',
            rowId: 'recipe-1:sobremesa',
            column: 'tag',
            value: 'sobremesa',
            hlc: hlc,
          ),
        ],
      );

      final resInsert = await applier.apply(batchInsert);
      expect(resInsert.isOk, isTrue);

      final tags = await (db.select(
        db.recipeTags,
      )..where((t) => t.recipeId.equals('recipe-1'))).get();
      expect(tags.length, equals(1));
      expect(tags.first.tag, equals('sobremesa'));

      // 3. Purga a tag com tombstone
      clock.advance(const Duration(minutes: 5));
      final hlcPurge = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 2,
        siteId: remoteSiteId,
      );

      final batchPurge = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlcPurge}),
        purged: [
          RowTombstone(
            id: 'tomb-tag-1',
            table: 'recipe_tags',
            rowId: 'recipe-1:sobremesa',
            hlc: hlcPurge,
            purgedAt: '2026-10-22T12:05:00.000Z',
          ),
        ],
      );

      final resPurge = await applier.apply(batchPurge);
      expect(resPurge.isOk, isTrue);

      final tagsAfter = await (db.select(
        db.recipeTags,
      )..where((t) => t.recipeId.equals('recipe-1'))).get();
      expect(tagsAfter, isEmpty);
    });
  });

  group('Dependency Order and Foreign Keys', () {
    test('insere pai e filho no mesmo lote respeitando foreign keys (PRAGMA defer_foreign_keys)', () async {
      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      // Lista e item de compras chegam juntos no mesmo lote
      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          // Item de compras (filho)
          ColumnVersion(
            table: 'shopping_items',
            rowId: 'item-10',
            column: 'list_id',
            value: 'list-10',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'shopping_items',
            rowId: 'item-10',
            column: 'free_text',
            value: 'Maçãs',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'shopping_items',
            rowId: 'item-10',
            column: 'position',
            value: 0,
            hlc: hlc,
          ),
          // Lista de compras (pai)
          ColumnVersion(
            table: 'shopping_lists',
            rowId: 'list-10',
            column: 'name',
            value: 'Feira Semanal',
            hlc: hlc,
          ),
        ],
      );

      final res = await applier.apply(batch);
      expect(res.isOk, isTrue);

      final list = await (db.select(
        db.shoppingLists,
      )..where((l) => l.id.equals('list-10'))).getSingle();
      expect(list.name, equals('Feira Semanal'));

      final item = await (db.select(
        db.shoppingItems,
      )..where((i) => i.id.equals('item-10'))).getSingle();
      expect(item.freeText, equals('Maçãs'));
    });
  });

  group('Idempotence and Events', () {
    test('aplicar o mesmo lote duas vezes produz o mesmo resultado', () async {
      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-idem',
            column: 'canonical_name',
            value: 'Arroz Branco 1kg',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-idem',
            column: 'category_id',
            value: 'cat-alimentacao',
            hlc: hlc,
          ),
        ],
      );

      final res1 = await applier.apply(batch);
      expect(res1.isOk, isTrue);
      expect(res1.valueOrNull!.appliedChangesCount, equals(2));

      // 2nd application of same batch
      final res2 = await applier.apply(batch);
      expect(res2.isOk, isTrue);
      // No additional change needs to win, state remains intact
      expect(res2.valueOrNull!.appliedChangesCount, equals(0));

      final prod = await (db.select(
        db.products,
      )..where((p) => p.id.equals('prod-idem'))).getSingle();
      expect(prod.canonicalName, equals('Arroz Branco 1kg'));
    });

    test('emits SyncAppliedEvent when changes are applied', () async {
      final events = <SyncAppliedEvent>[];
      final subscription = applier.onBatchApplied.listen(events.add);

      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-event',
            column: 'canonical_name',
            value: 'Farinha de Trigo',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-event',
            column: 'category_id',
            value: 'cat-alimentacao',
            hlc: hlc,
          ),
        ],
      );

      await applier.apply(batch);
      await pumpEventQueue();

      expect(events.length, equals(1));
      expect(events.first.householdId, equals(householdId));
      expect(events.first.fromSiteId, equals(remoteSiteId));
      expect(events.first.touchedTables, contains('products'));
      expect(events.first.touchedRowIds, contains('prod-event'));
      expect(events.first.changesAppliedCount, equals(2));

      await subscription.cancel();
    });

    test('onBatchApplied NAO emite nenhum evento se a transacao falhar ou for revertida', () async {
      final events = <SyncAppliedEvent>[];
      final subscription = applier.onBatchApplied.listen(events.add);

      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: remoteSiteId,
      );

      // Batch with corrupted table that fails validation/application
      final corruptedBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-failed',
            column: 'canonical_name',
            value: 'Produto com falha',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'tabela_inexistente',
            rowId: 'row-failed',
            column: 'col',
            value: 'val',
            hlc: hlc,
          ),
        ],
      );

      final res = await applier.apply(corruptedBatch);
      expect(res.isErr, isTrue);

      await pumpEventQueue();
      expect(events, isEmpty);

      await subscription.cancel();
    });

    test('SyncBatch toJson e fromJson round-trip', () {
      final hlc = Hlc(millis: 1700000000000, counter: 5, siteId: 'node-1');
      final original = SyncBatch(
        protocolVersion: 1,
        householdId: 'hh-1',
        fromSiteId: 'node-1',
        senderVector: VersionVector({'node-1': hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-1',
            column: 'canonical_name',
            value: 'Leite',
            hlc: hlc,
          ),
        ],
        purged: [
          RowTombstone(
            id: 't-1',
            table: 'tasks',
            rowId: 'task-1',
            hlc: hlc,
            purgedAt: '2026-10-22T12:00:00.000Z',
          ),
        ],
      );

      final json = original.toJson();
      final reconstructed = SyncBatch.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.protocolVersion, equals(1));
      expect(reconstructed.changes.length, equals(1));
      expect(reconstructed.purged.length, equals(1));
    });

    test('ApplyReport igualdade, hashCode, toString e defaults de insercao/tombstone por tabela', () async {
      const r1 = ApplyReport(
        appliedChangesCount: 2,
        appliedTombstonesCount: 1,
        touchedTables: {'products'},
        touchedRowIds: {'p1'},
      );
      const r2 = ApplyReport(
        appliedChangesCount: 2,
        appliedTombstonesCount: 1,
        touchedTables: {'products'},
        touchedRowIds: {'p1'},
      );
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1.toString(), contains('ApplyReport(changes: 2'));

      final hlc = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch,
        counter: 10,
        siteId: remoteSiteId,
      );

      // Aplica insercoes parciais exercitando _applyInsertDefaults nas tabelas compartilhadas
      final insertBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlc}),
        changes: [
          ColumnVersion(
            table: 'categories',
            rowId: 'cat-x',
            column: 'name',
            value: 'Cat X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'stores',
            rowId: 'st-x',
            column: 'name',
            value: 'Loja X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'pr-x',
            column: 'canonical_name',
            value: 'Prod X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'product_aliases',
            rowId: 'pa-x',
            column: 'product_id',
            value: 'pr-x',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'checklist_items',
            rowId: 'ck-x',
            column: 'title',
            value: 'Item X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'expenses',
            rowId: 'ex-x',
            column: 'amount_cents',
            value: 1000,
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'budgets',
            rowId: 'bg-x',
            column: 'limit_cents',
            value: 5000,
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'recipes',
            rowId: 'rc-x',
            column: 'title',
            value: 'Receita X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'recipe_ingredients',
            rowId: 'ri-x',
            column: 'recipe_id',
            value: 'rc-x',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'recurring_rules',
            rowId: 'rr-x',
            column: 'title',
            value: 'Regra X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'bills',
            rowId: 'bl-x',
            column: 'title',
            value: 'Conta X',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'bill_payments',
            rowId: 'bp-x',
            column: 'bill_id',
            value: 'bl-x',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'stock_items',
            rowId: 'sk-x',
            column: 'product_id',
            value: 'pr-x',
            hlc: hlc,
          ),
        ],
      );

      final insertRes = await applier.apply(insertBatch);
      expect(insertRes.isOk, isTrue);

      // Aplica tombstones exercitando _nullifyReferencesBeforeDelete para cada tabela
      final hlcPurge = Hlc(
        millis: clock.nowUtc().millisecondsSinceEpoch + 1000,
        counter: 1,
        siteId: remoteSiteId,
      );
      const purgedAt = '2026-10-22T12:05:00.000Z';
      final purgeBatch = SyncBatch(
        householdId: householdId,
        fromSiteId: remoteSiteId,
        senderVector: VersionVector({remoteSiteId: hlcPurge}),
        changes: const [],
        purged: [
          RowTombstone(
            id: 'tb-bp',
            table: 'bill_payments',
            rowId: 'bp-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-bl',
            table: 'bills',
            rowId: 'bl-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-ex',
            table: 'expenses',
            rowId: 'ex-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-rr',
            table: 'recurring_rules',
            rowId: 'rr-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-ri',
            table: 'recipe_ingredients',
            rowId: 'ri-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-rc',
            table: 'recipes',
            rowId: 'rc-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-st',
            table: 'stores',
            rowId: 'st-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-cat',
            table: 'categories',
            rowId: 'cat-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-sk',
            table: 'stock_items',
            rowId: 'sk-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-pa',
            table: 'product_aliases',
            rowId: 'pa-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
          RowTombstone(
            id: 'tb-pr',
            table: 'products',
            rowId: 'pr-x',
            hlc: hlcPurge,
            purgedAt: purgedAt,
          ),
        ],
      );

      final purgeRes = await applier.apply(purgeBatch);
      expect(purgeRes.isOk, isTrue);
    });
  });
}

Future<void> captureInitialVersion(
  AppDatabase db,
  String table,
  String rowId,
  String column,
  Hlc hlc,
  String siteId,
) async {
  await db.customStatement(
    '''
    INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at)
    VALUES (?, ?, ?, ?, ?, ?);
    ''',
    [table, rowId, column, hlc.pack(), siteId, '2026-10-22T10:00:00.000Z'],
  );
}
