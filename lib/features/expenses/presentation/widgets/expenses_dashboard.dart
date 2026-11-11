import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/dashboard_provider.dart';

class ExpensesDashboard extends ConsumerWidget {
  const ExpensesDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selectedMonth = ref.watch(selectedYearMonthProvider);
    final YearMonth currentMonth =
        selectedMonth ?? ref.watch(currentMonthProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider(currentMonth));
    final categories =
        ref.watch(expenseCategoriesProvider).asData?.value ?? const [];

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.expensesError),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(dashboardSummaryProvider(currentMonth)),
              child: Text(loc.expensesRetry),
            ),
          ],
        ),
      ),
      data: (summary) {
        if (summary == null ||
            (summary.actual == Money.zero && summary.budget == null)) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.expensesEmptyCallToAction),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/despesas/nova'),
                      child: Text(loc.expensesLaunchFirst),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await context.push('/orcamento');
                        ref.invalidate(dashboardSummaryProvider(currentMonth));
                        ref.invalidate(currentMonthProvider);
                      },
                      child: Text(loc.expensesSetBudget),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final actual = summary.actual;
        final budget = summary.budget;
        final remaining = summary.remaining;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (budget != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          loc.expensesBudgetSet(budget.formatPtBr()),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.edit),
                        tooltip: 'Editar Orçamento',
                        onPressed: () async {
                          await context.push('/orcamento');
                          ref.invalidate(
                            dashboardSummaryProvider(currentMonth),
                          );
                          ref.invalidate(currentMonthProvider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.expensesTotal(actual.formatPtBr()),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (remaining != null) ...[
                    if (remaining.cents < 0)
                      Text(
                        loc.expensesOverBudget(
                          Money(remaining.cents.abs()).formatPtBr(),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.red),
                      )
                    else
                      Text(
                        loc.expensesRemaining(remaining.formatPtBr()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ] else ...[
                  Text(
                    loc.expensesTotal(actual.formatPtBr()),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(loc.expensesNoBudgetInvite),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await context.push('/orcamento');
                      ref.invalidate(dashboardSummaryProvider(currentMonth));
                    },
                    child: Text(loc.expensesSetBudget),
                  ),
                ],

                const SizedBox(height: 16),

                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: budget != null && budget.cents > 0
                        ? (actual.cents / budget.cents).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remaining != null && remaining.cents < 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),

                if (summary.byCategory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(loc.expensesByCategoryTitle),
                    children: summary.byCategory.map((slice) {
                      final percent = actual.cents > 0
                          ? ((slice.actual.cents / actual.cents) * 100)
                                .toStringAsFixed(1)
                          : '0.0';
                      final catName =
                          categories
                              .where((c) => c.id == slice.categoryId)
                              .firstOrNull
                              ?.name ??
                          slice.categoryId.value;
                      return Semantics(
                        label: loc.expensesChartCategoryAlt(
                          catName,
                          slice.actual.formatPtBr(),
                          percent,
                        ),
                        child: ListTile(
                          title: Text(catName),
                          trailing: Text(
                            '${slice.actual.formatPtBr()} ($percent%)',
                          ),
                          dense: true,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                if (summary.monthsOfHistory < 2) ...[
                  Text(
                    loc.expensesForecastNoHistory,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    loc.expensesForecastExplanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  Text(
                    loc.expensesForecastTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(loc.expensesForecastAmount(actual.formatPtBr())),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
