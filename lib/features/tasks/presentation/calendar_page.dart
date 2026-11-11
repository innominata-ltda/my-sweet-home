import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as models;
import 'package:my_sweet_home/features/tasks/domain/models.dart'
    hide DateTimeRange;
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/presentation/day_view.dart';
import 'package:my_sweet_home/features/tasks/presentation/month_view.dart';
import 'package:my_sweet_home/features/tasks/presentation/quick_add_task_sheet.dart';
import 'package:my_sweet_home/features/tasks/presentation/week_view.dart';

import 'package:drift/drift.dart' hide Column;
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';

class CalendarBill {
  final String id;
  final String title;
  final int? amountCents;
  final DateTime dueOn;
  final DateTime? paidOn;

  const CalendarBill({
    this.id = '',
    required this.title,
    this.amountCents,
    required this.dueOn,
    this.paidOn,
  });
}

final calendarTasksProvider =
    FutureProvider.family<List<Task>, models.DateTimeRange>((ref, range) async {
      final repository = ref.watch(taskRepositoryProvider);
      final result = await repository.inRange(range);
      if (result.isErr) {
        throw result.failureOrNull!;
      }
      return result.valueOrNull!;
    });

final calendarBillsProvider =
    StreamProvider.family<List<CalendarBill>, DateTime>((ref, monthDate) {
      try {
        final db = ref.watch(databaseProvider);
        final startOfMonth = DateTime.utc(
          monthDate.year,
          monthDate.month,
        ).toIso8601String().substring(0, 10);
        final endOfMonth = DateTime.utc(monthDate.year, monthDate.month + 1)
            .subtract(const Duration(milliseconds: 1))
            .toIso8601String()
            .substring(0, 10);
        final nextMonth = DateTime.utc(
          monthDate.year,
          monthDate.month + 1,
        ).toIso8601String().substring(0, 10);

        final query = db.select(db.billPayments).join([
          innerJoin(db.bills, db.bills.id.equalsExp(db.billPayments.billId)),
        ]);
        query.where(
          db.bills.isActive.equals(true) &
              db.billPayments.dueOn.isBiggerOrEqualValue(startOfMonth) &
              (db.billPayments.dueOn.isSmallerOrEqualValue(endOfMonth) |
                  db.billPayments.dueOn.isSmallerThanValue(nextMonth)),
        );

        return query.watch().map((rows) {
          return rows.map((row) {
            final b = row.readTable(db.bills);
            final p = row.readTable(db.billPayments);
            return CalendarBill(
              id: b.id,
              title: b.title,
              amountCents: b.amountCents,
              dueOn: DateTime.parse(p.dueOn),
              paidOn: p.paidOn != null ? DateTime.tryParse(p.paidOn!) : null,
            );
          }).toList();
        });
      } catch (_) {
        return const Stream.empty();
      }
    });

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _currentDate;
  double _accumulatedOverscroll = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentDate = ref.read(clockProvider).todayUtc();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startOfMonth = DateTime.utc(_currentDate.year, _currentDate.month);
    final endOfMonth = DateTime.utc(
      _currentDate.year,
      _currentDate.month + 1,
    ).subtract(const Duration(milliseconds: 1));

    final startOfCalendar = startOfMonth.subtract(
      Duration(days: startOfMonth.weekday - 1),
    );
    final endOfCalendar = endOfMonth.add(
      Duration(days: 7 - endOfMonth.weekday),
    );
    final range = models.DateTimeRange(
      start: startOfCalendar,
      end: endOfCalendar,
    );

    final tasksAsync = ref.watch(calendarTasksProvider(range));
    final tasks = tasksAsync.value ?? <Task>[];

    final billsMonth = DateTime.utc(_currentDate.year, _currentDate.month);
    final billsAsync = ref.watch(calendarBillsProvider(billsMonth));
    final bills = billsAsync.value ?? <CalendarBill>[];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Mês anterior',
              button: true,
              child: IconButton(
                icon: const Icon(AppIcons.chevronLeft),
                tooltip: 'Mês anterior',
                onPressed: () {
                  setState(() {
                    _currentDate = DateTime.utc(
                      _currentDate.year,
                      _currentDate.month - 1,
                      _currentDate.day,
                    );
                  });
                },
              ),
            ),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _currentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _currentDate = DateTime.utc(
                      date.year,
                      date.month,
                      date.day,
                    );
                  });
                }
              },
              child: Text(
                '${_currentDate.month.toString().padLeft(2, '0')}/${_currentDate.year}',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Semantics(
              label: 'Próximo mês',
              button: true,
              child: IconButton(
                icon: const Icon(AppIcons.chevronRight),
                tooltip: 'Próximo mês',
                onPressed: () {
                  setState(() {
                    _currentDate = DateTime.utc(
                      _currentDate.year,
                      _currentDate.month + 1,
                      _currentDate.day,
                    );
                  });
                },
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dia'),
            Tab(text: 'Semana'),
            Tab(text: 'Mês'),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('tasks_suggestions_button'),
            icon: const Icon(AppIcons.info),
            tooltip: 'Sugestões de manutenção',
            onPressed: () => context.push('/tarefas/sugestoes'),
          ),
          IconButton(
            key: const Key('tasks_checklist_button'),
            icon: const Icon(AppIcons.checklist),
            tooltip: 'Checklist da casa',
            onPressed: () => context.push('/checklist'),
          ),
          IconButton(
            icon: const Icon(AppIcons.google),
            tooltip: 'Sincronizar com Google',
            onPressed: () async {
              final settings = ref.read(settingsRepositoryProvider);
              await settings.setCloudBackupAllowed(true);

              if (!context.mounted) return;
              final syncService = ref.read(taskSyncServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando sincronização...')),
              );

              final now = ref.read(clockProvider).nowUtc();
              final window = models.DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now.add(const Duration(days: 90)),
              );

              final res = await syncService.sync(window: window);
              if (!context.mounted) return;

              if (res.isOk) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronização concluída!')),
                );
                ref.invalidate(calendarTasksProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro: ${res.failureOrNull.toString()}'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.today),
            tooltip: 'Hoje',
            onPressed: () {
              setState(() {
                _currentDate = ref.read(clockProvider).todayUtc();
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exibindo hoje'),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Nova tarefa',
        button: true,
        child: FloatingActionButton(
          tooltip: 'Nova tarefa',
          onPressed: () async {
            final repository = ref.read(taskRepositoryProvider);
            final clock = ref.read(clockProvider);

            await showModalBottomSheet<Task>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => QuickAddTaskSheet(
                repository: repository,
                clock: clock,
                initialDate: _currentDate,
              ),
            );
            ref.invalidate(calendarTasksProvider);
          },
          child: const Icon(AppIcons.add),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.horizontal) {
            if (notification is ScrollUpdateNotification) {
              final delta = notification.scrollDelta ?? 0.0;
              if ((notification.metrics.pixels <=
                          notification.metrics.minScrollExtent &&
                      delta < 0) ||
                  (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent &&
                      delta > 0)) {
                _accumulatedOverscroll += delta;
                final parent = Scrollable.maybeOf(context);
                if (parent != null && _accumulatedOverscroll.abs() > 30) {
                  final viewport = parent.position.viewportDimension;
                  final currentPage = (parent.position.pixels / viewport)
                      .round();
                  final targetPage = _accumulatedOverscroll > 0
                      ? currentPage + 1
                      : currentPage - 1;
                  final maxPage = (parent.position.maxScrollExtent / viewport)
                      .round();
                  if (targetPage >= 0 && targetPage <= maxPage) {
                    parent.position.animateTo(
                      targetPage * viewport,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                  _accumulatedOverscroll = 0.0;
                }
              }
            } else if (notification is UserScrollNotification) {
              if (notification.direction == ScrollDirection.idle) {
                _accumulatedOverscroll = 0.0;
              }
            }
          }
          return false;
        },
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            Column(
              children: [
                if (tasks.isEmpty)
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.taskPreset,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.taskPresetsEmptyStatePrompt,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () =>
                                  context.push('/tarefas/sugestoes'),
                              child: Text(l10n.taskPresetsEmptyStateButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: DayView(
                    date: _currentDate,
                    tasks: tasks,
                    bills: bills,
                    onTapBill: (bill) {
                      context.push('/contas', extra: bill.id);
                    },
                    onToggleComplete: (task, completed) async {
                      final repo = ref.read(taskRepositoryProvider);
                      if (completed) {
                        await repo.complete(task.id);
                      } else {
                        await repo.uncomplete(task.id);
                      }
                      ref.invalidate(calendarTasksProvider);
                    },
                    onDeleteTask: (task) async {
                      final repo = ref.read(taskRepositoryProvider);
                      await repo.remove(task.id, alsoRemote: true);
                      ref.invalidate(calendarTasksProvider);
                    },
                    onEditTask: (task) => _showEditDialog(context, task),
                  ),
                ),
              ],
            ),
            WeekView(
              focusedDate: _currentDate,
              tasks: tasks,
              onDeleteTask: (task) async {
                final repo = ref.read(taskRepositoryProvider);
                await repo.remove(task.id, alsoRemote: true);
                ref.invalidate(calendarTasksProvider);
              },
              onEditTask: (task) => _showEditDialog(context, task),
            ),
            MonthView(
              focusedMonth: _currentDate,
              tasks: tasks,
              bills: bills,
              onDaySelected: (date) {
                setState(() {
                  _currentDate = date;
                  _tabController.index = 0; // Switch to Day view
                });
              },
              today: ref.read(clockProvider).todayUtc(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Task task) async {
    final titleController = TextEditingController(text: task.title);
    final notesController = TextEditingController(text: task.notes ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final repo = ref.read(taskRepositoryProvider);
      final updated = task.copyWith(
        title: titleController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      await repo.saveSyncedTask(updated);
      ref.invalidate(calendarTasksProvider);
    }
  }
}
