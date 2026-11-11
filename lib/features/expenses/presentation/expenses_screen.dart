import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_undo_snack_bar.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/dashboard_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/widgets/expenses_dashboard.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  String _formatMonthYear(YearMonth ym) {
    final parts = ym.iso.split('-');
    if (parts.length != 2) return ym.iso;
    final year = parts[0];
    const monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final mIndex = int.tryParse(parts[1]) ?? 1;
    final name = (mIndex >= 1 && mIndex <= 12)
        ? monthNames[mIndex - 1]
        : parts[1];
    return '$name de $year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selectedMonth = ref.watch(selectedYearMonthProvider);
    final YearMonth currentMonth =
        selectedMonth ?? ref.watch(currentMonthProvider);
    final expenseListAsync = ref.watch(expenseListProvider(currentMonth));

    final categories =
        ref.watch(expenseCategoriesProvider).asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(AppIcons.chevronLeft, size: 20),
              tooltip: 'Mês anterior',
              onPressed: () {
                ref
                    .read(selectedYearMonthProvider.notifier)
                    .setMonth(currentMonth.previous);
              },
            ),
            Text(
              _formatMonthYear(currentMonth),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(AppIcons.chevronRight, size: 20),
              tooltip: 'Próximo mês',
              onPressed: () {
                ref
                    .read(selectedYearMonthProvider.notifier)
                    .setMonth(currentMonth.next);
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('expenses_economy_button'),
            icon: const Icon(AppIcons.economy),
            tooltip: 'Modo economia',
            onPressed: () => context.push('/economia'),
          ),
          IconButton(
            key: const Key('expenses_budget_button'),
            icon: const Icon(AppIcons.budget),
            tooltip: 'Orçamento do mês',
            onPressed: () async {
              await context.push('/orcamento');
              ref.invalidate(dashboardSummaryProvider(currentMonth));
              ref.invalidate(currentMonthProvider);
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.bill),
            tooltip: 'Compras e Notas Fiscais',
            onPressed: () => context.push('/compras'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: ExpensesDashboard()),
          ...expenseListAsync.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, stack) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(loc.expensesError)),
              ),
            ],
            data: (expenses) {
              if (expenses.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: AppEmptyState.mascot(
                        title: loc.expensesEmpty,
                        description: loc.expensesEmptyCallToAction,
                        mascotSemanticLabel: loc.momoEmptyExpenses,
                      ),
                    ),
                  ),
                ];
              }

              return [
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final expense = expenses[index];
                    final catName = categories
                        .where((c) => c.id == expense.categoryId)
                        .firstOrNull
                        ?.name;
                    final subtitleParts = <String>[];
                    if (catName != null) {
                      subtitleParts.add(catName);
                    }
                    if (expense.notes != null && expense.notes!.isNotEmpty) {
                      subtitleParts.add(expense.notes!);
                    }
                    subtitleParts.add(
                      expense.occurredOn.toIso8601String().substring(0, 10),
                    );

                    return Dismissible(
                      key: ValueKey(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(AppIcons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir despesa?'),
                                content: const Text(
                                  'Tem certeza de que deseja excluir esta despesa?',
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
                            ) ??
                            false;
                      },
                      onDismissed: (direction) async {
                        final ticket = await ref
                            .read(expenseListProvider(currentMonth).notifier)
                            .removeExpense(expense.id);
                        if (ticket != null && context.mounted) {
                          AppUndoSnackBar.show(
                            context,
                            message: loc.expenseDeleted,
                            onUndo: () {
                              ref
                                  .read(
                                    expenseListProvider(currentMonth).notifier,
                                  )
                                  .undoRemoveExpense(ticket);
                            },
                          );
                        }
                      },
                      child: ListTile(
                        title: Text(
                          expense.description != null &&
                                  expense.description!.isNotEmpty
                              ? '${expense.description!} — ${expense.amount.formatPtBr()}'
                              : expense.amount.formatPtBr(),
                        ),
                        subtitle: Text(subtitleParts.join(' • ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (expense.purchaseId != null)
                              IconButton(
                                icon: const Icon(AppIcons.purchase),
                                tooltip: 'Ver Compra / Nota',
                                onPressed: () => context.push('/compras'),
                              ),
                            if (expense.billId != null)
                              IconButton(
                                icon: const Icon(AppIcons.bill),
                                tooltip: 'Ver Conta',
                                onPressed: () => context.push('/contas'),
                              ),
                          ],
                        ),
                        onTap: () async {
                          final result = await context.push(
                            '/despesas/nova',
                            extra: expense,
                          );
                          if (result is TrashTicket && context.mounted) {
                            AppUndoSnackBar.show(
                              context,
                              message: loc.expenseDeleted,
                              onUndo: () {
                                ref
                                    .read(
                                      expenseListProvider(currentMonth)
                                          .notifier,
                                    )
                                    .undoRemoveExpense(result);
                              },
                            );
                          }
                          ref.invalidate(expenseListProvider(currentMonth));
                          ref.invalidate(
                            dashboardSummaryProvider(currentMonth),
                          );
                        },
                      ),
                    );
                  }, childCount: expenses.length),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/despesas/nova');
          ref.invalidate(expenseListProvider(currentMonth));
          ref.invalidate(dashboardSummaryProvider(currentMonth));
        },
        tooltip: loc.expenseQuickAddTitle,
        child: const Icon(AppIcons.add),
      ),
    );
  }
}
