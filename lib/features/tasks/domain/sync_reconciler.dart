import 'models.dart';

abstract interface class SyncReconciler {
  SyncPlan reconcile({
    required List<Task> local,
    required RemoteSnapshot remote,
    required DateTime? lastSyncAt,
  });
}

class DefaultSyncReconciler implements SyncReconciler {
  const DefaultSyncReconciler();

  @override
  SyncPlan reconcile({
    required List<Task> local,
    required RemoteSnapshot remote,
    required DateTime? lastSyncAt,
  }) {
    final toPush = <Task>[];
    final toPull = <RemoteEvent>[];
    final toDeleteLocal = <TaskId>[];
    final conflicts = <Conflict>[];
    final unchanged = <TaskId>[];

    final remoteMap = <String, RemoteEvent>{};
    for (final event in remote.events) {
      remoteMap[event.id] = event;
    }

    final processedRemoteIds = <String>{};

    for (final task in local) {
      if (task.remoteEventId == null) {
        if (!task.isDeleted) {
          toPush.add(task);
        } else {
          toDeleteLocal.add(task.id);
        }
        continue;
      }

      final remoteId = task.remoteEventId!;
      processedRemoteIds.add(remoteId);
      final remoteEvent = remoteMap[remoteId];

      if (remoteEvent == null) {
        // When remoteEvent is null, during incremental sync (lastSyncAt != null)
        // it means the event was NOT modified on the remote side since lastSyncAt.
        // It does NOT mean it was deleted.
        if (lastSyncAt != null) {
          if (task.isDeleted) {
            toPush.add(task);
          } else if (_wasLocalModified(task, lastSyncAt)) {
            toPush.add(task);
          } else {
            unchanged.add(task.id);
          }
        } else {
          // Full sync (lastSyncAt == null)
          if (task.isDeleted) {
            toDeleteLocal.add(task.id);
          } else if (_wasLocalModified(task, null)) {
            conflicts.add(
              Conflict(
                task,
                RemoteEvent(
                  id: remoteId,
                  etag: task.remoteEtag ?? '',
                  updatedAt: task.updatedAt,
                  status: 'cancelled',
                  allDay: task.allDay,
                ),
              ),
            );
          } else {
            toDeleteLocal.add(task.id);
          }
        }
        continue;
      }

      if (remoteEvent.status == 'cancelled') {
        if (task.isDeleted) {
          toDeleteLocal.add(task.id);
        } else if (_wasLocalModified(task, lastSyncAt)) {
          conflicts.add(Conflict(task, remoteEvent));
        } else {
          toDeleteLocal.add(task.id);
        }
        continue;
      }

      final localModified = _wasLocalModified(task, lastSyncAt);
      final remoteModified = _wasRemoteModified(remoteEvent, task, lastSyncAt);

      if (task.isDeleted) {
        if (remoteModified) {
          conflicts.add(Conflict(task, remoteEvent));
        } else {
          toPush.add(task);
        }
      } else if (localModified && remoteModified) {
        if (_areTaskAndRemoteEquivalent(task, remoteEvent)) {
          unchanged.add(task.id);
        } else {
          conflicts.add(Conflict(task, remoteEvent));
        }
      } else if (localModified) {
        toPush.add(task);
      } else if (remoteModified) {
        toPull.add(remoteEvent);
      } else {
        unchanged.add(task.id);
      }
    }

    for (final remoteEvent in remote.events) {
      if (!processedRemoteIds.contains(remoteEvent.id)) {
        if (remoteEvent.status != 'cancelled') {
          toPull.add(remoteEvent);
        }
      }
    }

    return SyncPlan(
      toPush: toPush,
      toPull: toPull,
      toDeleteLocal: toDeleteLocal,
      conflicts: conflicts,
      unchanged: unchanged,
    );
  }

  bool _wasLocalModified(Task task, DateTime? lastSyncAt) {
    if (task.syncState == SyncState.dirty) return true;
    if (lastSyncAt == null) return false;
    return task.updatedAt.isAfter(lastSyncAt);
  }

  bool _wasRemoteModified(RemoteEvent remote, Task task, DateTime? lastSyncAt) {
    if (remote.etag != task.remoteEtag) return true;
    if (lastSyncAt == null) return false;
    return remote.updatedAt.isAfter(lastSyncAt);
  }

  bool _areTaskAndRemoteEquivalent(Task task, RemoteEvent remote) {
    return task.title == (remote.summary ?? '') &&
        task.notes == remote.description &&
        task.dueAt == remote.start &&
        task.allDay == remote.allDay;
  }
}
