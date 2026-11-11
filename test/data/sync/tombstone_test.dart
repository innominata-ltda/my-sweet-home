import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  const householdId = 'hh-1234-abcd';
  const siteA = 'site-aaaa-1111';
  const siteB = 'site-bbbb-2222';

  group('CA-5.3 - Delete wins over earlier edit and restore propagates', () {
    late AppDatabase dbA;
    late AppDatabase dbB;
    late FakeClock clockA;
    late FakeClock clockB;
    late ChangeCapture captureA;
    late ChangeCapture captureB;
    late DriftBatchApplier applierA;
    late DriftBatchApplier applierB;
    late DriftTrashPolicy trashPolicyA;
    late DriftTrashPolicy trashPolicyB;

    setUp(() async {
      clockA = FakeClock(DateTime.utc(2026, 10, 22, 10, 0, 0));
      clockB = FakeClock(DateTime.utc(2026, 10, 22, 10, 0, 0));

      dbA = AppDatabase.memory();
      dbB = AppDatabase.memory();

      captureA = ChangeCapture(db: dbA, clock: clockA);
      captureB = ChangeCapture(db: dbB, clock: clockB);

      await captureA.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: siteA,
      );
      await captureB.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: siteB,
      );

      applierA = DriftBatchApplier(
        db: dbA,
        registry: SyncTableRegistryImpl(),
        changeCapture: captureA,
        clock: clockA,
      );
      applierB = DriftBatchApplier(
        db: dbB,
        registry: SyncTableRegistryImpl(),
        changeCapture: captureB,
        clock: clockB,
      );

      trashPolicyA = DriftTrashPolicy(db: dbA, clock: clockA);
      trashPolicyB = DriftTrashPolicy(db: dbB, clock: clockB);

      // Cria categoria comum para FKs
      await dbA
          .into(dbA.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-geral',
              name: 'Geral',
              kind: 'both',
              iconKey: 'cart',
              colorHex: const Value('0xFF0000'),
            ),
          );
      await dbB
          .into(dbB.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-geral',
              name: 'Geral',
              kind: 'both',
              iconKey: 'cart',
              colorHex: const Value('0xFF0000'),
            ),
          );
    });

    tearDown(() async {
      applierA.dispose();
      applierB.dispose();
      await dbA.close();
      await dbB.close();
    });

    test('Dado A que exclui item e B que o editou antes da exclusao: restores in A', () async {
      const taskId = 'task-leite-1';

      // 1. Ambos iniciam com a mesma tarefa "Comprar Leite"
      final initialHlc = Hlc(
        millis: DateTime.utc(2026, 10, 22, 9, 0, 0).millisecondsSinceEpoch,
        counter: 0,
        siteId: siteA,
      );

      await captureA.runWithHlc(initialHlc, () async {
        await dbA
            .into(dbA.tasks)
            .insert(
              TasksCompanion.insert(
                id: taskId,
                title: 'Comprar Leite',
                categoryId: const Value('cat-geral'),
              ),
            );
      });

      await captureB.runWithHlc(initialHlc, () async {
        await dbB
            .into(dbB.tasks)
            .insert(
              TasksCompanion.insert(
                id: taskId,
                title: 'Comprar Leite',
                categoryId: const Value('cat-geral'),
              ),
            );
      });

      // 2. B, offline, edits task title at 10:10
      clockB.advance(const Duration(minutes: 10));
      final hlcBEdit = Hlc(
        millis: clockB.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: siteB,
      );

      await captureB.runWithHlc(hlcBEdit, () async {
        await (dbB.update(dbB.tasks)..where((t) => t.id.equals(taskId))).write(
          const TasksCompanion(title: Value('Comprar Leite Desnatado')),
        );
      });

      // 3. A, offline, deletes task (soft-delete to trash) at 10:20 (after B edit)
      clockA.advance(const Duration(minutes: 20));
      final hlcADelete = Hlc(
        millis: clockA.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: siteA,
      );

      final deleteTicketRes = await captureA.runWithHlc(hlcADelete, () async {
        return await trashPolicyA.softDelete('tasks', taskId);
      });
      expect(deleteTicketRes.isOk, isTrue);

      // Verifica que A tem deleted_at gravado
      final taskOnABeforeSync = await (dbA.select(
        dbA.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(taskOnABeforeSync.deletedAt, isNotNull);
      expect(taskOnABeforeSync.title, equals('Comprar Leite'));

      // 4. Synchronization: A sends deletion to B, and B sends edit to A
      final versionsA = await captureA.getCapturedVersions(
        tableName: 'tasks',
        rowId: taskId,
      );
      final deletedVersion = versionsA.firstWhere(
        (v) => v.column == 'deleted_at',
      );

      final batchFromA = SyncBatch(
        householdId: householdId,
        fromSiteId: siteA,
        senderVector: VersionVector({siteA: hlcADelete}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'deleted_at',
            value: deletedVersion.updatedAt,
            hlc: deletedVersion.hlc,
          ),
        ],
      );

      final versionsB = await captureB.getCapturedVersions(
        tableName: 'tasks',
        rowId: taskId,
      );
      final titleVersion = versionsB.firstWhere((v) => v.column == 'title');

      final batchFromB = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcBEdit}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'title',
            value: 'Comprar Leite Desnatado',
            hlc: titleVersion.hlc,
          ),
        ],
      );

      // B aplica o lote de A
      final applyResB = await applierB.apply(batchFromA);
      expect(applyResB.isOk, isTrue);

      // A aplica o lote de B
      final applyResA = await applierA.apply(batchFromB);
      expect(applyResA.isOk, isTrue);

      // Now both must have item in trash with title edited by B!
      final taskOnA = await (dbA.select(
        dbA.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      final taskOnB = await (dbB.select(
        dbB.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();

      expect(taskOnA.title, equals('Comprar Leite Desnatado'));
      expect(taskOnA.deletedAt, isNotNull);

      expect(taskOnB.title, equals('Comprar Leite Desnatado'));
      expect(taskOnB.deletedAt, isNotNull);

      // 5. B restores task from trash at 10:30
      clockB.advance(const Duration(minutes: 10));
      final hlcBRestore = Hlc(
        millis: clockB.nowUtc().millisecondsSinceEpoch,
        counter: 2,
        siteId: siteB,
      );

      final restoreTicket = TrashTicket(
        table: 'tasks',
        id: taskId,
        deletedAt: DateTime.parse(taskOnB.deletedAt!),
      );

      final restoreRes = await captureB.runWithHlc(hlcBRestore, () async {
        return await trashPolicyB.restore(restoreTicket);
      });
      expect(restoreRes.isOk, isTrue);

      // Verifies deletedAt is null again in B
      final taskOnBRestored = await (dbB.select(
        dbB.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(taskOnBRestored.deletedAt, isNull);

      // 6. B sends restoration (deleted_at = null) to A
      final batchRestoreFromB = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcBRestore}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'deleted_at',
            value: null,
            hlc: hlcBRestore,
          ),
        ],
      );

      final applyRestoreOnA = await applierA.apply(batchRestoreFromB);
      expect(applyRestoreOnA.isOk, isTrue);

      // Item must be restored in A as well!
      final taskOnAFinal = await (dbA.select(
        dbA.tasks,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(taskOnAFinal.deletedAt, isNull);
      expect(taskOnAFinal.title, equals('Comprar Leite Desnatado'));
    });

    test('exclusao de despesa propaga deleted_at e restaura em cascata na outra ponta', () async {
      const expenseId = 'exp-supermercado-1';

      final initialHlc = Hlc(
        millis: DateTime.utc(2026, 10, 22, 8, 0, 0).millisecondsSinceEpoch,
        counter: 0,
        siteId: siteA,
      );

      await captureA.runWithHlc(initialHlc, () async {
        await dbA
            .into(dbA.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: expenseId,
                categoryId: const Value('cat-geral'),
                amountCents: 15000,
                occurredOn: '2026-10-22',
                description: const Value('Compras semanais'),
              ),
            );
      });

      await captureB.runWithHlc(initialHlc, () async {
        await dbB
            .into(dbB.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: expenseId,
                categoryId: const Value('cat-geral'),
                amountCents: 15000,
                occurredOn: '2026-10-22',
                description: const Value('Compras semanais'),
              ),
            );
      });

      // A exclui a despesa
      clockA.advance(const Duration(minutes: 5));
      final hlcADel = Hlc(
        millis: clockA.nowUtc().millisecondsSinceEpoch,
        counter: 1,
        siteId: siteA,
      );

      await captureA.runWithHlc(hlcADel, () async {
        await trashPolicyA.softDelete('expenses', expenseId);
      });

      final versionsA = await captureA.getCapturedVersions(
        tableName: 'expenses',
        rowId: expenseId,
      );
      final delVer = versionsA.firstWhere((v) => v.column == 'deleted_at');

      final batchA = SyncBatch(
        householdId: householdId,
        fromSiteId: siteA,
        senderVector: VersionVector({siteA: hlcADel}),
        changes: [
          ColumnVersion(
            table: 'expenses',
            rowId: expenseId,
            column: 'deleted_at',
            value: delVer.updatedAt,
            hlc: delVer.hlc,
          ),
        ],
      );

      final resB = await applierB.apply(batchA);
      expect(resB.isOk, isTrue);

      final expB = await (dbB.select(
        dbB.expenses,
      )..where((e) => e.id.equals(expenseId))).getSingle();
      expect(expB.deletedAt, isNotNull);
    });
  });

  group('Tombstones — Permanent purges and resurrection suppression (RN-322)', () {
    late AppDatabase db;
    late FakeClock clock;
    late ChangeCapture capture;
    late DriftBatchApplier applier;
    late TombstoneStore tombstoneStore;
    late DriftTrashPolicy trashPolicy;

    setUp(() async {
      clock = FakeClock(DateTime.utc(2026, 10, 22, 12, 0, 0));
      db = AppDatabase.memory();
      capture = ChangeCapture(db: db, clock: clock);
      await capture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: siteA,
      );
      applier = DriftBatchApplier(
        db: db,
        registry: SyncTableRegistryImpl(),
        changeCapture: capture,
        clock: clock,
      );
      tombstoneStore = TombstoneStore(db: db, clock: clock);
      trashPolicy = DriftTrashPolicy(db: db, clock: clock);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-geral',
              name: 'Geral',
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

    test('expurgo da lixeira (> 30 dias) gera tombstone no banco', () async {
      const taskId = 'task-expurgo-1';

      // Cria tarefa
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Tarefa antiga',
              categoryId: const Value('cat-geral'),
            ),
          );

      // Exclui suavemente (soft-delete)
      await trashPolicy.softDelete('tasks', taskId);

      // Advances clock by 31 days (> 30-day retention period)
      clock.advance(const Duration(days: 31));

      // Varre expirados
      final sweepRes = await trashPolicy.sweepExpired();
      expect(sweepRes.isOk, isTrue);
      expect(sweepRes.valueOrNull, equals(1));

      // Physical row removed from tasks table
      final tasks = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).get();
      expect(tasks, isEmpty);

      // Trigger de delete gerou um tombstone em sync_row_tombstones
      final tombstones = await tombstoneStore.getAllTombstones(table: 'tasks');
      expect(tombstones.length, equals(1));
      expect(tombstones.first.rowId, equals(taskId));
      expect(tombstones.first.table, equals('tasks'));
    });

    test('lote com tombstone em purged remove linha fisicamente e limpa versoes', () async {
      const taskId = 'task-remota-purgada';

      // Linha existe no banco local
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Tarefa no nó local',
              categoryId: const Value('cat-geral'),
            ),
          );

      // Records existing local column version
      await capture.runAsRemote(() async {
        await db.customStatement('''
          INSERT OR REPLACE INTO sync_column_versions (table_name, row_id, column_name, hlc, site_id, updated_at)
          VALUES ('tasks', '$taskId', 'title', '2026-10-22T10:00:00.000Z:00000:$siteB', '$siteB', '2026-10-22T10:00:00.000Z')
          ''');
      });

      final hlcPurge = Hlc(
        millis: DateTime.utc(2026, 11, 25, 12, 0, 0).millisecondsSinceEpoch,
        counter: 1,
        siteId: siteB,
      );

      final batchWithPurged = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcPurge}),
        purged: [
          RowTombstone(
            id: 'tomb-1',
            table: 'tasks',
            rowId: taskId,
            hlc: hlcPurge,
            purgedAt: '2026-11-25T12:00:00.000Z',
          ),
        ],
      );

      final applyRes = await applier.apply(batchWithPurged);
      expect(applyRes.isOk, isTrue);
      expect(applyRes.valueOrNull!.appliedTombstonesCount, equals(1));

      // Physical row removed
      final rows = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).get();
      expect(rows, isEmpty);

      // Column versions cleaned
      final cvRows = await db
          .customSelect(
            "SELECT * FROM sync_column_versions WHERE table_name = 'tasks' AND row_id = '$taskId'",
          )
          .get();
      expect(cvRows, isEmpty);

      // Tombstone registrado localmente
      final isTomb = await tombstoneStore.isTombstoned('tasks', taskId);
      expect(isTomb, isTrue);
    });

    test('change received for row with tombstone DOES NOT resurrect row even with higher or concurrent HLC', () async {
      const taskId = 'task-morta';

      final hlcTombstone = Hlc(
        millis: DateTime.utc(2026, 11, 1, 12, 0, 0).millisecondsSinceEpoch,
        counter: 0,
        siteId: siteA,
      );

      // Records pre-existing tombstone
      await tombstoneStore.recordTombstone(
        RowTombstone(
          id: 'tomb-morta-1',
          table: 'tasks',
          rowId: taskId,
          hlc: hlcTombstone,
          purgedAt: '2026-11-01T12:00:00.000Z',
        ),
      );

      // 1. Packet arrives with earlier HLC (must not resurrect)
      final hlcAntigo = Hlc(
        millis: DateTime.utc(2026, 10, 25, 10, 0, 0).millisecondsSinceEpoch,
        counter: 5,
        siteId: siteB,
      );

      final batchAntigo = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcAntigo}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'title',
            value: 'Edição zumbi antiga',
            hlc: hlcAntigo,
          ),
        ],
      );

      final applyRes1 = await applier.apply(batchAntigo);
      expect(applyRes1.isOk, isTrue);
      expect(applyRes1.valueOrNull!.appliedChangesCount, equals(0));

      // 2. Packet arrives with HIGHER HLC (clock drift or late edit — must not resurrect!)
      final hlcFuturo = Hlc(
        millis: DateTime.utc(2026, 11, 2, 10, 0, 0).millisecondsSinceEpoch,
        counter: 1,
        siteId: siteB,
      );

      final batchFuturo = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcFuturo}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: taskId,
            column: 'title',
            value: 'Edição zumbi futura que deve ser suprimida',
            hlc: hlcFuturo,
          ),
        ],
      );

      final applyRes2 = await applier.apply(batchFuturo);
      expect(applyRes2.isOk, isTrue);
      expect(applyRes2.valueOrNull!.appliedChangesCount, equals(0));

      // Row MUST NOT exist in database
      final tasks = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(taskId))).get();
      expect(tasks, isEmpty);

      // No version in sync_column_versions
      final cvRows = await db
          .customSelect(
            "SELECT * FROM sync_column_versions WHERE table_name = 'tasks' AND row_id = '$taskId'",
          )
          .get();
      expect(cvRows, isEmpty);
    });

    test('TombstoneStore uses provided IdGenerator to generate predictable identifiers', () async {
      final seqIdGen = SequentialIdGenerator(prefix: 'tomb-seq');
      final storeWithCustomGen = TombstoneStore(
        db: db,
        clock: clock,
        idGenerator: seqIdGen,
      );

      final tomb1 = await storeWithCustomGen.recordPurge(
        table: 'tasks',
        rowId: 'task-abc',
        hlc: Hlc(millis: 1000, counter: 0, siteId: siteA),
      );
      final tomb2 = await storeWithCustomGen.recordPurge(
        table: 'tasks',
        rowId: 'task-def',
        hlc: Hlc(millis: 1001, counter: 0, siteId: siteA),
      );

      expect(tomb1.id, equals('tomb-seq-001'));
      expect(tomb2.id, equals('tomb-seq-002'));
    });

    test('lote com tombstone em purchases e expenses desconecta foreign keys sem violar integridade referencial', () async {
      const purchId = 'purch-com-fk-1';
      const expId = 'exp-com-fk-1';
      const pItemId = 'pitem-com-fk-1';
      const ppId = 'pp-com-fk-1';

      // Cria compra e despesa mutuamente referenciadas
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: purchId,
              purchasedAt: '2026-10-22T10:00:00.000Z',
              totalCents: 5000,
              source: 'manual',
            ),
          );

      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: expId,
              categoryId: const Value('cat-geral'),
              amountCents: 5000,
              occurredOn: '2026-10-22',
              purchaseId: const Value(purchId),
            ),
          );

      await db.customStatement(
        'UPDATE purchases SET expense_id = ? WHERE id = ?;',
        [expId, purchId],
      );

      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: pItemId,
              purchaseId: purchId,
              rawDescription: 'Item teste',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 5000,
              totalPriceCents: 5000,
              position: 0,
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: ppId,
              observedAt: '2026-10-22T10:00:00.000Z',
              unitPriceCents: 5000,
              normalizedPriceCents: 5000,
              quantityMilli: 1000,
              unit: 'un',
              source: 'manual',
              purchaseItemId: const Value(pItemId),
            ),
          );

      // Aplica tombstone remoto da compra
      final hlcPurge = Hlc(
        millis: DateTime.utc(2026, 11, 25, 12, 0, 0).millisecondsSinceEpoch,
        counter: 1,
        siteId: siteB,
      );

      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: siteB,
        senderVector: VersionVector({siteB: hlcPurge}),
        purged: [
          RowTombstone(
            id: 'tomb-purch-1',
            table: 'purchases',
            rowId: purchId,
            hlc: hlcPurge,
            purgedAt: '2026-11-25T12:00:00.000Z',
          ),
        ],
      );

      final applyRes = await applier.apply(batch);
      expect(applyRes.isOk, isTrue, reason: applyRes.toString());

      // Purchase was physically deleted
      final purchRows = await (db.select(
        db.purchases,
      )..where((p) => p.id.equals(purchId))).get();
      expect(purchRows, isEmpty);

      // Despesa teve purchase_id limpo
      final expRow = await (db.select(
        db.expenses,
      )..where((e) => e.id.equals(expId))).getSingle();
      expect(expRow.purchaseId, isNull);

      // Price point teve purchase_item_id limpo
      final ppRow = await (db.select(
        db.pricePoints,
      )..where((p) => p.id.equals(ppId))).getSingle();
      expect(ppRow.purchaseItemId, isNull);
    });

    test('lote contendo apenas tombstones atualiza sync_peer_vectors para o site do tombstone', () async {
      final hlcPurge = Hlc(
        millis: DateTime.utc(2026, 11, 26, 14, 0, 0).millisecondsSinceEpoch,
        counter: 10,
        siteId: 'site-purger-99',
      );

      final batch = SyncBatch(
        householdId: householdId,
        fromSiteId: 'site-relayed-from',
        senderVector: VersionVector.empty,
        purged: [
          RowTombstone(
            id: 'tomb-isolated-1',
            table: 'tasks',
            rowId: 'task-isolated-1',
            hlc: hlcPurge,
            purgedAt: '2026-11-26T14:00:00.000Z',
          ),
        ],
      );

      final applyRes = await applier.apply(batch);
      expect(applyRes.isOk, isTrue);

      final vectorRow = await db
          .customSelect(
            'SELECT hlc FROM sync_peer_vectors WHERE household_id = ? AND site_id = ?',
            variables: [
              Variable.withString(householdId),
              Variable.withString('site-purger-99'),
            ],
          )
          .getSingleOrNull();

      expect(vectorRow, isNotNull);
      expect(vectorRow!.data['hlc'], equals(hlcPurge.pack()));
    });

    test(
      'TombstoneStore: operacoes basicas e expurgo de tombstones antigos',
      () async {
        final hlc1 = Hlc(
          millis: DateTime.utc(2026, 1, 1, 12, 0, 0).millisecondsSinceEpoch,
          counter: 0,
          siteId: siteA,
        );

        // Registra purga com recordPurge
        final tomb = await tombstoneStore.recordPurge(
          table: 'expenses',
          rowId: 'exp-123',
          hlc: hlc1,
          purgedAt: DateTime.utc(2026, 1, 1, 12, 0, 0),
        );

        expect(tomb.table, equals('expenses'));
        expect(tomb.rowId, equals('exp-123'));
        expect(
          await tombstoneStore.isTombstoned('expenses', 'exp-123'),
          isTrue,
        );
        expect(
          await tombstoneStore.isTombstoned('expenses', 'exp-inexistente'),
          isFalse,
        );

        final fetched = await tombstoneStore.getTombstone(
          'expenses',
          'exp-123',
        );
        expect(fetched, isNotNull);
        expect(fetched!.id, equals(tomb.id));

        // Expurgo de tombstones com retention de 90 dias
        // Tombstone was recorded on 2026-01-01, clock is at 2026-10-22 (> 9 months later)
        final sweptCount = await tombstoneStore.sweepExpiredTombstones(
          retention: const Duration(days: 90),
        );
        expect(sweptCount, equals(1));
        expect(
          await tombstoneStore.isTombstoned('expenses', 'exp-123'),
          isFalse,
        );
      },
    );

    test('RowTombstone toJson e fromJson round-trip', () {
      final hlc = Hlc(millis: 1700000000000, counter: 42, siteId: 'device-x');
      final original = RowTombstone(
        id: 'tomb-uuid-123',
        table: 'shopping_items',
        rowId: 'item-999',
        hlc: hlc,
        purgedAt: '2026-10-22T12:00:00.000Z',
      );

      final json = original.toJson();
      final reconstructed = RowTombstone.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.key, equals('shopping_items:item-999'));
      expect(reconstructed.toString(), contains('shopping_items:item-999'));
    });
  });
}
