import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

class WeekView extends StatelessWidget {
  final DateTime focusedDate;
  final List<Task> tasks;
  final void Function(Task task)? onEditTask;
  final void Function(Task task)? onDeleteTask;

  const WeekView({
    super.key,
    required this.focusedDate,
    this.tasks = const [],
    this.onEditTask,
    this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the start of the week (Monday)
    final monday = focusedDate.subtract(
      Duration(days: focusedDate.weekday - 1),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: List.generate(7, (index) {
              final day = monday.add(Duration(days: index));
              final format = DateFormat.E(
                Localizations.localeOf(context).languageCode,
              );
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        format.format(day),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(7, (index) {
              final day = monday.add(Duration(days: index));
              final tasksForDay = tasks.where((t) {
                if (t.dueAt == null) return false;
                final date = t.allDay ? t.dueAt! : t.dueAt!.toLocal();
                return date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day;
              }).toList();

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: tasksForDay.length,
                    itemBuilder: (context, i) {
                      final task = tasksForDay[i];
                      return InkWell(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: task.notes != null
                                        ? Text(task.notes!)
                                        : null,
                                  ),
                                  ListTile(
                                    leading: const Icon(AppIcons.edit),
                                    title: Text(
                                      (Localizations.of<AppLocalizations>(
                                                context,
                                                AppLocalizations,
                                              ) ??
                                              lookupAppLocalizations(
                                                const Locale('pt'),
                                              ))
                                          .calendarEditTaskAction,
                                    ),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      onEditTask?.call(task);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      AppIcons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      (Localizations.of<AppLocalizations>(
                                                context,
                                                AppLocalizations,
                                              ) ??
                                              lookupAppLocalizations(
                                                const Locale('pt'),
                                              ))
                                          .calendarDeleteTaskAction,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    onTap: () async {
                                      Navigator.of(ctx).pop();
                                      final l10n =
                                          Localizations.of<AppLocalizations>(
                                            context,
                                            AppLocalizations,
                                          ) ??
                                          lookupAppLocalizations(
                                            const Locale('pt'),
                                          );
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(
                                            l10n.calendarDeleteTaskTitle,
                                          ),
                                          content: Text(
                                            l10n.calendarDeleteTaskConfirm(
                                              task.title,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: Text(l10n.commonCancel),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(true),
                                              child: Text(l10n.commonDelete),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        onDeleteTask?.call(task);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 10,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
