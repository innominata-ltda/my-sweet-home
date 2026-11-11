import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';

/// In-memory fake of [TaskFromPresetPort] for tests.
class FakeTaskFromPreset implements TaskFromPresetPort {
  FakeTaskFromPreset({this.shouldFail = false, Set<String>? activeIds})
    : activeIds = activeIds ?? <String>{};

  bool shouldFail;
  final Set<String> activeIds;
  final List<CreatedTask> created = [];
  final List<TaskDraft> receivedDrafts = [];
  final List<TrashTicket> undoneTickets = [];
  int _counter = 1;

  factory FakeTaskFromPreset.failing() {
    return FakeTaskFromPreset(shouldFail: true);
  }

  @override
  Future<Result<CreatedTask, Failure>> create(TaskDraft draft) async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Fake task from preset failure'));
    }
    receivedDrafts.add(draft);
    final task = CreatedTask(
      id: 'fake_task_${_counter++}',
      title: draft.title,
      firstOccurrence: draft.firstOccurrence,
      sourcePresetId: draft.sourcePresetId,
      rrule: draft.rrule,
    );
    created.add(task);
    if (draft.sourcePresetId != null) {
      activeIds.add(draft.sourcePresetId!);
    }
    return Ok(task);
  }

  @override
  Future<Result<List<CreatedTask>, Failure>> createBatch(
    List<TaskDraft> drafts,
  ) async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Fake batch failure'));
    }
    final results = <CreatedTask>[];
    for (final d in drafts) {
      final res = await create(d);
      if (res.isErr) return Err(res.failureOrNull!);
      results.add(res.valueOrNull!);
    }
    return Ok(results);
  }

  @override
  Future<Result<void, Failure>> undoBatch(List<TrashTicket> tickets) async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Fake undo failure'));
    }
    undoneTickets.addAll(tickets);
    for (final ticket in tickets) {
      created.removeWhere((t) => t.id == ticket.id);
    }
    return const Ok(null);
  }

  @override
  Future<Result<Set<String>, Failure>> activeOriginPresetIds() async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Fake active origins failure'));
    }
    return Ok(Set<String>.from(activeIds));
  }
}
