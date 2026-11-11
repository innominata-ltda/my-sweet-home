import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/sync_reconciler.dart';

void main() {
  const reconciler = DefaultSyncReconciler();
  final now = DateTime.utc(2026, 10, 1, 10, 0);

  group('SyncReconciler (T-06)', () {
    test('local creation goes to toPush', () {
      final task = Task(
        id: 't1',
        title: 'Trocar lâmpada',
        allDay: false,
        isCompleted: false,
        syncState: SyncState.dirty,
        createdAt: now,
        updatedAt: now,
      );

      final plan = reconciler.reconcile(
        local: [task],
        remote: RemoteSnapshot(events: [], snapshotAt: now),
        lastSyncAt: null,
      );

      expect(plan.toPush, [task]);
      expect(plan.toPull, isEmpty);
      expect(plan.conflicts, isEmpty);
      expect(plan.toDeleteLocal, isEmpty);
    });

    test(
      'CA-3.1: criação remota vai para toPull, rodar de novo vira unchanged',
      () {
        final remoteEvent = RemoteEvent(
          id: 'rem_1',
          etag: 'etag_1',
          updatedAt: now,
          summary: 'Dentista',
          allDay: false,
        );

        // 1. First reconciliation
        final plan1 = reconciler.reconcile(
          local: [],
          remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
          lastSyncAt: null,
        );

        expect(plan1.toPull, [remoteEvent]);
        expect(plan1.toPush, isEmpty);
        expect(plan1.conflicts, isEmpty);

        // Simula puxada para o local
        final localTask = Task(
          id: 't1',
          title: 'Dentista',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'rem_1',
          remoteEtag: 'etag_1',
          syncState: SyncState.synced,
          createdAt: now,
          updatedAt: now,
        );

        // 2. Second reconciliation with same event
        final plan2 = reconciler.reconcile(
          local: [localTask],
          remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
          lastSyncAt: now,
        );

        expect(plan2.toPull, isEmpty);
        expect(plan2.toPush, isEmpty);
        expect(plan2.conflicts, isEmpty);
        expect(plan2.unchanged, ['t1']);
      },
    );

    test('incremental sync (lastSyncAt != null): absent event in remoteSnapshot without local change becomes unchanged', () {
      final lastSync = now.subtract(const Duration(hours: 2));

      final localTask = Task(
        id: 't1',
        title: 'Tarefa Intacta',
        allDay: false,
        isCompleted: false,
        remoteEventId: 'rem_1',
        remoteEtag: 'etag_1',
        syncState: SyncState.synced,
        createdAt: lastSync,
        updatedAt: lastSync,
      );

      final plan = reconciler.reconcile(
        local: [localTask],
        remote: RemoteSnapshot(events: [], snapshotAt: now),
        lastSyncAt: lastSync,
      );

      expect(plan.toDeleteLocal, isEmpty);
      expect(plan.toPush, isEmpty);
      expect(plan.toPull, isEmpty);
      expect(plan.conflicts, isEmpty);
      expect(plan.unchanged, ['t1']);
    });

    test('CA-3.2: alterado dos dois lados gera Conflict, 0 push, 0 pull', () {
      final lastSync = now.subtract(const Duration(hours: 2));

      final localTask = Task(
        id: 't1',
        title: 'Comprar leite (editado local)',
        allDay: false,
        isCompleted: false,
        remoteEventId: 'rem_1',
        remoteEtag: 'etag_1',
        syncState: SyncState.dirty,
        createdAt: lastSync,
        updatedAt: now,
      );

      final remoteEvent = RemoteEvent(
        id: 'rem_1',
        etag: 'etag_2',
        updatedAt: now,
        summary: 'Comprar leite desnatado (editado remoto)',
        allDay: false,
      );

      final plan = reconciler.reconcile(
        local: [localTask],
        remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
        lastSyncAt: lastSync,
      );

      expect(plan.toPush, isEmpty);
      expect(plan.toPull, isEmpty);
      expect(plan.conflicts.length, 1);
      expect(plan.conflicts.first.local, localTask);
      expect(plan.conflicts.first.remote, remoteEvent);
    });

    test('local-only edit goes to toPush', () {
      final lastSync = now.subtract(const Duration(hours: 2));

      final localTask = Task(
        id: 't1',
        title: 'Limpar casa (editado)',
        allDay: false,
        isCompleted: false,
        remoteEventId: 'rem_1',
        remoteEtag: 'etag_1',
        syncState: SyncState.dirty,
        createdAt: lastSync,
        updatedAt: now,
      );

      final remoteEvent = RemoteEvent(
        id: 'rem_1',
        etag: 'etag_1',
        updatedAt: lastSync,
        summary: 'Limpar casa',
        allDay: false,
      );

      final plan = reconciler.reconcile(
        local: [localTask],
        remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
        lastSyncAt: lastSync,
      );

      expect(plan.toPush, [localTask]);
      expect(plan.toPull, isEmpty);
      expect(plan.conflicts, isEmpty);
    });

    test('remote-only edit goes to toPull', () {
      final lastSync = now.subtract(const Duration(hours: 2));

      final localTask = Task(
        id: 't1',
        title: 'Pagar conta',
        allDay: false,
        isCompleted: false,
        remoteEventId: 'rem_1',
        remoteEtag: 'etag_1',
        syncState: SyncState.synced,
        createdAt: lastSync,
        updatedAt: lastSync,
      );

      final remoteEvent = RemoteEvent(
        id: 'rem_1',
        etag: 'etag_2',
        updatedAt: now,
        summary: 'Pagar conta de energia',
        allDay: false,
      );

      final plan = reconciler.reconcile(
        local: [localTask],
        remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
        lastSyncAt: lastSync,
      );

      expect(plan.toPull, [remoteEvent]);
      expect(plan.toPush, isEmpty);
      expect(plan.conflicts, isEmpty);
    });

    test(
      'evento apagado no remoto sem alteração local vai para toDeleteLocal',
      () {
        final lastSync = now.subtract(const Duration(hours: 2));

        final localTask = Task(
          id: 't1',
          title: 'Reunião cancelada',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'rem_1',
          remoteEtag: 'etag_1',
          syncState: SyncState.synced,
          createdAt: lastSync,
          updatedAt: lastSync,
        );

        final remoteEvent = RemoteEvent(
          id: 'rem_1',
          etag: 'etag_2',
          updatedAt: now,
          summary: 'Reunião',
          allDay: false,
          status: 'cancelled',
        );

        final plan = reconciler.reconcile(
          local: [localTask],
          remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
          lastSyncAt: lastSync,
        );

        expect(plan.toDeleteLocal, ['t1']);
        expect(plan.toPush, isEmpty);
        expect(plan.toPull, isEmpty);
        expect(plan.conflicts, isEmpty);
      },
    );

    test('deleted event on remote with local edit yields Conflict', () {
      final lastSync = now.subtract(const Duration(hours: 2));

      final localTask = Task(
        id: 't1',
        title: 'Reunião importante (editado)',
        allDay: false,
        isCompleted: false,
        remoteEventId: 'rem_1',
        remoteEtag: 'etag_1',
        syncState: SyncState.dirty,
        createdAt: lastSync,
        updatedAt: now,
      );

      final remoteEvent = RemoteEvent(
        id: 'rem_1',
        etag: 'etag_2',
        updatedAt: now,
        summary: 'Reunião',
        allDay: false,
        status: 'cancelled',
      );

      final plan = reconciler.reconcile(
        local: [localTask],
        remote: RemoteSnapshot(events: [remoteEvent], snapshotAt: now),
        lastSyncAt: lastSync,
      );

      expect(plan.conflicts.length, 1);
      expect(plan.toDeleteLocal, isEmpty);
      expect(plan.toPush, isEmpty);
    });
  });
}
