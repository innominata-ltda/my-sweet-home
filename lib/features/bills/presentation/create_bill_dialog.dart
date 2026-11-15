import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
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
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    return AlertDialog(
      title: Text(l10n.billsNewDialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.billsTitleFieldLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.billsTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.billsAmountFieldLabel,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.commonEnterAmount
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDayController,
                decoration: InputDecoration(
                  labelText: l10n.billsDueDayFieldLabel,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final day = int.tryParse(v ?? '');
                  if (day == null || day < 1 || day > 31) {
                    return l10n.billsDueDayInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _recurrenceCycle,
                decoration: InputDecoration(
                  labelText: l10n.billsFrequencyLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'FREQ=MONTHLY;INTERVAL=1',
                    child: Text(l10n.billsFrequencyMonthly),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=WEEKLY;INTERVAL=2',
                    child: Text(l10n.billsFrequencyBiweekly),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=WEEKLY;INTERVAL=1',
                    child: Text(l10n.billsFrequencyWeekly),
                  ),
                  DropdownMenuItem(
                    value: 'FREQ=YEARLY;INTERVAL=1',
                    child: Text(l10n.billsFrequencyAnnual),
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
                  decoration: InputDecoration(
                    labelText: l10n.billsCategoryLabel,
                  ),
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
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(l10n.billsSaveButton)),
      ],
    );
  }
}
