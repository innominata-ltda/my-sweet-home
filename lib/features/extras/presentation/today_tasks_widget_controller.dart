import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

sealed class TodayTasksWidgetState {}

class TodayTasksWidgetLoading extends TodayTasksWidgetState {}

class TodayTasksWidgetSuccess extends TodayTasksWidgetState {
  final List<Task> tasks;

  TodayTasksWidgetSuccess({required this.tasks});

  bool get isEmpty => tasks.isEmpty;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
}

class TodayTasksWidgetError extends TodayTasksWidgetState {
  final Failure failure;

  TodayTasksWidgetError(this.failure);
}

/// Controller para o widget de tarefas do dia (RF-102).
class TodayTasksWidgetController extends ValueNotifier<TodayTasksWidgetState> {
  TodayTasksWidgetController({required this._taskRepository, Clock? clock})
    : _clock = clock ?? const SystemClock(),
      super(TodayTasksWidgetLoading()) {
    unawaited(load());
  }

  final TaskRepository _taskRepository;
  final Clock _clock;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(TodayTasksWidgetState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  Future<void> load() async {
    value = TodayTasksWidgetLoading();

    final now = _clock.nowUtc();
    final localNow = now.toLocal();
    final localStart = DateTime(localNow.year, localNow.month, localNow.day);
    final localEnd = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      23,
      59,
      59,
      999,
    );
    final start = localStart.toUtc();
    final end = localEnd.toUtc();

    final result = await _taskRepository.inRange(
      DateTimeRange(start: start, end: end),
    );

    if (result is Err) {
      value = TodayTasksWidgetError((result as Err).failure);
      return;
    }

    final allTasks = (result as Ok<List<Task>, Failure>).value;
    final activeTasks = allTasks.where((t) => !t.isDeleted).toList();

    activeTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueAt != null && b.dueAt != null) {
        return a.dueAt!.compareTo(b.dueAt!);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    value = TodayTasksWidgetSuccess(tasks: activeTasks);
  }

  Future<void> toggleComplete(TaskId id) async {
    final currentTasks = (value is TodayTasksWidgetSuccess)
        ? (value as TodayTasksWidgetSuccess).tasks
        : <Task>[];
    final task = currentTasks.where((t) => t.id == id).firstOrNull;
    final isDone = task?.isCompleted ?? false;

    final result = isDone
        ? await _taskRepository.uncomplete(id)
        : await _taskRepository.complete(id);

    if (result is Ok) {
      await load();
    }
  }
}
