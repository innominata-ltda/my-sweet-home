import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/task_presets/data/drift_task_from_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_task_preset_catalog.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator idGen;
  late DriftTaskFromPreset taskFromPreset;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    idGen = SequentialIdGenerator(prefix: 'test');
    taskFromPreset = DriftTaskFromPreset(
      db: db,
      clock: clock,
      idGenerator: idGen,
      trashPolicy: DriftTrashPolicy.system(db: db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group(
    'CA-6.1: Atualizar o catálogo não altera tarefa já criada (RN-356)',
    () {
      test('Given task created with INTERVAL=7, new catalog version with INTERVAL=10 does not alter existing task', () async {
        // 1. Create task from preset with INTERVAL=7
        final draft = TaskDraft(
          title: 'Lavar roupa',
          firstOccurrence: clock.todayUtc(),
          allDay: true,
          rrule: 'FREQ=DAILY;INTERVAL=7',
          sourcePresetId: 'wash-clothes',
        );

        final createRes = await taskFromPreset.create(draft);
        expect(createRes.isOk, isTrue);
        final created = createRes.valueOrNull!;
        expect(created.rrule, 'FREQ=DAILY;INTERVAL=7');

        // Confere dados no banco
        final initialTaskRow = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals(created.id))).getSingle();
        final initialRuleRow =
            await (db.select(db.recurringRules)
                  ..where((r) => r.id.equals(initialTaskRow.recurringRuleId!)))
                .getSingle();

        expect(initialTaskRow.title, 'Lavar roupa');
        expect(initialTaskRow.sourcePresetId, 'wash-clothes');
        expect(initialRuleRow.rrule, 'FREQ=DAILY;INTERVAL=7');

        // 2. Load fake catalog v2 where preset updated to INTERVAL=10
        const updatedPreset = TaskPreset(
          id: 'wash-clothes',
          area: TaskPresetArea.laundry,
          title: 'Lavar roupa atualizada',
          recommendedRrule: 'FREQ=DAILY;INTERVAL=10',
          rationale: 'Nova recomendação técnica.',
        );

        final v2CatalogPort = FakeTaskPresetCatalog(
          catalog: const TaskPresetCatalog(
            version: 2,
            presets: [updatedPreset],
          ),
        );

        final catalogRes = await v2CatalogPort.load();
        expect(catalogRes.isOk, isTrue);
        final loadedCatalog = catalogRes.valueOrNull!;
        expect(loadedCatalog.version, 2);
        expect(
          loadedCatalog.presets.first.recommendedRrule,
          'FREQ=DAILY;INTERVAL=10',
        );

        // 3. Executa consultas de rotina
        final activeRes = await taskFromPreset.activeOriginPresetIds();
        expect(activeRes.isOk, isTrue);
        expect(activeRes.valueOrNull!, contains('wash-clothes'));

        // 4. Confirma que a tarefa e sua regra no banco permanecem totalmente inalteradas
        final finalTaskRow = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals(created.id))).getSingle();
        final finalRuleRow =
            await (db.select(db.recurringRules)
                  ..where((r) => r.id.equals(finalTaskRow.recurringRuleId!)))
                .getSingle();

        expect(finalTaskRow.title, 'Lavar roupa');
        expect(finalTaskRow.dueAt, initialTaskRow.dueAt);
        expect(finalTaskRow.sourcePresetId, 'wash-clothes');
        expect(finalRuleRow.rrule, 'FREQ=DAILY;INTERVAL=7');
      });
    },
  );
}
