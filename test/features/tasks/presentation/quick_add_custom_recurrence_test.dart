import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task;
import 'package:my_sweet_home/features/tasks/data/task_dao.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/quick_add_task_sheet.dart';

import '../../../fakes/fake_clock.dart';

void main() {
  late AppDatabase db;
  late TaskDao repository;
  late FakeClock clock;
  late IdGenerator idGenerator;
  late TrashPolicy trashPolicy;

  setUp(() async {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 3, 10, 9, 0));
    idGenerator = const UuidV7Generator();
    trashPolicy = DriftTrashPolicy.system(db: db);

    repository = TaskDao(
      db: db,
      clock: clock,
      idGenerator: idGenerator,
      trashPolicy: trashPolicy,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildWidget({
    required DateTime initialDate,
    TaskDraft? initialDraft,
    Task? initialTask,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: QuickAddTaskSheet(
          repository: repository,
          clock: clock,
          initialDate: initialDate,
          initialDraft: initialDraft,
          initialTask: initialTask,
        ),
      ),
    );
  }

  group(
    'SPEC-007 / T-B17 — Opção "A cada X dias" com campo numérico (RN-163)',
    () {
      testWidgets(
        'Opção "A cada X dias" está disponível no dropdown de repetição',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(initialDate: DateTime.utc(2026, 3, 10)),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('quick_add_custom_days_field')),
            findsNothing,
          );

          await tester.tap(find.byType(DropdownButtonFormField<String?>));
          await tester.pumpAndSettle();

          expect(find.text('A cada X dias'), findsWidgets);
        },
      );

      testWidgets(
        'CA-1.3: Seleciona "A cada X dias", digita 4 em 2026-03-10, salva com FREQ=DAILY;INTERVAL=4 e conclui gerando 2026-03-14',
        (tester) async {
          await tester.pumpWidget(
            buildWidget(initialDate: DateTime.utc(2026, 3, 10)),
          );
          await tester.pumpAndSettle();

          // 1. Fill title
          await tester.enterText(find.byType(TextField).first, 'Regar plantas');

          // 2. Seleciona "A cada X dias"
          await tester.tap(find.byType(DropdownButtonFormField<String?>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('A cada X dias').last);
          await tester.pumpAndSettle();

          // 3. Numeric field is displayed
          final daysFinder = find.byKey(
            const Key('quick_add_custom_days_field'),
          );
          expect(daysFinder, findsOneWidget);

          // 4. Digita 4 no campo
          await tester.enterText(daysFinder, '4');
          await tester.pumpAndSettle();

          // 5. Salva
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();

          // 6. Verifica tarefa salva
          final tasksResult = await repository.allTasksForSync();
          expect(tasksResult.isOk, isTrue);
          final tasks = tasksResult.valueOrNull!;
          expect(tasks.length, 1);
          final task = tasks.first;
          expect(task.title, 'Regar plantas');
          expect(task.dueAt, DateTime.utc(2026, 3, 10));

          // 7. Conclui a tarefa em 2026-03-10
          final completeResult = await repository.complete(task.id);
          expect(completeResult.isOk, isTrue);

          // 8. Next occurrence generated at 2026-03-14
          final updatedTasksResult = await repository.allTasksForSync();
          final pending = updatedTasksResult.valueOrNull!
              .where((t) => !t.isCompleted)
              .toList();
          expect(pending.length, 1);
          expect(pending.first.dueAt, DateTime.utc(2026, 3, 14));
        },
      );

      testWidgets(
        'CA-1.4: Informar 0 ou deixar campo de dias vazio impede salvamento e anuncia erro (A11Y-8)',
        (tester) async {
          final handle = tester.ensureSemantics();

          await tester.pumpWidget(
            buildWidget(initialDate: DateTime.utc(2026, 3, 10)),
          );
          await tester.pumpAndSettle();

          // Fill title
          await tester.enterText(
            find.byType(TextField).first,
            'Trocar toalhas',
          );

          // Seleciona "A cada X dias"
          await tester.tap(find.byType(DropdownButtonFormField<String?>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('A cada X dias').last);
          await tester.pumpAndSettle();

          final daysFinder = find.byKey(
            const Key('quick_add_custom_days_field'),
          );
          expect(daysFinder, findsOneWidget);

          // Tenta salvar com campo vazio
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();

          // Should not save
          var tasksResult = await repository.allTasksForSync();
          expect(tasksResult.valueOrNull!, isEmpty);

          // Validation error message announced
          expect(
            find.text('Informe um valor entre 1 e 365 dias'),
            findsOneWidget,
          );

          // Digita 0
          await tester.enterText(daysFinder, '0');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();

          // Should not save
          tasksResult = await repository.allTasksForSync();
          expect(tasksResult.valueOrNull!, isEmpty);
          expect(
            find.text('Informe um valor entre 1 e 365 dias'),
            findsOneWidget,
          );

          // Digita 400 (> 365)
          await tester.enterText(daysFinder, '400');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();

          // Should not save
          tasksResult = await repository.allTasksForSync();
          expect(tasksResult.valueOrNull!, isEmpty);
          expect(
            find.text('Informe um valor entre 1 e 365 dias'),
            findsOneWidget,
          );

          // A11Y-8: Persistent label and liveRegion
          expect(find.text('Quantidade de dias *'), findsWidgets);
          final liveRegionFinder = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          );
          expect(liveRegionFinder, findsAtLeastNWidgets(1));

          handle.dispose();
        },
      );

      testWidgets(
        'RN-163: Pré-seleciona "A cada X dias" quando aberto com TaskDraft contendo FREQ=DAILY;INTERVAL=15',
        (tester) async {
          final draft = TaskDraft(
            title: 'Trocar lençol',
            firstOccurrence: DateTime.utc(2026, 3, 10),
            allDay: true,
            rrule: 'FREQ=DAILY;INTERVAL=15',
          );

          await tester.pumpWidget(
            buildWidget(
              initialDate: DateTime.utc(2026, 3, 10),
              initialDraft: draft,
            ),
          );
          await tester.pumpAndSettle();

          // Numeric field already visible with 15
          final daysFinder = find.byKey(
            const Key('quick_add_custom_days_field'),
          );
          expect(daysFinder, findsOneWidget);
          expect(find.text('15'), findsOneWidget);

          // Editable: change to 20 and save
          await tester.enterText(daysFinder, '20');
          await tester.pumpAndSettle();

          await tester.tap(find.text('Salvar'));
          await tester.pumpAndSettle();

          final tasksResult = await repository.allTasksForSync();
          final tasks = tasksResult.valueOrNull!;
          expect(tasks.length, 1);
          expect(tasks.first.title, 'Trocar lençol');

          // Complete on 2026-03-10 -> next occurrence must be 2026-03-30 (+20 days)
          await repository.complete(tasks.first.id);
          final updatedTasksResult = await repository.allTasksForSync();
          final pending = updatedTasksResult.valueOrNull!
              .where((t) => !t.isCompleted)
              .toList();
          expect(pending.first.dueAt, DateTime.utc(2026, 3, 30));
        },
      );

      testWidgets(
        'RN-163: Pré-seleciona "A cada X dias" quando aberto com tarefa (initialTask) contendo FREQ=DAILY;INTERVAL=5',
        (tester) async {
          final existingTask = Task(
            id: 'task-1',
            title: 'Regar orquídeas',
            allDay: true,
            dueAt: DateTime.utc(2026, 3, 10),
            isCompleted: false,
            recurringRuleId: 'FREQ=DAILY;INTERVAL=5',
            syncState: SyncState.synced,
            createdAt: DateTime.utc(2026, 3, 1),
            updatedAt: DateTime.utc(2026, 3, 1),
          );

          await tester.pumpWidget(
            buildWidget(
              initialDate: DateTime.utc(2026, 3, 10),
              initialTask: existingTask,
            ),
          );
          await tester.pumpAndSettle();

          // Title populated
          expect(find.text('Regar orquídeas'), findsOneWidget);

          // Campo de dias com 5
          final daysFinder = find.byKey(
            const Key('quick_add_custom_days_field'),
          );
          expect(daysFinder, findsOneWidget);
          expect(find.text('5'), findsOneWidget);
        },
      );
    },
  );
}
