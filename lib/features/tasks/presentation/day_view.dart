import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

class DayView extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final List<CalendarBill> bills;
  final void Function(Task task, bool completed)? onToggleComplete;
  final void Function(Task task)? onEditTask;
  final void Function(Task task)? onDeleteTask;
  final void Function(CalendarBill bill)? onTapBill;

  const DayView({
    super.key,
    required this.date,
    this.tasks = const [],
    this.bills = const [],
    this.onToggleComplete,
    this.onEditTask,
    this.onDeleteTask,
    this.onTapBill,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dayOfWeek = DateFormat.EEEE(locale).format(date);
    final dayAndMonth = DateFormat('d \'de\' MMMM', locale).format(date);
    final capitalizedDayOfWeek = dayOfWeek.isNotEmpty
        ? '${dayOfWeek[0].toUpperCase()}${dayOfWeek.substring(1)}'
        : dayOfWeek;

    final tasksForDay = tasks.where((t) {
      if (t.dueAt == null) return false;
      final localDue = t.allDay ? t.dueAt! : t.dueAt!.toLocal();
      return localDue.year == date.year &&
          localDue.month == date.month &&
          localDue.day == date.day;
    }).toList();

    final billsForDay = bills.where((b) {
      final due = b.dueOn;
      return due.year == date.year &&
          due.month == date.month &&
          due.day == date.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with day of week and day of month (T-B11)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$capitalizedDayOfWeek, $dayAndMonth',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (billsForDay.isNotEmpty)
                Badge(
                  label: Text('${billsForDay.length} conta(s)'),
                  backgroundColor: Colors.orange.shade800,
                ),
            ],
          ),
        ),
        if (billsForDay.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.bill, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Contas a vencer hoje (${billsForDay.length}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final b in billsForDay)
                  InkWell(
                    key: Key(
                      'calendar_bill_${b.id.isNotEmpty ? b.id : b.title}',
                    ),
                    onTap: () {
                      if (onTapBill != null) {
                        onTapBill!(b);
                      } else {
                        context.push('/contas', extra: b.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Text(
                              '• ${b.title}${b.amountCents != null ? ' — R\$ ${(b.amountCents! / 100).toStringAsFixed(2)}' : ''}${b.paidOn != null ? ' (Paga)' : ' (Pendente)'}',
                              style: TextStyle(
                                color: b.paidOn != null
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            AppIcons.chevronRight,
                            size: 16,
                            color: Colors.brown,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final tasksForHour = tasksForDay.where((t) {
                if (t.allDay) return hour == 0;
                return t.dueAt!.toLocal().hour == hour;
              }).toList();

              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                          top: 12.0,
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tasksForHour.map((task) {
                          return ListTile(
                            leading: CuteCheckbox(
                              value: task.isCompleted,
                              semanticLabel: task.title,
                              onChanged: (val) {
                                if (val) {
                                  final remainingPending = tasksForDay
                                      .where(
                                        (t) =>
                                            t.id != task.id && !t.isCompleted,
                                      )
                                      .length;
                                  if (remainingPending == 0 &&
                                      tasksForDay.isNotEmpty) {
                                    CelebrationOverlay.show(
                                      context,
                                      message: 'Todas as tarefas de hoje foram concluídas! 🎉',
                                    );
                                  }
                                }
                                onToggleComplete?.call(task, val);
                              },
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: task.notes != null
                                ? Text(task.notes!)
                                : null,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(AppIcons.more),
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  onEditTask?.call(task);
                                } else if (action == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Excluir tarefa?'),
                                      content: Text(
                                        'Tem certeza de que deseja excluir "${task.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    onDeleteTask?.call(task);
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
