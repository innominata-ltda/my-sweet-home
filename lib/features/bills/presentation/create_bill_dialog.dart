import 'package:flutter/material.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

class CreateBillDialog extends StatefulWidget {
  const CreateBillDialog({
    super.key,
    required this.onSave,
    this.categories = const [],
    this.initialCategoryId,
  });

  final void Function(
    String title,
    int amountCents,
    int dueDay,
    CategoryId categoryId, [
    RecurrenceRule? recurrence,
  ])
  onSave;
  final List<Category> categories;
  final CategoryId? initialCategoryId;

  @override
  State<CreateBillDialog> createState() => _CreateBillDialogState();
}

class _CreateBillDialogState extends State<CreateBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDayController = TextEditingController(text: '10');
  late CategoryId _selectedCategoryId;
  String _recurrenceCycle = 'FREQ=MONTHLY;INTERVAL=1';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId =
        widget.initialCategoryId ??
        (widget.categories.isNotEmpty
            ? widget.categories.first.id
            : const CategoryId('cat_housing'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final amountCents =
          (double.parse(_amountController.text.replaceAll(',', '.')) * 100)
              .toInt();
      final dueDay = int.parse(_dueDayController.text);
      final recurrence =
          RecurrenceRule.tryParse(_recurrenceCycle) ??
          RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!;
      widget.onSave(
        title,
        amountCents,
        dueDay,
        _selectedCategoryId,
        recurrence,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Conta a Vencer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título * (ex: Aluguel, Luz, Internet)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor em R\$ * (ex: 150.00)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDayController,
                decoration: const InputDecoration(
                  labelText: 'Dia do Vencimento * (1 a 31)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final day = int.tryParse(v ?? '');
                  if (day == null || day < 1 || day > 31) {
                    return 'Informe um dia entre 1 e 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _recurrenceCycle,
                decoration: const InputDecoration(
                  labelText: 'Frequência da Conta',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'FREQ=MONTHLY;INTERVAL=1',
                    child: Text('Mensal'),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=WEEKLY;INTERVAL=2',
                    child: Text('Quinzenal'),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=WEEKLY;INTERVAL=1',
                    child: Text('Semanal'),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=YEARLY;INTERVAL=1',
                    child: Text('Anual'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _recurrenceCycle = val;
                    });
                  }
                },
              ),
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<CategoryId>(
                  initialValue:
                      widget.categories.any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : widget.categories.first.id,
                  decoration: const InputDecoration(labelText: 'Categoria *'),
                  items: widget.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (catId) {
                    if (catId != null) {
                      setState(() {
                        _selectedCategoryId = catId;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Salvar Conta')),
      ],
    );
  }
}
