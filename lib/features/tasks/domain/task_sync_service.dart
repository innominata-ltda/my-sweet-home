import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/time/clock.dart';

import 'calendar_gateway_port.dart';
import 'models.dart';
import 'repositories.dart';
import 'sync_executor.dart';
import 'sync_reconciler.dart';

class TaskSyncService {
  final CalendarGatewayPort gateway;
  final TaskRepository repository;
  final SyncReconciler reconciler;
  final SyncExecutor executor;
  final SettingsRepository? settingsRepository;
  final Clock clock;

  TaskSyncService({
    required this.gateway,
    required this.repository,
    this.reconciler = const DefaultSyncReconciler(),
    required this.executor,
    this.settingsRepository,
    this.clock = const SystemClock(),
  });

  /// Performs synchronization respecting explicit consent (RN-153, RN-161, CA-2.1, CA-2.2).
  ///
  /// If [settingsRepository] is provided and synchronization permission/consent
  /// has not been granted, NO external request to [gateway] is made (CA-2.1).
  Future<Result<SyncReport, Failure>> sync({
    required DateTimeRange window,
    DateTime? lastSyncAt,
    bool syncFutureOnly = false,
  }) async {
    if (settingsRepository != null) {
      final hasConsent = await settingsRepository!.isCloudBackupAllowed();
      // In case consent exists in settings repository
      if (!hasConsent) {
        return const Err(PermissionFailure(permission: 'calendar_sync'));
      }
    }

    final localRes = await repository.allTasksForSync();
    if (localRes.isErr) return Err(localRes.failureOrNull!);
    var localTasks = localRes.valueOrNull!;

    if (syncFutureOnly) {
      final now = clock.nowUtc();
      localTasks = localTasks
          .where((t) => t.dueAt == null || !t.dueAt!.isBefore(now))
          .toList();
    }

    final remoteRes = await gateway.pull(window, updatedMin: lastSyncAt);
    if (remoteRes.isErr) return Err(remoteRes.failureOrNull!);
    final remoteSnapshot = remoteRes.valueOrNull!;

    final plan = reconciler.reconcile(
      local: localTasks,
      remote: remoteSnapshot,
      lastSyncAt: lastSyncAt,
    );

    return executor.apply(plan);
  }
}
