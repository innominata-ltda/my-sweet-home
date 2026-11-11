import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/task_presets/data/drift_task_from_preset.dart';
import 'package:my_sweet_home/features/task_presets/presentation/duplicate_preset_dialog.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_task_from_preset.dart';
import '../../fakes/fake_task_preset_catalog.dart';
import '../../fakes/sequential_id_generator.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: child,
    ),
  );
}

void main() {
  group('CA-3.1 & CA-3.2: DriftTaskFromPreset activeOriginPresetIds', () {
    late AppDatabase db;
    late FakeClock clock;
    late SequentialIdGenerator idGen;
    late DriftTrashPolicy trashPolicy;
    late DriftTaskFromPreset taskFromPreset;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 10));
      idGen = SequentialIdGenerator(prefix: 'test');
      trashPolicy = DriftTrashPolicy.system(db: db);
      taskFromPreset = DriftTaskFromPreset(
        db: db,
        clock: clock,
        idGenerator: idGen,
        trashPolicy: trashPolicy,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'CA-3.1: Active task from preset is returned in activeOriginPresetIds',
      () async {
        final draft = TaskDraft(
          title: 'Lavar roupa',
          firstOccurrence: clock.todayUtc(),
          allDay: true,
          rrule: 'FREQ=DAILY;INTERVAL=7',
          sourcePresetId: 'wash-clothes',
        );

        final res = await taskFromPreset.create(draft);
        expect(res.isOk, isTrue);

        final activeIdsRes = await taskFromPreset.activeOriginPresetIds();
        expect(activeIdsRes.isOk, isTrue);
        expect(activeIdsRes.valueOrNull!, contains('wash-clothes'));
      },
    );

    test(
      'CA-3.2: Soft-deleted task clears activeOriginPresetIds mark',
      () async {
        final draft = TaskDraft(
          title: 'Lavar roupa',
          firstOccurrence: clock.todayUtc(),
          allDay: true,
          rrule: 'FREQ=DAILY;INTERVAL=7',
          sourcePresetId: 'wash-clothes',
        );

        final res = await taskFromPreset.create(draft);
        expect(res.isOk, isTrue);
        final taskId = res.valueOrNull!.id;

        // Soft delete via trash policy
        final deleteRes = await trashPolicy.softDelete('tasks', taskId);
        expect(deleteRes.isOk, isTrue);

        final activeIdsRes = await taskFromPreset.activeOriginPresetIds();
        expect(activeIdsRes.isOk, isTrue);
        expect(activeIdsRes.valueOrNull!, isNot(contains('wash-clothes')));
      },
    );

    test(
      'Non-recurring completed task no longer appears in activeOriginPresetIds',
      () async {
        final draft = TaskDraft(
          title: 'Lavar roupa pontual',
          firstOccurrence: clock.todayUtc(),
          allDay: true,
          rrule: null,
          sourcePresetId: 'wash-clothes',
        );

        final res = await taskFromPreset.create(draft);
        expect(res.isOk, isTrue);
        final taskId = res.valueOrNull!.id;

        // Conclui a tarefa no banco
        await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
          const TasksCompanion(isCompleted: Value(true)),
        );

        final activeIdsRes = await taskFromPreset.activeOriginPresetIds();
        expect(activeIdsRes.isOk, isTrue);
        expect(activeIdsRes.valueOrNull!, isNot(contains('wash-clothes')));
      },
    );
  });

  group('CA-3.1 & CA-3.2: TaskPresetCatalogPage UI & Dialog', () {
    late FakeClock clock;
    late FakeTaskPresetCatalog fakeCatalogPort;
    late FakeTaskFromPreset fakeTaskFromPresetPort;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 10));
      fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
      fakeTaskFromPresetPort = FakeTaskFromPreset(activeIds: {'wash-clothes'});
    });

    testWidgets(
      'CA-3.1: "Lavar roupa" exibe marcação "já na sua rotina"; ao tocar pede confirmação',
      (tester) async {
        TaskDraft? openedDraft;

        await tester.pumpWidget(
          _wrap(
            TaskPresetCatalogPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
              onOpenDraft: (draft) {
                openedDraft = draft;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Encontra o tile de "Lavar roupa"
        final washClothesFinder = find.text('Lavar roupa');
        expect(washClothesFinder, findsOneWidget);
        await tester.ensureVisible(washClothesFinder);
        await tester.pumpAndSettle();

        // Verify routine badge is visible
        expect(find.text('Já na sua rotina'), findsOneWidget);

        // Toca no tile de "Lavar roupa"
        await tester.tap(washClothesFinder);
        await tester.pumpAndSettle();

        // DuplicatePresetDialog should appear
        expect(find.byType(DuplicatePresetDialog), findsOneWidget);
        expect(find.text('Tarefa já existe na rotina'), findsOneWidget);

        // If cancelled, nothing is opened
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(openedDraft, isNull);

        // Toca novamente e agora confirma
        await tester.tap(washClothesFinder);
        await tester.pumpAndSettle();
        expect(find.byType(DuplicatePresetDialog), findsOneWidget);

        await tester.tap(find.text('Adicionar mesmo assim'));
        await tester.pumpAndSettle();

        // Draft opened successfully to create second task
        expect(openedDraft, isNotNull);
        expect(openedDraft!.title, 'Lavar roupa');
        expect(openedDraft!.sourcePresetId, 'wash-clothes');
      },
    );

    testWidgets(
      'CA-3.2: Quando a tarefa não está ativa, "já na sua rotina" não é exibido',
      (tester) async {
        // Sem activeIds
        final emptyPort = FakeTaskFromPreset(activeIds: {});

        await tester.pumpWidget(
          _wrap(
            TaskPresetCatalogPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: emptyPort,
              clock: clock,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Lavar roupa'), findsOneWidget);
        expect(find.text('Já na sua rotina'), findsNothing);
      },
    );
  });
}
