import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';

/// Tarefa criada a partir de um rascunho.
final class CreatedTask {
  const CreatedTask({
    required this.id,
    required this.title,
    required this.firstOccurrence,
    this.sourcePresetId,
    this.rrule,
  });

  final String id;
  final String title;
  final DateTime firstOccurrence;
  final String? sourcePresetId;
  final String? rrule;
}

/// Port for saving regular tasks created from presets (SPEC-014).
/// Does not import `features/tasks`.
abstract interface class TaskFromPresetPort {
  Future<Result<CreatedTask, Failure>> create(TaskDraft draft);
  Future<Result<List<CreatedTask>, Failure>> createBatch(
    List<TaskDraft> drafts,
  );
  Future<Result<void, Failure>> undoBatch(List<TrashTicket> tickets);

  /// Presets with at least one active task (not deleted; definitive completion =
  /// without next occurrence and is_completed). Used by RN-357 / RN-366.
  Future<Result<Set<String>, Failure>> activeOriginPresetIds();
}
