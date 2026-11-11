import 'package:my_sweet_home/core/result/result.dart';

typedef TaskId = String;

enum SyncState { synced, dirty, conflict }

class TaskCategory {
  final String id;
  final String name;
  final String iconKey;
  final String? colorHex;
  final bool isSystem;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    this.colorHex,
    required this.isSystem,
  });
}

class Task {
  final TaskId id;
  final String title;
  final String? notes;
  final TaskCategory? category;
  final DateTime? dueAt;
  final bool allDay;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? recurringRuleId;

  final String? remoteEventId;
  final String? remoteEtag;
  final SyncState syncState;
  final String? sourcePresetId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.title,
    this.notes,
    this.category,
    this.dueAt,
    required this.allDay,
    required this.isCompleted,
    this.completedAt,
    this.recurringRuleId,
    this.remoteEventId,
    this.remoteEtag,
    required this.syncState,
    this.sourcePresetId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Task copyWith({
    String? title,
    String? notes,
    TaskCategory? category,
    DateTime? dueAt,
    bool? allDay,
    bool? isCompleted,
    DateTime? completedAt,
    String? recurringRuleId,
    String? remoteEventId,
    String? remoteEtag,
    SyncState? syncState,
    String? sourcePresetId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      dueAt: dueAt ?? this.dueAt,
      allDay: allDay ?? this.allDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      remoteEventId: remoteEventId ?? this.remoteEventId,
      remoteEtag: remoteEtag ?? this.remoteEtag,
      syncState: syncState ?? this.syncState,
      sourcePresetId: sourcePresetId ?? this.sourcePresetId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class NewTask {
  final String title;
  final String? notes;
  final String? categoryId;
  final DateTime? dueAt;
  final bool allDay;
  final String? recurringRuleId;
  final String? sourcePresetId;

  const NewTask({
    required this.title,
    this.notes,
    this.categoryId,
    this.dueAt,
    required this.allDay,
    this.recurringRuleId,
    this.sourcePresetId,
  });
}

class RemoteEvent {
  final String id;
  final String etag;
  final DateTime updatedAt;
  final String? summary;
  final String? description;
  final DateTime? start;
  final bool allDay;
  final String? status; // 'confirmed', 'cancelled'

  const RemoteEvent({
    required this.id,
    required this.etag,
    required this.updatedAt,
    this.summary,
    this.description,
    this.start,
    required this.allDay,
    this.status,
  });
}

class Conflict {
  final Task local;
  final RemoteEvent remote;

  const Conflict(this.local, this.remote);
}

class SyncPlan {
  final List<Task> toPush;
  final List<RemoteEvent> toPull;
  final List<TaskId> toDeleteLocal;
  final List<Conflict> conflicts;
  final List<TaskId> unchanged;

  const SyncPlan({
    this.toPush = const [],
    this.toPull = const [],
    this.toDeleteLocal = const [],
    this.conflicts = const [],
    this.unchanged = const [],
  });
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

final class CalendarFailure extends Failure {
  final String message;
  final bool isNetworkError;

  const CalendarFailure(this.message, {this.isNetworkError = false});
}

class TaskEvent {
  final TaskId taskId;
  final String title;
  final String? description;
  final DateTime? start;
  final bool allDay;
  final String? remoteEventId;
  final String? remoteEtag;
  final bool isDeleted;

  const TaskEvent({
    required this.taskId,
    required this.title,
    this.description,
    this.start,
    required this.allDay,
    this.remoteEventId,
    this.remoteEtag,
    this.isDeleted = false,
  });

  factory TaskEvent.fromTask(Task task) {
    return TaskEvent(
      taskId: task.id,
      title: task.title,
      description: task.notes,
      start: task.dueAt,
      allDay: task.allDay,
      remoteEventId: task.remoteEventId,
      remoteEtag: task.remoteEtag,
      isDeleted: task.isDeleted,
    );
  }
}

class RemoteSnapshot {
  final List<RemoteEvent> events;
  final DateTime snapshotAt;

  const RemoteSnapshot({required this.events, required this.snapshotAt});
}

class SyncReport {
  final int pushedCount;
  final int pulledCount;
  final int deletedCount;
  final int conflictCount;

  const SyncReport({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.deletedCount = 0,
    this.conflictCount = 0,
  });
}
