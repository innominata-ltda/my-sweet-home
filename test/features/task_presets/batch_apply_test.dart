import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/task_presets/data/drift_task_from_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/presentation/batch_start_dates_sheet.dart';
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('CA-4.1: DriftTaskFromPreset createBatch e undoBatch', () {
    late AppDatabase db;
    late FakeClock clock;
    late SequentialIdGenerator idGen;
    late DriftTaskFromPreset taskFromPreset;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 3, 10));
      idGen = SequentialIdGenerator(prefix: 'batch_test');
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

    test(
      'CA-4.1: createBatch de 5 cria 5 tarefas e undoBatch remove todas as 5',
      () async {
        final drafts = List.generate(
          5,
          (i) => TaskDraft(
            title: 'Tarefa Lote $i',
            firstOccurrence: clock.todayUtc(),
            allDay: true,
            rrule: 'FREQ=DAILY;INTERVAL=${i + 1}',
            sourcePresetId: 'preset_$i',
          ),
        );

        final createRes = await taskFromPreset.createBatch(drafts);
        expect(createRes.isOk, isTrue);
        final createdTasks = createRes.valueOrNull!;
        expect(createdTasks.length, 5);

        // Confere no banco de dados real
        final rowsInDb = await (db.select(db.tasks)).get();
        expect(rowsInDb.length, 5);

        // Desfaz o lote via undoBatch
        final tickets = createdTasks
            .map(
              (t) => TrashTicket(
                id: t.id,
                table: 'tasks',
                deletedAt: clock.nowUtc(),
              ),
            )
            .toList();

        final undoRes = await taskFromPreset.undoBatch(tickets);
        expect(undoRes.isOk, isTrue);

        final rowsAfterUndo = await (db.select(db.tasks)).get();
        expect(rowsAfterUndo, isEmpty);

        final rulesAfterUndo = await (db.select(db.recurringRules)).get();
        expect(rulesAfterUndo, isEmpty);
      },
    );
  });

  group('CA-4.2: BatchStartDatesSheet individual start dates', () {
    late FakeClock clock;
    const presets = [
      TaskPreset(
        id: 'wash-clothes',
        area: TaskPresetArea.laundry,
        title: 'Lavar roupa',
        recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
        rationale: 'Evita acúmulo.',
      ),
      TaskPreset(
        id: 'sweep-floor',
        area: TaskPresetArea.generalCleaning,
        title: 'Varrer o chão',
        recommendedRrule: 'FREQ=DAILY;INTERVAL=3',
        rationale: 'Poeira acumula.',
      ),
      TaskPreset(
        id: 'wash-dishes',
        area: TaskPresetArea.kitchen,
        title: 'Lavar louça',
        recommendedRrule: 'FREQ=DAILY;INTERVAL=1',
        rationale: 'Higiene diária.',
      ),
    ];

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 10));
    });

    testWidgets(
      'CA-4.2: As 3 predefinições começam com 10/03/2026 pré-preenchido',
      (tester) async {
        Map<String, DateTime>? resultDates;

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultDates = await BatchStartDatesSheet.show(
                    context,
                    presets: presets,
                    clock: clock,
                  );
                },
                child: const Text('Abrir Lote'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Lote'));
        await tester.pumpAndSettle();

        // 3 buttons with "10/03/2026"
        expect(find.text('10/03/2026'), findsNWidgets(3));
        expect(find.text('Lavar roupa'), findsOneWidget);
        expect(find.text('Varrer o chão'), findsOneWidget);
        expect(find.text('Lavar louça'), findsOneWidget);

        // Confirma sem alterar
        await tester.tap(find.text('Confirmar rotina'));
        await tester.pumpAndSettle();

        expect(resultDates, isNotNull);
        expect(resultDates!['wash-clothes'], DateTime.utc(2026, 3, 10));
        expect(resultDates!['sweep-floor'], DateTime.utc(2026, 3, 10));
        expect(resultDates!['wash-dishes'], DateTime.utc(2026, 3, 10));
      },
    );

    testWidgets('CA-4.2: Changing date confirms with correct dates', (
      tester,
    ) async {
      Map<String, DateTime>? resultDates;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultDates = await BatchStartDatesSheet.show(
                  context,
                  presets: presets,
                  clock: clock,
                );
              },
              child: const Text('Abrir Lote'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Lote'));
      await tester.pumpAndSettle();

      // Toca no date picker de 'wash-clothes'
      await tester.tap(find.byKey(const Key('date_picker_wash-clothes')));
      await tester.pumpAndSettle();

      // In March 2026 DatePicker, tap day 14
      await tester.tap(find.text('14'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Confere que agora wash-clothes mostra 14/03/2026 e os outros continuam 10/03/2026
      expect(find.text('14/03/2026'), findsOneWidget);
      expect(find.text('10/03/2026'), findsNWidgets(2));

      // Confirma
      await tester.tap(find.text('Confirmar rotina'));
      await tester.pumpAndSettle();

      expect(resultDates, isNotNull);
      expect(resultDates!['wash-clothes'], DateTime.utc(2026, 3, 14));
      expect(resultDates!['sweep-floor'], DateTime.utc(2026, 3, 10));
      expect(resultDates!['wash-dishes'], DateTime.utc(2026, 3, 10));
    });
  });

  group('CA-4.1: TaskPresetCatalogPage batch selection and Undo button', () {
    late FakeClock clock;
    late FakeTaskPresetCatalog fakeCatalogPort;
    late FakeTaskFromPreset fakeTaskFromPresetPort;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 10));
      fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
      fakeTaskFromPresetPort = FakeTaskFromPreset();
    });

    testWidgets(
      'Seleciona 2 tarefas, confirma lote e toca em Desfazer -> undoBatch é chamado',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TaskPresetCatalogPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Encontra os checkboxes das tarefas
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsWidgets);

        // Marca as duas primeiras
        await tester.tap(checkboxes.at(0));
        await tester.pumpAndSettle();
        await tester.tap(checkboxes.at(1));
        await tester.pumpAndSettle();

        // Bottom button shows "Adicionar 2 tarefas"
        final addBtn = find.text('Adicionar 2 tarefas');
        expect(addBtn, findsOneWidget);

        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Start dates sheet is opened
        expect(find.byType(BatchStartDatesSheet), findsOneWidget);
        expect(find.text('Confirmar rotina'), findsOneWidget);

        await tester.tap(find.text('Confirmar rotina'));
        await tester.pumpAndSettle();

        // As tarefas foram criadas no fake
        expect(fakeTaskFromPresetPort.created.length, 2);

        // SnackBar appears with Undo button
        expect(find.text('2 tarefas adicionadas!'), findsOneWidget);
        expect(find.text('Desfazer'), findsOneWidget);

        // Toca em Desfazer
        await tester.tap(find.text('Desfazer'));
        await tester.pumpAndSettle();

        // undoBatch foi chamado com os tickets
        expect(fakeTaskFromPresetPort.undoneTickets.length, 2);
        expect(fakeTaskFromPresetPort.created, isEmpty);
      },
    );
  });
}
