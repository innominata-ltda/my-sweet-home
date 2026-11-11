import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/sync_executor.dart';
import 'package:my_sweet_home/features/tasks/domain/task_sync_service.dart';

import '../../fakes/in_memory_calendar_gateway.dart';
import 'sync_executor_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12, 0);
  final clock = TestClock(now);

  group('Sync Failure Resilience (CA-4.1)', () {
    test('mid-sync failure does not corrupt or lose anything and next attempt retries', () async {
      final repo = TestTaskRepository();
      // Simulate failure on 2nd remote action (e.g. pull or 2nd push)
      final gateway = InMemoryCalendarGateway(failAfterActions: 1);
      final idGen = TestIdGenerator();
      final executor = DefaultSyncExecutor(
        gateway: gateway,
        repository: repo,
        idGenerator: idGen,
        clock: clock,
      );
      final syncService = TaskSyncService(
        gateway: gateway,
        repository: repo,
        executor: executor,
      );

      // Duas tarefas locais para serem enviadas
      final t1 = Task(
        id: 't1',
        title: 'Primeira tarefa',
        allDay: false,
        isCompleted: false,
        syncState: SyncState.dirty,
        createdAt: now,
        updatedAt: now,
      );
      final t2 = Task(
        id: 't2',
        title: 'Segunda tarefa',
        allDay: false,
        isCompleted: false,
        syncState: SyncState.dirty,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveSyncedTask(t1);
      await repo.saveSyncedTask(t2);

      final window = DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now.add(const Duration(days: 90)),
      );

      // 1. Try sync -> first action passes (pull snapshot), but push fails!
      final result1 = await syncService.sync(window: window);
      expect(result1.isErr, isTrue);

      // Check resilience (CA-4.1): No task was lost!
      expect(repo.tasks.length, 2);
      expect(repo.tasks['t1']!.title, 'Primeira tarefa');
      expect(repo.tasks['t2']!.title, 'Segunda tarefa');

      // 2. Remove network error (connection recovery)
      gateway.failAfterActions = null;

      // 3. Next synchronization attempt succeeds
      final result2 = await syncService.sync(window: window);
      expect(result2.isOk, isTrue);

      final report = result2.valueOrNull!;
      expect(report.pushedCount, 2);

      expect(repo.tasks['t1']!.syncState, SyncState.synced);
      expect(repo.tasks['t2']!.syncState, SyncState.synced);
    });
  });
}
