import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';

import 'calendar_gateway_port.dart';
import 'models.dart';
import 'repositories.dart';

import 'conflict_resolution_port.dart';

abstract interface class SyncExecutor {
  Future<Result<SyncReport, Failure>> apply(SyncPlan plan);
}

class DefaultSyncExecutor implements SyncExecutor {
  final CalendarGatewayPort gateway;
  final TaskRepository repository;
  final IdGenerator idGenerator;
  final Clock clock;
  final ConflictResolutionPort? conflictResolver;

  DefaultSyncExecutor({
    required this.gateway,
    required this.repository,
    required this.idGenerator,
    required this.clock,
    this.conflictResolver,
  });

  @override
  Future<Result<SyncReport, Failure>> apply(SyncPlan plan) async {
    int pushed = 0;
    int pulled = 0;
    int deleted = 0;
    int conflictCount = 0;

    // 1. Process conflicts (resolves with user choice or marks as conflict - RN-156, CA-3.2)
    for (final conflict in plan.conflicts) {
      if (conflictResolver != null) {
        final choiceRes = await conflictResolver!.resolve(conflict);
        if (choiceRes.isOk) {
          final choice = choiceRes.valueOrNull!;
          if (choice == ConflictChoice.keepLocal) {
            final taskEvent = TaskEvent.fromTask(conflict.local);
            final pushRes = await gateway.push(taskEvent);
            if (pushRes.isOk) {
              final remoteEvent = pushRes.valueOrNull!;
              await repository.saveSyncedTask(
                conflict.local.copyWith(
                  remoteEventId: remoteEvent.id,
                  remoteEtag: remoteEvent.etag,
                  syncState: SyncState.synced,
                  updatedAt: clock.nowUtc(),
                ),
              );
              pushed++;
            }
          } else if (choice == ConflictChoice.keepRemote) {
            final remoteEvent = conflict.remote;
            await repository.saveSyncedTask(
              conflict.local.copyWith(
                title: remoteEvent.summary ?? conflict.local.title,
                notes: remoteEvent.description,
                dueAt: remoteEvent.start,
                allDay: remoteEvent.allDay,
                remoteEtag: remoteEvent.etag,
                syncState: SyncState.synced,
                updatedAt: clock.nowUtc(),
              ),
            );
            pulled++;
          }
          conflictCount++;
          continue;
        }
      }

      final markRes = await repository.saveSyncedTask(
        conflict.local.copyWith(
          syncState: SyncState.conflict,
          updatedAt: clock.nowUtc(),
        ),
      );
      if (markRes.isErr) return Err(markRes.failureOrNull!);
      conflictCount++;
    }

    // 2. Process toPush
    for (final task in plan.toPush) {
      if (task.isDeleted) {
        if (task.remoteEventId != null) {
          final delRes = await gateway.deleteRemote(
            task.remoteEventId!,
            task.remoteEtag ?? '',
          );
          if (delRes.isErr) return Err(delRes.failureOrNull!);
        }
        final permDel = await repository.deleteLocalPermanently(task.id);
        if (permDel.isErr) return Err(permDel.failureOrNull!);
        deleted++;
      } else {
        final taskEvent = TaskEvent.fromTask(task);
        final pushRes = await gateway.push(taskEvent);
        if (pushRes.isErr) return Err(pushRes.failureOrNull!);

        final remoteEvent = pushRes.valueOrNull!;
        final updatedTask = task.copyWith(
          remoteEventId: remoteEvent.id,
          remoteEtag: remoteEvent.etag,
          syncState: SyncState.synced,
          updatedAt: clock.nowUtc(),
        );
        final saveRes = await repository.saveSyncedTask(updatedTask);
        if (saveRes.isErr) return Err(saveRes.failureOrNull!);
        pushed++;
      }
    }

    // 3. Process toPull
    final localTasksRes = await repository.allTasksForSync();
    if (localTasksRes.isErr) return Err(localTasksRes.failureOrNull!);
    final currentLocalMap = <String, Task>{
      for (final t in localTasksRes.valueOrNull!)
        if (t.remoteEventId != null) t.remoteEventId!: t,
    };

    for (final remoteEvent in plan.toPull) {
      final existingLocal = currentLocalMap[remoteEvent.id];
      final now = clock.nowUtc();

      if (existingLocal != null) {
        final updatedTask = existingLocal.copyWith(
          title: remoteEvent.summary ?? existingLocal.title,
          notes: remoteEvent.description,
          dueAt: remoteEvent.start,
          allDay: remoteEvent.allDay,
          remoteEtag: remoteEvent.etag,
          syncState: SyncState.synced,
          updatedAt: now,
        );
        final saveRes = await repository.saveSyncedTask(updatedTask);
        if (saveRes.isErr) return Err(saveRes.failureOrNull!);
      } else {
        final newTask = Task(
          id: idGenerator.newId(),
          title: remoteEvent.summary ?? '',
          notes: remoteEvent.description,
          dueAt: remoteEvent.start,
          allDay: remoteEvent.allDay,
          isCompleted: false,
          remoteEventId: remoteEvent.id,
          remoteEtag: remoteEvent.etag,
          syncState: SyncState.synced,
          createdAt: now,
          updatedAt: now,
        );
        final saveRes = await repository.saveSyncedTask(newTask);
        if (saveRes.isErr) return Err(saveRes.failureOrNull!);
      }
      pulled++;
    }

    // 4. Process toDeleteLocal
    for (final taskId in plan.toDeleteLocal) {
      final delRes = await repository.deleteLocalPermanently(taskId);
      if (delRes.isErr) return Err(delRes.failureOrNull!);
      deleted++;
    }

    // 5. Process unchanged
    final allLocalList = localTasksRes.valueOrNull ?? [];
    for (final taskId in plan.unchanged) {
      final task = allLocalList.firstWhere(
        (t) => t.id == taskId,
        orElse: () => Task(
          id: '',
          title: '',
          allDay: false,
          isCompleted: false,
          syncState: SyncState.synced,
          createdAt: _epoch,
          updatedAt: _epoch,
        ),
      );
      if (task.id.isNotEmpty && task.syncState != SyncState.synced) {
        await repository.saveSyncedTask(
          task.copyWith(syncState: SyncState.synced),
        );
      }
    }

    return Ok(
      SyncReport(
        pushedCount: pushed,
        pulledCount: pulled,
        deletedCount: deleted,
        conflictCount: conflictCount,
      ),
    );
  }
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
