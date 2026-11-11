import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

class QuickAddTaskSheet extends StatefulWidget {
  final TaskRepository repository;
  final Clock clock;
  final DateTime initialDate;
  final TaskDraft? initialDraft;
  final Task? initialTask;

  const QuickAddTaskSheet({
    super.key,
    required this.repository,
    required this.clock,
    required this.initialDate,
    this.initialDraft,
    this.initialTask,
  });

  @override
  State<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends State<QuickAddTaskSheet> {
  final _titleController = TextEditingController();
  final _customDaysController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _allDay = true;
  String? _selectedRecurrenceOption;
  String? _customDaysError;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    final task = widget.initialTask;

    if (draft != null) {
      _titleController.text = draft.title;
      _selectedDate = draft.firstOccurrence;
      _allDay = draft.allDay;
      _parseRecurrence(draft.rrule);
    } else if (task != null) {
      _titleController.text = task.title;
      _selectedDate = task.dueAt ?? widget.initialDate;
      if (task.dueAt != null) {
        final local = task.dueAt!.toLocal();
        _selectedTime = TimeOfDay(hour: local.hour, minute: local.minute);
      }
      _allDay = task.allDay;
      _parseRecurrence(task.recurringRuleId);
    } else {
      _selectedDate = widget.initialDate;
    }
  }

  void _parseRecurrence(String? rrule) {
    if (rrule == null || rrule.isEmpty) {
      _selectedRecurrenceOption = null;
      return;
    }
    if (rrule == 'FREQ=DAILY') {
      _selectedRecurrenceOption = 'FREQ=DAILY';
      return;
    }
    if (rrule.startsWith('FREQ=DAILY;INTERVAL=')) {
      final intervalStr = rrule.split('INTERVAL=').last.split(';').first;
      final interval = int.tryParse(intervalStr);
      if (interval != null && interval > 1) {
        _selectedRecurrenceOption = 'CUSTOM_DAYS';
        _customDaysController.text = interval.toString();
        return;
      } else if (interval == 1) {
        _selectedRecurrenceOption = 'FREQ=DAILY';
        return;
      }
    }
    if (rrule == 'FREQ=WEEKLY') {
      _selectedRecurrenceOption = 'FREQ=WEEKLY';
      return;
    }
    if (rrule == 'FREQ=MONTHLY') {
      _selectedRecurrenceOption = 'FREQ=MONTHLY';
      return;
    }
    _selectedRecurrenceOption = rrule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  String _formatRecurrenceLabel(String rrule) {
    if (rrule == 'FREQ=DAILY;INTERVAL=7') return 'Semanalmente (a cada 7 dias)';
    if (rrule.startsWith('FREQ=DAILY;INTERVAL=')) {
      final interval = rrule.split('INTERVAL=').last;
      return 'A cada $interval dias';
    }
    if (rrule.startsWith('FREQ=WEEKLY;INTERVAL=')) {
      final interval = rrule.split('INTERVAL=').last;
      return 'A cada $interval semanas';
    }
    if (rrule.startsWith('FREQ=MONTHLY;INTERVAL=')) {
      final interval = rrule.split('INTERVAL=').last;
      return 'A cada $interval meses';
    }
    return rrule;
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    String? recurrenceRule;
    if (_selectedRecurrenceOption == 'CUSTOM_DAYS') {
      final text = _customDaysController.text.trim();
      final days = int.tryParse(text);
      if (text.isEmpty || days == null || days < 1 || days > 365) {
        setState(() {
          _customDaysError = 'Informe um valor entre 1 e 365 dias';
        });
        return;
      }
      _customDaysError = null;
      recurrenceRule = 'FREQ=DAILY;INTERVAL=$days';
    } else {
      recurrenceRule = _selectedRecurrenceOption;
    }

    DateTime dueAt;
    if (_allDay) {
      dueAt = DateTime.utc(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
    } else {
      final local = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      dueAt = local.toUtc();
    }

    if (widget.initialTask != null) {
      final updated = widget.initialTask!.copyWith(
        title: title,
        dueAt: dueAt,
        allDay: _allDay,
        recurringRuleId: recurrenceRule,
        updatedAt: widget.clock.nowUtc(),
      );
      final result = await widget.repository.saveSyncedTask(updated);
      result.fold(
        (ok) {
          if (mounted) Navigator.of(context).pop(ok);
        },
        (err) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.taskQuickAddError(err.toString()))),
            );
          }
        },
      );
      return;
    }

    final task = NewTask(
      title: title,
      dueAt: dueAt,
      allDay: _allDay,
      recurringRuleId: recurrenceRule,
      sourcePresetId: widget.initialDraft?.sourcePresetId,
      categoryId: widget.initialDraft?.categoryId,
    );

    final result = await widget.repository.upsert(task);
    result.fold(
      (ok) {
        if (mounted) Navigator.of(context).pop(ok);
      },
      (err) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.taskQuickAddError(err.toString()))),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.taskQuickAddTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '${l10n.taskQuickAddPlaceholder} *',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(AppIcons.calendar, size: 16),
                    label: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!_allDay)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(AppIcons.time, size: 16),
                      label: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dia inteiro'),
              value: _allDay,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _allDay = val;
                  });
                }
              },
            ),
            DropdownButtonFormField<String?>(
              initialValue: _selectedRecurrenceOption,
              decoration: const InputDecoration(labelText: 'Repetição'),
              items: [
                const DropdownMenuItem(child: Text('Sem repetição')),
                const DropdownMenuItem(
                  value: 'FREQ=DAILY',
                  child: Text('Diariamente'),
                ),
                const DropdownMenuItem(
                  value: 'CUSTOM_DAYS',
                  child: Text('A cada X dias'),
                ),
                const DropdownMenuItem(
                  value: 'FREQ=WEEKLY',
                  child: Text('Semanalmente'),
                ),
                const DropdownMenuItem(
                  value: 'FREQ=MONTHLY',
                  child: Text('Mensalmente'),
                ),
                if (_selectedRecurrenceOption != null &&
                    !const [
                      'FREQ=DAILY',
                      'CUSTOM_DAYS',
                      'FREQ=WEEKLY',
                      'FREQ=MONTHLY',
                    ].contains(_selectedRecurrenceOption))
                  DropdownMenuItem(
                    value: _selectedRecurrenceOption,
                    child: Text(
                      _formatRecurrenceLabel(_selectedRecurrenceOption!),
                    ),
                  ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedRecurrenceOption = val;
                  if (val != 'CUSTOM_DAYS') {
                    _customDaysError = null;
                  }
                });
              },
            ),
            if (_selectedRecurrenceOption == 'CUSTOM_DAYS') ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: TextField(
                  key: const Key('quick_add_custom_days_field'),
                  controller: _customDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade de dias *',
                    errorText: _customDaysError,
                  ),
                  onChanged: (_) {
                    if (_customDaysError != null) {
                      setState(() {
                        _customDaysError = null;
                      });
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _save,
                  child: Text(l10n.taskQuickAddSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
