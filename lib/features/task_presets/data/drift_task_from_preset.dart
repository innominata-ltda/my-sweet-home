import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Task, Category;
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';

/// Drift implementation of [TaskFromPresetPort] (SPEC-014).
/// Grava tarefas no [AppDatabase] sem importar `features/tasks`.
class DriftTaskFromPreset implements TaskFromPresetPort {
  DriftTaskFromPreset({
    required this.db,
    required this.clock,
    required this.idGenerator,
    required this.trashPolicy,
  });

  final AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;
  final TrashPolicy trashPolicy;

  static const defaultCategoryId = 'cat_home';

  Future<void> _ensureDefaultCategory() async {
    final existing = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(defaultCategoryId))).getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: defaultCategoryId,
              name: 'Casa',
              kind: 'task',
              iconKey: 'home',
              isSystem: const Value(true),
            ),
          );
    }
  }

  @override
  Future<Result<CreatedTask, Failure>> create(TaskDraft draft) async {
    try {
      await _ensureDefaultCategory();
      return await db.transaction(() async {
        final now = clock.nowUtc().toIso8601String();
        final categoryId = draft.categoryId ?? defaultCategoryId;

        String? ruleId;
        if (draft.rrule != null && draft.rrule!.isNotEmpty) {
          ruleId = idGenerator.newId();
          await db
              .into(db.recurringRules)
              .insert(
                RecurringRulesCompanion.insert(
                  id: ruleId,
                  kind: 'task',
                  rrule: draft.rrule!,
                  startsOn: draft.firstOccurrence.toIso8601String(),
                  title: draft.title,
                ),
              );
        }

        final taskId = idGenerator.newId();
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: taskId,
                title: draft.title,
                categoryId: Value(categoryId),
                dueAt: Value(draft.firstOccurrence.toIso8601String()),
                allDay: Value(draft.allDay),
                isCompleted: const Value(false),
                recurringRuleId: Value(ruleId),
                sourcePresetId: Value(draft.sourcePresetId),
                syncState: const Value('dirty'),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        return Ok(
          CreatedTask(
            id: taskId,
            title: draft.title,
            firstOccurrence: draft.firstOccurrence,
            sourcePresetId: draft.sourcePresetId,
            rrule: draft.rrule,
          ),
        );
      });
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao criar tarefa a partir de predefinição: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<CreatedTask>, Failure>> createBatch(
    List<TaskDraft> drafts,
  ) async {
    try {
      await _ensureDefaultCategory();
      return await db.transaction(() async {
        final results = <CreatedTask>[];
        for (final draft in drafts) {
          final res = await create(draft);
          if (res.isErr) {
            throw res.failureOrNull!;
          }
          results.add(res.valueOrNull!);
        }
        return Ok(results);
      });
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao criar lote de tarefas: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> undoBatch(List<TrashTicket> tickets) async {
    try {
      await db.transaction(() async {
        for (final ticket in tickets) {
          final task = await (db.select(
            db.tasks,
          )..where((t) => t.id.equals(ticket.id))).getSingleOrNull();
          if (task != null) {
            await (db.delete(
              db.tasks,
            )..where((t) => t.id.equals(ticket.id))).go();
            if (task.recurringRuleId != null) {
              await (db.delete(
                db.recurringRules,
              )..where((r) => r.id.equals(task.recurringRuleId!))).go();
            }
          }
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao desfazer lote de tarefas: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<Set<String>, Failure>> activeOriginPresetIds() async {
    try {
      final rows =
          await (db.select(db.tasks)..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.sourcePresetId.isNotNull() &
                    (t.isCompleted.equals(false) |
                        t.recurringRuleId.isNotNull()),
              ))
              .get();

      final ids = rows.map((r) => r.sourcePresetId).whereType<String>().toSet();

      return Ok(ids);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao consultar origens de predefinições ativas: $e',
          cause: e,
        ),
      );
    }
  }
}
