import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/tasks/data/task_dao.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/tasks/domain/task_sync_service.dart';
import 'package:my_sweet_home/features/tasks/domain/calendar_gateway_port.dart';
import 'package:my_sweet_home/features/tasks/domain/sync_executor.dart';
import 'package:my_sweet_home/features/tasks/data/adapters/google_calendar_adapter.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskDao(
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    trashPolicy: DriftTrashPolicy(
      db: ref.watch(databaseProvider),
      clock: ref.watch(clockProvider),
    ),
  );
});

final calendarGatewayProvider = Provider<CalendarGatewayPort>((ref) {
  return GoogleCalendarAdapter(clock: ref.watch(clockProvider));
});

final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  return TaskSyncService(
    gateway: ref.watch(calendarGatewayProvider),
    repository: ref.watch(taskRepositoryProvider),
    executor: DefaultSyncExecutor(
      gateway: ref.watch(calendarGatewayProvider),
      repository: ref.watch(taskRepositoryProvider),
      idGenerator: ref.watch(idGeneratorProvider),
      clock: ref.watch(clockProvider),
    ),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});
