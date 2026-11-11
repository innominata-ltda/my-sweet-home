import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/dashboard_provider.dart';

class MonthBudgetIncome {
  final Money baseIncome;
  final Money extraIncome;

  const MonthBudgetIncome({
    this.baseIncome = const Money(0),
    this.extraIncome = const Money(0),
  });

  Money get totalBudget => Money(baseIncome.cents + extraIncome.cents);
}

final budgetsForMonthProvider = FutureProvider.family<List<Budget>, YearMonth>((
  ref,
  month,
) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final result = await repo.ofMonth(month);
  if (result.isOk) {
    return result.valueOrNull!;
  }
  return const [];
});

final incomeForMonthProvider =
    FutureProvider.family<MonthBudgetIncome, YearMonth>((ref, month) async {
      final repo = ref.watch(budgetRepositoryProvider);
      try {
        final Object dynamicRepo = repo;
        // ignore: avoid_dynamic_calls
        final dynamic result = await (dynamicRepo as dynamic).getIncome(month);
        // ignore: avoid_dynamic_calls
        if (result.isOk == true && result.valueOrNull != null) {
          // ignore: avoid_dynamic_calls
          final dynamic inc = result.valueOrNull;
          return MonthBudgetIncome(
            // ignore: avoid_dynamic_calls
            baseIncome: inc.baseIncome as Money,
            // ignore: avoid_dynamic_calls
            extraIncome: inc.extraIncome as Money,
          );
        }
      } catch (_) {}
      return const MonthBudgetIncome();
    });

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late YearMonth _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = ref.read(currentMonthProvider);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = _selectedMonth.previous;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = _selectedMonth.next;
    });
  }

  Future<void> _setBudgetLimit({
    required BuildContext context,
    CategoryId? categoryId,
    String? categoryName,
    Money? currentLimit,
  }) async {
    if (categoryId == null) {
      await _setTotalBudgetWithIncome(
        context: context,
        currentLimit: currentLimit,
      );
      return;
    }

    final textController = TextEditingController(
      text: currentLimit != null && currentLimit.cents > 0
          ? (currentLimit.cents / 100).toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );

    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Orçamento para $categoryName'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Limite em R\$ * (ex: 500,00)',
              prefixText: 'R\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o valor';
              final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
              if (parsed == null || parsed < 0) return 'Valor inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final val = double.parse(textController.text.trim().replaceAll(',', '.'));
      final cents = (val * 100).round();
      final repo = ref.read(budgetRepositoryProvider);

      await repo.setLimit(_selectedMonth, categoryId, Money(cents));
      ref.invalidate(budgetsForMonthProvider(_selectedMonth));
      ref.invalidate(dashboardSummaryProvider(_selectedMonth));
    }
  }

  Future<void> _setTotalBudgetWithIncome({
    required BuildContext context,
    Money? currentLimit,
  }) async {
    final repo = ref.read(budgetRepositoryProvider);
    String initialBase = '';
    String initialExtra = '';

    try {
      final Object dynamicRepo = repo;
      // ignore: avoid_dynamic_calls
      final dynamic res = await (dynamicRepo as dynamic).getIncome(
        _selectedMonth,
      );
      // ignore: avoid_dynamic_calls
      if (res.isOk == true && res.valueOrNull != null) {
        // ignore: avoid_dynamic_calls
        final dynamic inc = res.valueOrNull;
        // ignore: avoid_dynamic_calls
        final base = inc.baseIncome as Money;
        // ignore: avoid_dynamic_calls
        final extra = inc.extraIncome as Money;
        if (base.cents > 0) {
          initialBase = (base.cents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }
        if (extra.cents > 0) {
          initialExtra = (extra.cents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }
      }
    } catch (_) {
      if (currentLimit != null && currentLimit.cents > 0) {
        initialBase = (currentLimit.cents / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
    }

    final baseController = TextEditingController(text: initialBase);
    final extraController = TextEditingController(text: initialExtra);
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final baseVal =
              double.tryParse(
                baseController.text.trim().replaceAll(',', '.'),
              ) ??
              0.0;
          final extraVal =
              double.tryParse(
                extraController.text.trim().replaceAll(',', '.'),
              ) ??
              0.0;
          final totalCents = ((baseVal + extraVal) * 100).round();
          final totalMoney = Money(totalCents);

          return AlertDialog(
            title: Text('Orçamento Total de ${_selectedMonth.iso}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('baseIncomeField'),
                      controller: baseController,
                      decoration: const InputDecoration(
                        labelText: 'Receita base recorrente *',
                        hintText: 'ex: 3000,00',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      validator: (v) {
                        if ((v == null || v.trim().isEmpty) &&
                            extraController.text.trim().isEmpty) {
                          return 'Informe ao menos uma receita';
                        }
                        if (v != null && v.trim().isNotEmpty) {
                          final parsed = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Valor inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('extraIncomeField'),
                      controller: extraController,
                      decoration: const InputDecoration(
                        labelText: 'Receitas adicionais avulsas no mês',
                        hintText: 'ex: 500,00',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final parsed = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Valor inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      key: const Key('totalBudgetSummaryBox'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soma total do orçamento:',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalMoney.formatPtBr(),
                            key: const Key('totalBudgetText'),
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(ctx).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final baseVal =
          double.tryParse(baseController.text.trim().replaceAll(',', '.')) ??
          0.0;
      final extraVal =
          double.tryParse(extraController.text.trim().replaceAll(',', '.')) ??
          0.0;
      final baseCents = (baseVal * 100).round();
      final extraCents = (extraVal * 100).round();

      var savedViaIncome = false;
      try {
        final Object dynamicRepo = repo;
        // ignore: avoid_dynamic_calls
        await (dynamicRepo as dynamic).saveIncome(
          month: _selectedMonth,
          baseIncome: Money(baseCents),
          extraIncome: Money(extraCents),
        );
        savedViaIncome = true;
      } catch (_) {}

      if (!savedViaIncome) {
        await repo.setLimit(
          _selectedMonth,
          null,
          Money(baseCents + extraCents),
        );
      }

      ref.invalidate(budgetsForMonthProvider(_selectedMonth));
      ref.invalidate(incomeForMonthProvider(_selectedMonth));
      ref.invalidate(dashboardSummaryProvider(_selectedMonth));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(budgetsForMonthProvider(_selectedMonth));
    final incomeAsync = ref.watch(incomeForMonthProvider(_selectedMonth));
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    final budgets = budgetsAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];

    final overallBudget = budgets.where((b) => b.category == null).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamento'),
        leading: Semantics(
          label: 'Voltar',
          button: true,
          child: IconButton(
            icon: const Icon(AppIcons.back),
            tooltip: 'Voltar',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/despesas');
              }
            },
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 80.0,
        ),
        children: [
          // Month selector
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Mês anterior',
                    button: true,
                    child: IconButton(
                      icon: const Icon(AppIcons.chevronLeft),
                      tooltip: 'Mês anterior',
                      onPressed: _previousMonth,
                    ),
                  ),
                  Text(
                    _selectedMonth.iso,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Semantics(
                    label: 'Próximo mês',
                    button: true,
                    child: IconButton(
                      icon: const Icon(AppIcons.chevronRight),
                      tooltip: 'Próximo mês',
                      onPressed: _nextMonth,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Total Budget Card
          AppCard(
            child: InkWell(
              onTap: () => _setTotalBudgetWithIncome(
                context: context,
                currentLimit: overallBudget?.limit,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Orçamento Total do Mês',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.edit, size: 20),
                          tooltip: 'Editar receita e orçamento',
                          onPressed: () => _setTotalBudgetWithIncome(
                            context: context,
                            currentLimit: overallBudget?.limit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overallBudget != null
                          ? overallBudget.limit.formatPtBr()
                          : (incomeAsync.asData?.value != null &&
                                incomeAsync.asData!.value.totalBudget.cents > 0)
                          ? incomeAsync.asData!.value.totalBudget.formatPtBr()
                          : 'Nenhum limite definido',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color:
                            (overallBudget != null ||
                                (incomeAsync.asData?.value != null &&
                                    incomeAsync
                                            .asData!
                                            .value
                                            .totalBudget
                                            .cents >
                                        0))
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (incomeAsync.asData?.value != null &&
                        (incomeAsync.asData!.value.baseIncome.cents > 0 ||
                            incomeAsync.asData!.value.extraIncome.cents >
                                0)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Base: ${incomeAsync.asData!.value.baseIncome.formatPtBr()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Extras: ${incomeAsync.asData!.value.extraIncome.formatPtBr()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Budgets Section
          Text(
            'Limites por Categoria',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),

          if (categoriesAsync.isLoading || budgetsAsync.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhuma categoria cadastrada.'),
            )
          else
            ...categories.map((cat) {
              final catBudget = budgets
                  .where((b) => b.category == cat.id)
                  .firstOrNull;

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(AppIcons.budget, size: 20),
                  ),
                  title: Text(cat.name),
                  subtitle: Text(
                    catBudget != null
                        ? 'Limite: ${catBudget.limit.formatPtBr()}'
                        : 'Sem limite definido',
                    style: TextStyle(
                      color: catBudget != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(AppIcons.edit, size: 20),
                    tooltip: 'Definir limite',
                    onPressed: () => _setBudgetLimit(
                      context: context,
                      categoryId: cat.id,
                      categoryName: cat.name,
                      currentLimit: catBudget?.limit,
                    ),
                  ),
                  onTap: () => _setBudgetLimit(
                    context: context,
                    categoryId: cat.id,
                    categoryName: cat.name,
                    currentLimit: catBudget?.limit,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
