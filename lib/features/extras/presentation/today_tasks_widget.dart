import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_controller.dart';

/// Widget de tarefas do dia para a tela inicial / dashboard (RF-102, CA-110.6, RN-284).
class TodayTasksWidget extends StatelessWidget {
  const TodayTasksWidget({
    super.key,
    required this.controller,
    this.title,
    this.onTapTask,
    this.onToggleTask,
    this.onTapViewAll,
  });

  final TodayTasksWidgetController controller;
  final String? title;
  final void Function(Task task)? onTapTask;
  final void Function(Task task)? onToggleTask;
  final VoidCallback? onTapViewAll;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TodayTasksWidgetState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state is TodayTasksWidgetLoading) {
          return const AppCard(
            child: SizedBox(height: 100, child: Center(child: AppLoading())),
          );
        }

        if (state is TodayTasksWidgetError) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Erro ao carregar tarefas de hoje: ${state.failure}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final successState = state as TodayTasksWidgetSuccess;
        final theme = Theme.of(context);

        return Semantics(
          container: true,
          label: 'Widget de tarefas do dia',
          child: AppCard(
            key: const Key('today_tasks_widget_card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.tasks,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title ??
                                  Localizations.of<AppLocalizations>(
                                    context,
                                    AppLocalizations,
                                  )?.dashboardTodayTasksTitle ??
                                  'Tarefas de hoje',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (successState.tasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${successState.pendingCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (successState.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AppEmptyState.mascot(
                      title: 'Nenhuma tarefa para hoje',
                      description: 'Você não tem tarefas agendadas para hoje.',
                      mascotExpression: MascotExpression.relaxed,
                      mascotSemanticLabel:
                          Localizations.of<AppLocalizations>(
                            context,
                            AppLocalizations,
                          )?.momoEmptyTasks ??
                          'Momo relaxada — nenhuma tarefinha para hoje',
                    ),
                  )
                else
                  Column(
                    children: successState.tasks.map((task) {
                      final isDone = task.isCompleted;

                      return Semantics(
                        container: true,
                        label:
                            '${task.title}, ${isDone ? "concluída" : "pendente"}',
                        button: onTapTask != null,
                        child: Container(
                          key: Key('today_task_item_${task.id}'),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CuteCheckbox(
                                key: Key('today_task_check_${task.id}'),
                                value: isDone,
                                excludeSemantics: true,
                                onChanged: (val) {
                                  if (val) {
                                    final remainingPending = successState.tasks
                                        .where(
                                          (t) =>
                                              t.id != task.id && !t.isCompleted,
                                        )
                                        .length;
                                    if (remainingPending == 0 &&
                                        successState.tasks.isNotEmpty) {
                                      CelebrationOverlay.show(
                                        context,
                                        message: 'Todas as tarefas de hoje foram concluídas! 🎉',
                                      );
                                    }
                                  }
                                  if (onToggleTask != null) {
                                    onToggleTask!(task);
                                  } else {
                                    controller.toggleComplete(task.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: InkWell(
                                  onTap: onTapTask != null
                                      ? () => onTapTask!(task)
                                      : null,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isDone
                                                  ? theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                  : theme.colorScheme.onSurface,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (task.category != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          task.category!.name,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (onTapViewAll != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTapViewAll,
                      child: const Text('Ver todas as tarefas'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
