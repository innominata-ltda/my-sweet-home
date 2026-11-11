import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task, Category;
import 'package:my_sweet_home/features/tasks/data/task_dao.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late Clock clock;
  late IdGenerator idGenerator;
  late TrashPolicy trashPolicy;

  setUp(() async {
    db = AppDatabase.memory();
    clock = SystemClock();
    idGenerator = const UuidV7Generator();
    trashPolicy = DriftTrashPolicy.system(db: db);

    taskDao = TaskDao(
      db: db,
      clock: clock,
      idGenerator: idGenerator,
      trashPolicy: trashPolicy,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert creates a new task', () async {
    final newTask = NewTask(
      title: 'Comprar pão',
      notes: 'Pão francês',
      allDay: true,
      dueAt: clock.nowUtc(),
    );

    final result = await taskDao.upsert(newTask);
    expect(result.isOk, isTrue);

    final task = result.valueOrNull!;
    expect(task.title, 'Comprar pão');
    expect(task.notes, 'Pão francês');
    expect(task.allDay, isTrue);
    expect(task.isCompleted, isFalse);
    expect(task.syncState, SyncState.dirty);
  });

  test('complete marks task as completed', () async {
    final newTask = NewTask(title: 'Comprar pão', allDay: true);

    final result1 = await taskDao.upsert(newTask);
    final task1 = result1.valueOrNull!;

    final result2 = await taskDao.complete(task1.id);
    expect(result2.isOk, isTrue);

    final task2 = result2.valueOrNull!;
    expect(task2.isCompleted, isTrue);
    expect(task2.completedAt, isNotNull);
    expect(task2.syncState, SyncState.dirty);
  });

  test('remove logical deletes task', () async {
    final newTask = NewTask(title: 'Comprar pão', allDay: true);

    final result1 = await taskDao.upsert(newTask);
    final task1 = result1.valueOrNull!;

    final result2 = await taskDao.remove(task1.id, alsoRemote: true);
    expect(result2.isOk, isTrue);

    // Test if it's no longer in withoutDueDate
    final result3 = await taskDao.withoutDueDate();
    final tasks = result3.valueOrNull!;
    expect(tasks.where((t) => t.id == task1.id).isEmpty, isTrue);
  });

  test('complete recurring task generates next occurrence', () async {
    final now = clock.nowUtc();
    final ruleId = idGenerator.newId();
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: ruleId,
            kind: 'task',
            rrule: 'FREQ=DAILY;INTERVAL=1',
            startsOn: now.toIso8601String(),
            title: 'Tomar ritalina',
          ),
        );

    final newTask = NewTask(
      title: 'Tomar ritalina',
      allDay: true,
      dueAt: now,
      recurringRuleId: ruleId,
    );

    final result1 = await taskDao.upsert(newTask);
    final task1 = result1.valueOrNull!;

    final result2 = await taskDao.complete(task1.id);
    expect(result2.isOk, isTrue);

    final completedTask = result2.valueOrNull!;
    expect(completedTask.isCompleted, isTrue);

    // Check if a new task was generated
    final pendingResult = await taskDao.dirtySince(null);
    final pendingTasks = pendingResult.valueOrNull!
        .where((t) => !t.isCompleted)
        .toList();

    expect(pendingTasks.length, 1);
    final nextTask = pendingTasks.first;
    expect(nextTask.title, 'Tomar ritalina');
    expect(nextTask.recurringRuleId, ruleId);
    expect(
      nextTask.dueAt!.day,
      now.add(const Duration(days: 1)).day,
    ); // approx check
  });

  test('uncomplete reverses completed state', () async {
    final newTask = NewTask(title: 'Lavar louça', allDay: true);
    final created = (await taskDao.upsert(newTask)).valueOrNull!;

    await taskDao.complete(created.id);
    final uncompletedResult = await taskDao.uncomplete(created.id);
    expect(uncompletedResult.isOk, isTrue);

    final task = uncompletedResult.valueOrNull!;
    expect(task.isCompleted, isFalse);
    expect(task.completedAt, isNull);
    expect(task.syncState, SyncState.dirty);

    final notFound = await taskDao.uncomplete('missing_id');
    expect(notFound.isErr, isTrue);
  });

  test('complete and remove handle not found task', () async {
    final notFoundComplete = await taskDao.complete('missing_id');
    expect(notFoundComplete.isErr, isTrue);

    final notFoundRemove = await taskDao.remove(
      'missing_id',
      alsoRemote: false,
    );
    expect(notFoundRemove.isErr, isTrue);
  });

  test('inRange and dirtySince filter tasks correctly', () async {
    final now = clock.nowUtc();
    final task1 = (await taskDao.upsert(
      NewTask(title: 'Hoje', dueAt: now, allDay: true),
    )).valueOrNull!;

    final task2 = (await taskDao.upsert(
      NewTask(
        title: 'Mês que vem',
        dueAt: now.add(const Duration(days: 30)),
        allDay: true,
      ),
    )).valueOrNull!;

    final range = DateTimeRange(
      start: now.subtract(const Duration(days: 1)),
      end: now.add(const Duration(days: 2)),
    );
    final inRangeResult = await taskDao.inRange(range);
    expect(inRangeResult.isOk, isTrue);
    final tasksInRange = inRangeResult.valueOrNull!;
    expect(tasksInRange.any((t) => t.id == task1.id), isTrue);
    expect(tasksInRange.any((t) => t.id == task2.id), isFalse);

    final dirtyResult = await taskDao.dirtySince(
      now.subtract(const Duration(hours: 1)),
    );
    expect(dirtyResult.isOk, isTrue);
    expect(dirtyResult.valueOrNull!, isNotEmpty);
  });

  test('allTasksForSync, saveSyncedTask and deleteLocalPermanently', () async {
    final now = clock.nowUtc();
    final task = Task(
      id: 'synced-1',
      title: 'Synced Task',
      notes: 'Notes',
      dueAt: now,
      allDay: true,
      isCompleted: false,
      completedAt: null,
      syncState: SyncState.conflict,
      createdAt: now,
      updatedAt: now,
    );

    final saveResult = await taskDao.saveSyncedTask(task);
    expect(saveResult.isOk, isTrue);
    expect(saveResult.valueOrNull!.syncState, SyncState.conflict);

    final allSync = await taskDao.allTasksForSync();
    expect(allSync.isOk, isTrue);
    expect(allSync.valueOrNull!.any((t) => t.id == 'synced-1'), isTrue);

    final deleteResult = await taskDao.deleteLocalPermanently('synced-1');
    expect(deleteResult.isOk, isTrue);

    final afterDelete = await taskDao.allTasksForSync();
    expect(afterDelete.valueOrNull!.any((t) => t.id == 'synced-1'), isFalse);
  });

  test('upsert supports category and notes', () async {
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat_work',
            name: 'Work',
            kind: 'task',
            iconKey: 'work',
          ),
        );

    final created = (await taskDao.upsert(
      NewTask(
        title: 'Initial',
        notes: 'Initial notes',
        categoryId: 'cat_work',
        allDay: true,
      ),
    )).valueOrNull!;
    expect(created.category?.name, 'Work');
    expect(created.notes, 'Initial notes');
  });

  test(
    'upsert and recurrence preserve sourcePresetId (SPEC-014 T-I01)',
    () async {
      final now = clock.nowUtc();
      final ruleId = idGenerator.newId();
      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: ruleId,
              kind: 'task',
              rrule: 'FREQ=DAILY;INTERVAL=7',
              startsOn: now.toIso8601String(),
              title: 'Lavar roupa',
            ),
          );

      final created = (await taskDao.upsert(
        NewTask(
          title: 'Lavar roupa',
          dueAt: now,
          allDay: true,
          recurringRuleId: ruleId,
          sourcePresetId: 'wash-clothes',
        ),
      )).valueOrNull!;

      expect(created.sourcePresetId, 'wash-clothes');

      // Complete task and verify next occurrence preserves sourcePresetId
      final completedResult = await taskDao.complete(created.id);
      expect(completedResult.isOk, isTrue);
      expect(completedResult.valueOrNull!.sourcePresetId, 'wash-clothes');

      final pending = (await taskDao.dirtySince(null)).valueOrNull!
          .where((t) => !t.isCompleted)
          .toList();
      expect(pending.length, 1);
      expect(pending.first.sourcePresetId, 'wash-clothes');
    },
  );
}
