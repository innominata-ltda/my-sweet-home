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

  group('CA-1.2 & CA-1.3: Applying preset to task', () {
    test('CA-1.2: Varrer o chao saves with category Casa, FREQ=DAILY;INTERVAL=3 and dueAt 2026-03-10', () async {
      const preset = TaskPreset(
        id: 'sweep-floor',
        area: TaskPresetArea.generalCleaning,
        title: 'Varrer o chão',
        recommendedRrule: 'FREQ=DAILY;INTERVAL=3',
        rationale: 'Poeira e cabelo se espalham rápido.',
      );

      final draft = TaskDraft(
        title: preset.title,
        firstOccurrence: clock.todayUtc(),
        allDay: true,
        rrule: preset.recommendedRrule,
        sourcePresetId: preset.id,
      );

      final result = await taskFromPreset.create(draft);
      expect(result.isOk, isTrue);

      final created = result.valueOrNull!;
      expect(created.title, 'Varrer o chão');
      expect(created.firstOccurrence, DateTime.utc(2026, 3, 10));
      expect(created.rrule, 'FREQ=DAILY;INTERVAL=3');
      expect(created.sourcePresetId, 'sweep-floor');

      // Verify in real database
      final taskRow = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(created.id))).getSingle();
      expect(taskRow.title, 'Varrer o chão');
      expect(taskRow.sourcePresetId, 'sweep-floor');
      expect(taskRow.dueAt, '2026-03-10T00:00:00.000Z');
      expect(taskRow.categoryId, 'cat_home');

      // Verify recurrence rule
      expect(taskRow.recurringRuleId, isNotNull);
      final ruleRow = await (db.select(
        db.recurringRules,
      )..where((r) => r.id.equals(taskRow.recurringRuleId!))).getSingle();
      expect(ruleRow.rrule, 'FREQ=DAILY;INTERVAL=3');

      // Verifica categoria Casa criada
      final catRow = await (db.select(
        db.categories,
      )..where((c) => c.id.equals('cat_home'))).getSingle();
      expect(catRow.name, 'Casa');
      expect(catRow.kind, 'task');
    });

    test('CA-1.3: Changing frequency to INTERVAL=2 saves task with 2 days and catalog remains with 3', () async {
      final fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
      final catalogBefore = (await fakeCatalogPort.load()).valueOrNull!;
      final sweepPreset = catalogBefore.presets.firstWhere(
        (p) => p.id == 'sweep-floor',
      );
      expect(sweepPreset.recommendedRrule, 'FREQ=DAILY;INTERVAL=3');

      // User changes frequency in draft to 2 days
      final editedDraft = TaskDraft(
        title: sweepPreset.title,
        firstOccurrence: clock.todayUtc(),
        allDay: true,
        rrule: 'FREQ=DAILY;INTERVAL=2',
        sourcePresetId: sweepPreset.id,
      );

      final result = await taskFromPreset.create(editedDraft);
      expect(result.isOk, isTrue);

      final created = result.valueOrNull!;
      expect(created.rrule, 'FREQ=DAILY;INTERVAL=2');

      final taskRow = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(created.id))).getSingle();
      final ruleRow = await (db.select(
        db.recurringRules,
      )..where((r) => r.id.equals(taskRow.recurringRuleId!))).getSingle();
      expect(ruleRow.rrule, 'FREQ=DAILY;INTERVAL=2');

      // Catalog remains intact with INTERVAL=3
      final catalogAfter = (await fakeCatalogPort.load()).valueOrNull!;
      final sweepPresetAfter = catalogAfter.presets.firstWhere(
        (p) => p.id == 'sweep-floor',
      );
      expect(sweepPresetAfter.recommendedRrule, 'FREQ=DAILY;INTERVAL=3');
    });
  });
}
