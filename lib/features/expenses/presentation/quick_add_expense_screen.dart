import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';

class QuickAddExpenseScreen extends StatefulWidget {
  final ExpenseRepository repository;
  final Clock clock;
  final List<Category> categories; // Default or provided
  final Expense? initialExpense;
  final DateTime? initialDate;
  final bool initialRecurring;

  const QuickAddExpenseScreen({
    super.key,
    required this.repository,
    required this.clock,
    required this.categories,
    this.initialExpense,
    this.initialDate,
    this.initialRecurring = false,
  });

  @override
  State<QuickAddExpenseScreen> createState() => _QuickAddExpenseScreenState();
}

class _QuickAddExpenseScreenState extends State<QuickAddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  int _cents = 0;
  CategoryId? _selectedCategoryId;
  late DateTime _selectedDate;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _customDaysController;
  bool _isRecurring = false;
  String _recurrenceType = 'FREQ=MONTHLY';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialExpense?.description ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialExpense?.notes ?? '',
    );
    _customDaysController = TextEditingController();

    final localNow = widget.clock.nowUtc().toLocal();
    _selectedDate =
        widget.initialExpense?.occurredOn ??
        widget.initialDate ??
        DateTime(localNow.year, localNow.month, localNow.day);

    if (widget.initialExpense != null) {
      _cents = widget.initialExpense!.amount.cents;
      _selectedCategoryId = widget.initialExpense!.categoryId;
      if (widget.initialExpense!.recurringRuleId != null) {
        _isRecurring = true;
        _loadInitialRecurrence(widget.initialExpense!.recurringRuleId!);
      }
    } else if (widget.initialRecurring) {
      _isRecurring = true;
    }
  }

  void _loadInitialRecurrence(String ruleId) async {
    final rrule = await widget.repository.getRecurringRrule(ruleId);
    if (rrule != null && mounted) {
      setState(() {
        if (rrule.startsWith('FREQ=DAILY;INTERVAL=')) {
          _recurrenceType = 'custom_days';
          _customDaysController.text = rrule
              .split('INTERVAL=')
              .last
              .split(';')
              .first;
        } else if (rrule == 'FREQ=DAILY' ||
            rrule == 'FREQ=WEEKLY' ||
            rrule == 'FREQ=MONTHLY') {
          _recurrenceType = rrule;
        } else {
          _recurrenceType = 'custom_days';
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    if (_cents <= 0) return;
    final amount = Money(_cents);

    final occurredOn = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final desc = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    final expense = NewExpense(
      amount: amount,
      occurredOn: occurredOn,
      description: desc.isNotEmpty ? desc : null,
      notes: notes.isNotEmpty ? notes : null,
      categoryId: _selectedCategoryId,
      billId: widget.initialExpense?.billId,
      purchaseId: widget.initialExpense?.purchaseId,
    );

    String? rrule;
    if (_isRecurring) {
      if (_recurrenceType == 'custom_days') {
        final days = int.parse(_customDaysController.text.trim());
        rrule = 'FREQ=DAILY;INTERVAL=$days';
      } else {
        rrule = _recurrenceType;
      }
    }

    final repo = widget.repository;
    final Future<Result<Expense, Failure>> saveFuture;
    if (widget.initialExpense != null) {
      saveFuture = repo.update(
        widget.initialExpense!.id,
        expense,
        rrule: rrule,
      );
    } else {
      saveFuture = repo.add(expense, rrule: rrule);
    }

    final result = await saveFuture;

    result.fold(
      (ok) {
        if (mounted) Navigator.of(context).pop(ok);
      },
      (err) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.expenseQuickAddError(err.toString()))),
          );
        }
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir despesa?'),
            content: const Text(
              'Tem certeza de que deseja excluir esta despesa?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted && widget.initialExpense != null) {
      final result = await widget.repository.remove(widget.initialExpense!.id);
      result.fold(
        (ticket) {
          if (mounted) Navigator.of(context).pop(ticket);
        },
        (err) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.expenseQuickAddError(err.toString())),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initialExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Despesa' : l10n.expenseQuickAddTitle),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(AppIcons.delete),
              tooltip: 'Excluir despesa',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppMoneyField(
                autofocus: true,
                label: 'Valor *',
                initialCents: widget.initialExpense?.amount.cents,
                onChanged: (cents) => setState(() => _cents = cents),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Nome / Descrição',
                  hintText: 'ex.: Supermercado, Aluguel, Farmácia',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Detalhes adicionais...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('expense_date_picker_button'),
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
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('repeat_switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Repetir despesa'),
                value: _isRecurring,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val;
                  });
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('recurrence_type_dropdown'),
                  initialValue: _recurrenceType,
                  decoration: const InputDecoration(
                    labelText: 'Frequência de repetição',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'FREQ=MONTHLY',
                      child: Text('Mensalmente'),
                    ),
                    DropdownMenuItem(
                      value: 'FREQ=WEEKLY',
                      child: Text('Semanalmente'),
                    ),
                    DropdownMenuItem(
                      value: 'FREQ=DAILY',
                      child: Text('Diariamente'),
                    ),
                    DropdownMenuItem(
                      value: 'custom_days',
                      child: Text('A cada X dias'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _recurrenceType = val;
                      });
                    }
                  },
                ),
                if (_recurrenceType == 'custom_days') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('custom_days_field'),
                    controller: _customDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de dias *',
                      hintText: 'ex.: 4',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isRecurring || _recurrenceType != 'custom_days') {
                        return null;
                      }
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Informe a quantidade de dias (entre 1 e 365)';
                      }
                      final days = int.tryParse(trimmed);
                      if (days == null || days < 1 || days > 365) {
                        return 'Informe um número de dias válido entre 1 e 365';
                      }
                      return null;
                    },
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: widget.categories.map((c) {
                  final isSelected = _selectedCategoryId == c.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? c.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cents > 0 ? _save : null,
                child: Text(l10n.expenseQuickAddSave),
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(AppIcons.delete),
                  label: const Text('Excluir despesa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
