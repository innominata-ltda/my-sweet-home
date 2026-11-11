import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_controller.dart';

final todayTasksWidgetControllerProvider =
    Provider.family<TodayTasksWidgetController, TodayTasksWidgetParams>((
      ref,
      params,
    ) {
      final controller = TodayTasksWidgetController(
        taskRepository: params.taskRepository,
        clock: params.clock ?? ref.watch(clockProvider),
      );

      try {
        final db = ref.watch(databaseProvider);
        final sub = db
            .select(db.tasks)
            .watch()
            .listen((_) => controller.load());
        ref.onDispose(sub.cancel);
      } catch (_) {}

      ref.onDispose(controller.dispose);
      return controller;
    });

class TodayTasksWidgetParams {
  final TaskRepository taskRepository;
  final Clock? clock;

  const TodayTasksWidgetParams({required this.taskRepository, this.clock});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayTasksWidgetParams &&
          runtimeType == other.runtimeType &&
          taskRepository == other.taskRepository &&
          clock == other.clock;

  @override
  int get hashCode => taskRepository.hashCode ^ clock.hashCode;
}
