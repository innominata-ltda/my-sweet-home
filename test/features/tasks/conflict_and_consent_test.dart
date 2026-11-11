import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/tasks/domain/conflict_resolution_port.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/sync_executor.dart';
import 'package:my_sweet_home/features/tasks/domain/task_sync_service.dart';

import '../../fakes/fake_conflict_resolution_port.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/in_memory_calendar_gateway.dart';
import 'sync_executor_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12, 0);
  final clock = TestClock(now);

  group(
    'T-07: Resolução de Conflitos pelo Usuário (RF-085, RN-156, CA-3.2)',
    () {
      late TestTaskRepository repo;
      late InMemoryCalendarGateway gateway;
      late IdGenerator idGen;
      late FakeConflictResolver resolver;
      late DefaultSyncExecutor executor;
      late TaskSyncService syncService;

      setUp(() {
        repo = TestTaskRepository();
        gateway = InMemoryCalendarGateway();
        idGen = TestIdGenerator();
        resolver = FakeConflictResolver();
        executor = DefaultSyncExecutor(
          gateway: gateway,
          repository: repo,
          idGenerator: idGen,
          clock: clock,
          conflictResolver: resolver,
        );
        syncService = TaskSyncService(
          gateway: gateway,
          repository: repo,
          executor: executor,
        );
      });

      test('CA-3.2: When user chooses keepLocal, local version is kept and sent to remote', () async {
        final lastSync = now.subtract(const Duration(hours: 2));

        final localTask = Task(
          id: 't1',
          title: 'Título Local Editado',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'rem_1',
          remoteEtag: 'etag_1',
          syncState: SyncState.dirty,
          createdAt: lastSync,
          updatedAt: now,
        );
        await repo.saveSyncedTask(localTask);

        final remoteEvent = RemoteEvent(
          id: 'rem_1',
          etag: 'etag_2',
          updatedAt: now,
          summary: 'Título Remoto Editado',
          allDay: false,
        );
        gateway.seed([remoteEvent]);

        resolver.defaultChoice = ConflictChoice.keepLocal;

        final window = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 90)),
        );

        final result = await syncService.sync(
          window: window,
          lastSyncAt: lastSync,
        );
        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;

        expect(report.conflictCount, 1);
        expect(report.pushedCount, 1);
        expect(resolver.resolvedConflicts.length, 1);
        expect(repo.tasks['t1']!.title, 'Título Local Editado');
        expect(repo.tasks['t1']!.syncState, SyncState.synced);
      });

      test(
        'CA-3.2: When user chooses keepRemote, remote version overwrites local',
        () async {
          final lastSync = now.subtract(const Duration(hours: 2));

          final localTask = Task(
            id: 't1',
            title: 'Título Local Editado',
            allDay: false,
            isCompleted: false,
            remoteEventId: 'rem_1',
            remoteEtag: 'etag_1',
            syncState: SyncState.dirty,
            createdAt: lastSync,
            updatedAt: now,
          );
          await repo.saveSyncedTask(localTask);

          final remoteEvent = RemoteEvent(
            id: 'rem_1',
            etag: 'etag_2',
            updatedAt: now,
            summary: 'Título Remoto Editado',
            allDay: false,
          );
          gateway.seed([remoteEvent]);

          resolver.defaultChoice = ConflictChoice.keepRemote;

          final window = DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now.add(const Duration(days: 90)),
          );

          final result = await syncService.sync(
            window: window,
            lastSyncAt: lastSync,
          );
          expect(result.isOk, isTrue);
          final report = result.valueOrNull!;

          expect(report.conflictCount, 1);
          expect(report.pulledCount, 1);
          expect(repo.tasks['t1']!.title, 'Título Remoto Editado');
          expect(repo.tasks['t1']!.syncState, SyncState.synced);
        },
      );
    },
  );

  group(
    'T-08 & T-V2: Consentimento de Sincronização (RN-153, RN-161, CA-2.1)',
    () {
      test('T-V2 & CA-2.1: Without consent (false), NO network call is made to gateway', () async {
        final repo = TestTaskRepository();
        final gateway = InMemoryCalendarGateway();
        final idGen = TestIdGenerator();
        final settingsRepo = FakeSettingsRepository(cloudBackupAllowed: false);

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
          settingsRepository: settingsRepo,
        );

        final window = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 90)),
        );

        final result = await syncService.sync(window: window);
        expect(result.isErr, isTrue);
        expect(result.failureOrNull!, isA<PermissionFailure>());
        expect(gateway.actionCount, equals(0)); // No action on remote gateway!
      });

      test(
        'Com consentimento (true), a sincronização é realizada normalmente',
        () async {
          final repo = TestTaskRepository();
          final gateway = InMemoryCalendarGateway();
          final idGen = TestIdGenerator();
          final settingsRepo = FakeSettingsRepository(cloudBackupAllowed: true);

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
            settingsRepository: settingsRepo,
          );

          final window = DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now.add(const Duration(days: 90)),
          );

          final result = await syncService.sync(window: window);
          expect(result.isOk, isTrue);
        },
      );
    },
  );
}
