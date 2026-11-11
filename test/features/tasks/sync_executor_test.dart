import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/domain/sync_executor.dart';
import 'package:my_sweet_home/features/tasks/domain/task_sync_service.dart';

import '../../fakes/in_memory_calendar_gateway.dart';

class TestTaskRepository implements TaskRepository {
  final Map<String, Task> tasks = {};

  @override
  Future<Result<Task, Failure>> upsert(NewTask t) async {
    final id = 'local_${tasks.length + 1}';
    final task = Task(
      id: id,
      title: t.title,
      notes: t.notes,
      dueAt: t.dueAt,
      allDay: t.allDay,
      isCompleted: false,
      syncState: SyncState.dirty,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    tasks[id] = task;
    return Ok(task);
  }

  @override
  Future<Result<Task, Failure>> complete(TaskId id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Task, Failure>> uncomplete(TaskId id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(
    TaskId id, {
    required bool alsoRemote,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Task>, Failure>> inRange(DateTimeRange r) async =>
      Ok(tasks.values.toList());

  @override
  Future<Result<List<Task>, Failure>> withoutDueDate() async => Ok([]);

  @override
  Future<Result<List<Task>, Failure>> dirtySince(DateTime? mark) async =>
      Ok(tasks.values.where((t) => t.syncState == SyncState.dirty).toList());

  @override
  Future<Result<List<Task>, Failure>> allTasksForSync() async =>
      Ok(tasks.values.toList());

  @override
  Future<Result<Task, Failure>> saveSyncedTask(Task task) async {
    tasks[task.id] = task;
    return Ok(task);
  }

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(TaskId id) async {
    tasks.remove(id);
    return const Ok(null);
  }
}

class TestClock implements Clock {
  final DateTime fixed;
  TestClock(this.fixed);

  @override
  DateTime nowUtc() => fixed;

  @override
  DateTime nowLocal() => fixed;

  @override
  DateTime todayUtc() => DateTime.utc(fixed.year, fixed.month, fixed.day);
}

class TestIdGenerator implements IdGenerator {
  int _counter = 1;

  @override
  String newId() => 'generated_${_counter++}';
}

void main() {
  final now = DateTime.utc(2026, 10, 1, 12, 0);
  final clock = TestClock(now);

  group('SyncExecutor & TaskSyncService (T-06)', () {
    late TestTaskRepository repo;
    late InMemoryCalendarGateway gateway;
    late SyncExecutor executor;
    late TaskSyncService syncService;
    late IdGenerator idGen;

    setUp(() {
      repo = TestTaskRepository();
      gateway = InMemoryCalendarGateway();
      idGen = TestIdGenerator();
      executor = DefaultSyncExecutor(
        gateway: gateway,
        repository: repo,
        idGenerator: idGen,
        clock: clock,
      );
      syncService = TaskSyncService(
        gateway: gateway,
        repository: repo,
        executor: executor,
      );
    });

    test('Full bidirectional sync without duplication (RF-084, CA-3.1)', () async {
      // 1. Tarefa local dirty
      final localTask = Task(
        id: 't_local_1',
        title: 'Tarefa Criada Localmente',
        allDay: false,
        isCompleted: false,
        syncState: SyncState.dirty,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveSyncedTask(localTask);

      // 2. Evento remoto novo
      final remoteEvent = RemoteEvent(
        id: 'r_remote_1',
        etag: 'etag_r1',
        updatedAt: now,
        summary: 'Evento Criado no Google',
        allDay: false,
      );
      gateway.seed([remoteEvent]);

      final window = DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now.add(const Duration(days: 90)),
      );

      // 3. Executes first synchronization
      final result1 = await syncService.sync(window: window);
      expect(result1.isOk, isTrue);
      final report1 = result1.valueOrNull!;

      expect(report1.pushedCount, 1);
      expect(report1.pulledCount, 1);

      // Confere que a tarefa local foi enviada e atualizada com o remoteEventId
      final updatedLocal = repo.tasks['t_local_1']!;
      expect(updatedLocal.syncState, SyncState.synced);
      expect(updatedLocal.remoteEventId, isNotNull);

      // Confere que a tarefa remota virou tarefa local
      expect(repo.tasks.length, 2);
      final pulledLocal = repo.tasks.values.firstWhere(
        (t) => t.remoteEventId == 'r_remote_1',
      );
      expect(pulledLocal.title, 'Evento Criado no Google');
      expect(pulledLocal.syncState, SyncState.synced);

      // 4. Executes second synchronization (no changes)
      final result2 = await syncService.sync(window: window);
      expect(result2.isOk, isTrue);
      final report2 = result2.valueOrNull!;

      expect(report2.pushedCount, 0);
      expect(report2.pulledCount, 0);
      expect(report2.conflictCount, 0);

      // Confere que NENHUMA duplicata foi criada!
      expect(repo.tasks.length, 2);
    });

    test(
      'Incremental sync with lastSyncAt preserves unmodified local tasks',
      () async {
        final localTask = Task(
          id: 't1',
          title: 'Já Sincronizada',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'rem_1',
          remoteEtag: 'etag_1',
          syncState: SyncState.synced,
          createdAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        );
        await repo.saveSyncedTask(localTask);

        final window = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 90)),
        );

        // Incremental sync with lastSyncAt = now (gateway returns nothing as nothing changed)
        final result = await syncService.sync(window: window, lastSyncAt: now);
        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;
        expect(report.deletedCount, 0);
        expect(repo.tasks.containsKey('t1'), isTrue);
      },
    );

    test(
      'Tarefa excluída localmente sem remoteEventId é removida do banco',
      () async {
        final deletedTask = Task(
          id: 't_deleted',
          title: 'Excluída Localmente',
          allDay: false,
          isCompleted: false,
          syncState: SyncState.dirty,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        );
        await repo.saveSyncedTask(deletedTask);

        final window = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 90)),
        );

        final result = await syncService.sync(window: window);
        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;
        expect(report.deletedCount, 1);
        expect(repo.tasks.containsKey('t_deleted'), isFalse);
      },
    );

    test(
      'Locally deleted task with remoteEventId deletes on remote and local db',
      () async {
        final deletedTask = Task(
          id: 't_del_remote',
          title: 'Excluída Localmente com Remote',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'r_del_1',
          remoteEtag: 'etag_del_1',
          syncState: SyncState.dirty,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        );
        await repo.saveSyncedTask(deletedTask);
        gateway.seed([
          RemoteEvent(
            id: 'r_del_1',
            etag: 'etag_del_1',
            updatedAt: now,
            summary: 'Excluída Localmente com Remote',
            allDay: false,
          ),
        ]);

        final window = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 90)),
        );

        final result = await syncService.sync(window: window);
        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;
        expect(report.deletedCount, 1);
        expect(repo.tasks.containsKey('t_del_remote'), isFalse);
        expect(gateway.getEvent('r_del_1')?.status, 'cancelled');
      },
    );

    test('Idempotency: syncing 3x in a row without changes yields 0 additional pushes/pulls', () async {
      final localTask = Task(
        id: 't1',
        title: 'Tarefa Idempotência',
        allDay: false,
        isCompleted: false,
        syncState: SyncState.dirty,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveSyncedTask(localTask);

      final window = DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now.add(const Duration(days: 90)),
      );

      // 1º sync: push = 1
      final res1 = await syncService.sync(window: window);
      expect(res1.isOk, isTrue);
      expect(res1.valueOrNull!.pushedCount, 1);

      // 2º sync: nada muda
      final res2 = await syncService.sync(window: window);
      expect(res2.isOk, isTrue);
      expect(res2.valueOrNull!.pushedCount, 0);
      expect(res2.valueOrNull!.pulledCount, 0);

      // 3º sync: nada muda
      final res3 = await syncService.sync(window: window);
      expect(res3.isOk, isTrue);
      expect(res3.valueOrNull!.pushedCount, 0);
      expect(res3.valueOrNull!.pulledCount, 0);
    });
  });
}
