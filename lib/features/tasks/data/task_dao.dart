import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task, Category;
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/next_occurrence_policy.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

class TaskDao implements TaskRepository {
  final AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;
  final TrashPolicy trashPolicy;
  final NextOccurrencePolicy nextOccurrencePolicy;
  final DeterministicIdGenerator deterministicIdGen;

  TaskDao({
    required this.db,
    required this.clock,
    required this.idGenerator,
    required this.trashPolicy,
    this.nextOccurrencePolicy = const DefaultNextOccurrencePolicy(),
    this.deterministicIdGen = const UuidV5DeterministicIdGenerator(),
  });

  SyncState _parseSyncState(String? state) {
    switch (state) {
      case 'dirty':
        return SyncState.dirty;
      case 'conflict':
        return SyncState.conflict;
      default:
        return SyncState.synced;
    }
  }

  Task _mapTask(TypedResult row) {
    final taskRow = row.readTable(db.tasks);
    final categoryRow = row.readTableOrNull(db.categories);

    TaskCategory? category;
    if (categoryRow != null) {
      category = TaskCategory(
        id: categoryRow.id,
        name: categoryRow.name,
        iconKey: categoryRow.iconKey,
        colorHex: categoryRow.colorHex,
        isSystem: categoryRow.isSystem,
      );
    }

    return Task(
      id: taskRow.id,
      title: taskRow.title,
      notes: taskRow.notes,
      category: category,
      dueAt: taskRow.dueAt != null
          ? DateTime.parse(taskRow.dueAt!).toUtc()
          : null,
      allDay: taskRow.allDay,
      isCompleted: taskRow.isCompleted,
      completedAt: taskRow.completedAt != null
          ? DateTime.parse(taskRow.completedAt!).toUtc()
          : null,
      recurringRuleId: taskRow.recurringRuleId,
      remoteEventId: taskRow.remoteEventId,
      remoteEtag: taskRow.remoteEtag,
      syncState: _parseSyncState(taskRow.syncState),
      sourcePresetId: taskRow.sourcePresetId,
      createdAt: taskRow.createdAt != null
          ? DateTime.parse(taskRow.createdAt!).toUtc()
          : (taskRow.dueAt != null
                ? DateTime.parse(taskRow.dueAt!).toUtc()
                : clock.nowUtc()),
      updatedAt: taskRow.updatedAt != null
          ? DateTime.parse(taskRow.updatedAt!).toUtc()
          : clock.nowUtc(),
      deletedAt: taskRow.deletedAt != null
          ? DateTime.parse(taskRow.deletedAt!).toUtc()
          : null,
    );
  }

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    try {
      final now = clock.nowUtc().toIso8601String();
      final id = idGenerator.newId();

      String? ruleId = t.recurringRuleId;
      if (ruleId != null && ruleId.isNotEmpty) {
        final existing = await (db.select(
          db.recurringRules,
        )..where((r) => r.id.equals(ruleId!))).getSingleOrNull();
        if (existing == null) {
          final newRuleId = idGenerator.newId();
          await db
              .into(db.recurringRules)
              .insert(
                RecurringRulesCompanion.insert(
                  id: newRuleId,
                  kind: 'task',
                  rrule: ruleId,
                  startsOn: (t.dueAt ?? clock.nowUtc()).toIso8601String(),
                  title: t.title,
                ),
              );
          ruleId = newRuleId;
        }
      }

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: id,
              title: t.title,
              notes: Value(t.notes),
              categoryId: Value(t.categoryId),
              dueAt: Value(t.dueAt?.toUtc().toIso8601String()),
              allDay: Value(t.allDay),
              isCompleted: const Value(false),
              recurringRuleId: Value(ruleId),
              syncState: const Value('dirty'),
              sourcePresetId: Value(t.sourcePresetId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      return await _getTask(id);
    } catch (e) {
      return Err(StorageFailure(detail: 'Error upserting task', cause: e));
    }
  }

  Future<Result<Task, Failure>> _getTask(String id) async {
    try {
      final query = db.select(db.tasks).join([
        leftOuterJoin(
          db.categories,
          db.categories.id.equalsExp(db.tasks.categoryId),
        ),
      ])..where(db.tasks.id.equals(id));

      final row = await query.getSingleOrNull();
      if (row == null) {
        return Err(NotFoundFailure(what: 'Task $id'));
      }
      return Ok(_mapTask(row));
    } catch (e) {
      return Err(StorageFailure(detail: 'Error getting task $id', cause: e));
    }
  }

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    try {
      return await db.transaction(() async {
        final query = db.select(db.tasks).join([
          leftOuterJoin(
            db.categories,
            db.categories.id.equalsExp(db.tasks.categoryId),
          ),
        ])..where(db.tasks.id.equals(id));

        final row = await query.getSingleOrNull();
        if (row == null) {
          return Err(NotFoundFailure(what: 'Task $id'));
        }

        final task = _mapTask(row);

        final now = clock.nowUtc();
        final nowIso = now.toIso8601String();

        await db
            .update(db.tasks)
            .replace(
              TasksCompanion(
                id: Value(task.id),
                title: Value(task.title),
                notes: Value(task.notes),
                categoryId: Value(task.category?.id),
                dueAt: Value(task.dueAt?.toUtc().toIso8601String()),
                allDay: Value(task.allDay),
                isCompleted: const Value(true),
                completedAt: Value(nowIso),
                recurringRuleId: Value(task.recurringRuleId),
                remoteEventId: Value(task.remoteEventId),
                remoteEtag: Value(task.remoteEtag),
                syncState: const Value('dirty'),
                sourcePresetId: Value(task.sourcePresetId),
                createdAt: Value(task.createdAt.toIso8601String()),
                updatedAt: Value(nowIso),
                deletedAt: Value(task.deletedAt?.toIso8601String()),
              ),
            );

        if (task.recurringRuleId != null && task.dueAt != null) {
          final ruleQuery = db.select(db.recurringRules)
            ..where((r) => r.id.equals(task.recurringRuleId!));
          final ruleRow = await ruleQuery.getSingleOrNull();
          if (ruleRow != null) {
            final rule = RecurrenceRule.tryParse(
              ruleRow.rrule,
              dtStart: task.dueAt,
            );
            if (rule != null) {
              final nextDate = nextOccurrencePolicy.next(
                rule: rule,
                scheduledFor: task.dueAt!,
                completedAt: now,
              );
              if (nextDate != null) {
                final dateIso = nextDate.toUtc().toIso8601String().substring(
                  0,
                  10,
                );
                final newId = deterministicIdGen.forOccurrence(
                  task.recurringRuleId!,
                  dateIso,
                );
                await db
                    .into(db.tasks)
                    .insert(
                      TasksCompanion.insert(
                        id: newId,
                        title: task.title,
                        notes: Value(task.notes),
                        categoryId: Value(task.category?.id),
                        dueAt: Value(nextDate.toUtc().toIso8601String()),
                        allDay: Value(task.allDay),
                        isCompleted: const Value(false),
                        recurringRuleId: Value(task.recurringRuleId),
                        syncState: const Value('dirty'),
                        sourcePresetId: Value(task.sourcePresetId),
                        createdAt: Value(nowIso),
                        updatedAt: Value(nowIso),
                      ),
                      mode: InsertMode.insertOrIgnore,
                    );
              }
            }
          }
        }

        return await _getTask(id);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Error completing task', cause: e));
    }
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    try {
      return await db.transaction(() async {
        final query = db.select(db.tasks).join([
          leftOuterJoin(
            db.categories,
            db.categories.id.equalsExp(db.tasks.categoryId),
          ),
        ])..where(db.tasks.id.equals(id));

        final row = await query.getSingleOrNull();
        if (row == null) {
          return Err(NotFoundFailure(what: 'Task $id'));
        }

        final task = _mapTask(row);
        final now = clock.nowUtc();
        final nowIso = now.toIso8601String();

        await db
            .update(db.tasks)
            .replace(
              TasksCompanion(
                id: Value(task.id),
                title: Value(task.title),
                notes: Value(task.notes),
                categoryId: Value(task.category?.id),
                dueAt: Value(task.dueAt?.toUtc().toIso8601String()),
                allDay: Value(task.allDay),
                isCompleted: const Value(false),
                completedAt: const Value(null),
                recurringRuleId: Value(task.recurringRuleId),
                remoteEventId: Value(task.remoteEventId),
                remoteEtag: Value(task.remoteEtag),
                syncState: const Value('dirty'),
                sourcePresetId: Value(task.sourcePresetId),
                createdAt: Value(task.createdAt.toIso8601String()),
                updatedAt: Value(nowIso),
                deletedAt: Value(task.deletedAt?.toIso8601String()),
              ),
            );

        return await _getTask(id);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Error uncompleting task', cause: e));
    }
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    try {
      return await db.transaction(() async {
        final query = db.select(db.tasks)..where((t) => t.id.equals(id));
        final row = await query.getSingleOrNull();
        if (row == null) {
          return Err(NotFoundFailure(what: 'Task $id'));
        }

        final now = clock.nowUtc().toIso8601String();

        if (alsoRemote) {
          // Mark as dirty to synchronize deletion
          await db
              .update(db.tasks)
              .replace(
                TasksCompanion(
                  id: Value(row.id),
                  title: Value(row.title),
                  notes: Value(row.notes),
                  categoryId: Value(row.categoryId),
                  dueAt: Value(row.dueAt),
                  allDay: Value(row.allDay),
                  isCompleted: Value(row.isCompleted),
                  completedAt: Value(row.completedAt),
                  recurringRuleId: Value(row.recurringRuleId),
                  remoteEventId: Value(row.remoteEventId),
                  remoteEtag: Value(row.remoteEtag),
                  syncState: const Value('dirty'),
                  sourcePresetId: Value(row.sourcePresetId),
                  createdAt: Value(row.createdAt),
                  updatedAt: Value(now),
                  deletedAt: Value(row.deletedAt),
                ),
              );
        }

        final result = await trashPolicy.softDelete('tasks', id);
        return result;
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Error removing task', cause: e));
    }
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async {
    try {
      final startIso = r.start.toIso8601String();
      final endIso = r.end.toIso8601String();

      final query =
          db.select(db.tasks).join([
            leftOuterJoin(
              db.categories,
              db.categories.id.equalsExp(db.tasks.categoryId),
            ),
          ])..where(
            db.tasks.deletedAt.isNull() &
                db.tasks.dueAt.isBetweenValues(startIso, endIso),
          );

      final rows = await query.get();
      return Ok(rows.map(_mapTask).toList());
    } catch (e) {
      return Err(StorageFailure(detail: 'Error querying tasks', cause: e));
    }
  }

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async {
    try {
      final query = db.select(db.tasks).join([
        leftOuterJoin(
          db.categories,
          db.categories.id.equalsExp(db.tasks.categoryId),
        ),
      ])..where(db.tasks.deletedAt.isNull() & db.tasks.dueAt.isNull());

      final rows = await query.get();
      return Ok(rows.map(_mapTask).toList());
    } catch (e) {
      return Err(StorageFailure(detail: 'Error querying tasks', cause: e));
    }
  }

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async {
    try {
      var whereClause = db.tasks.syncState.equals('dirty');
      if (mark != null) {
        final markIso = mark.toIso8601String();
        whereClause =
            whereClause & db.tasks.updatedAt.isBiggerOrEqualValue(markIso);
      }

      final query = db.select(db.tasks).join([
        leftOuterJoin(
          db.categories,
          db.categories.id.equalsExp(db.tasks.categoryId),
        ),
      ])..where(whereClause);

      final rows = await query.get();
      return Ok(rows.map(_mapTask).toList());
    } catch (e) {
      return Err(StorageFailure(detail: 'Error querying tasks', cause: e));
    }
  }

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async {
    try {
      final query = db.select(db.tasks).join([
        leftOuterJoin(
          db.categories,
          db.categories.id.equalsExp(db.tasks.categoryId),
        ),
      ]);
      final rows = await query.get();
      return Ok(rows.map(_mapTask).toList());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Error getting tasks for sync', cause: e),
      );
    }
  }

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async {
    try {
      final syncStateStr = task.syncState.name;
      await db
          .into(db.tasks)
          .insertOnConflictUpdate(
            TasksCompanion(
              id: Value(task.id),
              title: Value(task.title),
              notes: Value(task.notes),
              categoryId: Value(task.category?.id),
              dueAt: Value(task.dueAt?.toUtc().toIso8601String()),
              allDay: Value(task.allDay),
              isCompleted: Value(task.isCompleted),
              completedAt: Value(task.completedAt?.toUtc().toIso8601String()),
              recurringRuleId: Value(task.recurringRuleId),
              remoteEventId: Value(task.remoteEventId),
              remoteEtag: Value(task.remoteEtag),
              syncState: Value(syncStateStr),
              sourcePresetId: Value(task.sourcePresetId),
              createdAt: Value(task.createdAt.toUtc().toIso8601String()),
              updatedAt: Value(task.updatedAt.toUtc().toIso8601String()),
              deletedAt: Value(task.deletedAt?.toUtc().toIso8601String()),
            ),
          );
      return await _getTask(task.id);
    } catch (e) {
      return Err(StorageFailure(detail: 'Error saving synced task', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async {
    try {
      await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Error deleting local task $id', cause: e),
      );
    }
  }
}
