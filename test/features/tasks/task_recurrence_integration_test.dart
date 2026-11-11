import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task, Category;
import 'package:my_sweet_home/features/tasks/data/task_dao.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/notifying_task_repository.dart';
import 'package:my_sweet_home/features/tasks/domain/task_reminder_planner.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/recording_scheduler.dart';

void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late FakeClock clock;
  late IdGenerator idGenerator;
  late TrashPolicy trashPolicy;
  late RecordingScheduler scheduler;
  late TaskReminderPlanner planner;
  late NotifyingTaskRepository repository;

  setUp(() async {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 3, 10, 10, 0)); // 10:00 AM UTC
    idGenerator = const UuidV7Generator();
    trashPolicy = DriftTrashPolicy.system(db: db);

    taskDao = TaskDao(
      db: db,
      clock: clock,
      idGenerator: idGenerator,
      trashPolicy: trashPolicy,
    );

    scheduler = RecordingScheduler();
    planner = const DefaultTaskReminderPlanner();

    repository = NotifyingTaskRepository(
      inner: taskDao,
      scheduler: scheduler,
      planner: planner,
      clock: clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('CA-1.1: "every 15 days", completed on 10/03 -> generates 25/03 and schedules reminder', () async {
    // 1. Create recurrence rule
    final ruleId = idGenerator.newId();
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: ruleId,
            kind: 'task',
            rrule: 'FREQ=DAILY;INTERVAL=15',
            startsOn: DateTime.utc(2026, 3, 1).toIso8601String(),
            title: 'Trocar lençol',
          ),
        );

    // 2. Inserir tarefa agendada para 10/03
    final newTask = NewTask(
      title: 'Trocar lençol',
      allDay: true,
      dueAt: DateTime.utc(2026, 3, 10),
      recurringRuleId: ruleId,
    );

    final upsertResult = await repository.upsert(newTask);
    final task = upsertResult.valueOrNull!;
    expect(task.isCompleted, isFalse);
    expect(task.dueAt, DateTime.utc(2026, 3, 10));

    for (final s in scheduler.scheduled.toList()) {
      await scheduler.cancel(s.id);
    }

    // 3. Concluir hoje (10/03)
    final completeResult = await repository.complete(task.id);
    expect(completeResult.isOk, isTrue);

    // 4. Verify pending occurrence
    final pendingResult = await taskDao.dirtySince(null);
    final pendingTasks = pendingResult.valueOrNull!
        .where((t) => !t.isCompleted)
        .toList();
    expect(pendingTasks.length, 1);

    final nextTask = pendingTasks.first;
    expect(nextTask.title, 'Trocar lençol');
    expect(nextTask.dueAt, DateTime.utc(2026, 3, 25));

    // 5. Verify scheduling in time (NotifyingTaskRepository schedules based on next task)
    expect(scheduler.scheduled.length, 1);
    expect(scheduler.scheduled.first.id, 'task_${nextTask.id}');
  });

  test('CA-1.2: "every 10th", completed late on 12/03 -> generates 10/04 and schedules reminder', () async {
    // 1. Create recurrence rule
    final ruleId = idGenerator.newId();
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: ruleId,
            kind: 'task',
            rrule: 'FREQ=MONTHLY;BYMONTHDAY=10',
            startsOn: DateTime.utc(2026, 3, 10).toIso8601String(),
            title: 'Pagar condomínio',
          ),
        );

    // 2. Inserir tarefa agendada para 10/03
    final newTask = NewTask(
      title: 'Pagar condomínio',
      allDay: true,
      dueAt: DateTime.utc(2026, 3, 10),
      recurringRuleId: ruleId,
    );

    final upsertResult = await repository.upsert(newTask);
    final task = upsertResult.valueOrNull!;

    for (final s in scheduler.scheduled.toList()) {
      await scheduler.cancel(s.id);
    }

    // 3. Change clock to 12/03 to simulate late completion
    clock.setTo(DateTime.utc(2026, 3, 12, 10, 0));

    // 4. Concluir a tarefa em 12/03
    final completeResult = await repository.complete(task.id);
    expect(completeResult.isOk, isTrue);

    // 5. Verify pending occurrence
    final pendingResult = await taskDao.dirtySince(null);
    final pendingTasks = pendingResult.valueOrNull!
        .where((t) => !t.isCompleted)
        .toList();
    expect(pendingTasks.length, 1);

    final nextTask = pendingTasks.first;
    expect(nextTask.title, 'Pagar condomínio');
    // CA-1.2: Next must be 10/04 (not 12/04)
    expect(nextTask.dueAt, DateTime.utc(2026, 4, 10));

    // 6. Verificar agendamento
    expect(scheduler.scheduled.length, 1);
    expect(scheduler.scheduled.first.id, 'task_${nextTask.id}');
  });
}
