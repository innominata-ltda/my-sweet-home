import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_customize_sheet.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/recipes_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_providers.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/core/update/app_update_providers.dart';
import 'package:my_sweet_home/core/update/update_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdatesSilently();
    });
  }

  Future<void> _checkUpdatesSilently() async {
    try {
      if (!mounted) return;
      final service = ref.read(appUpdateServiceProvider);
      final updateInfo = await service.checkSilentlyForDashboard();
      if (!mounted || updateInfo == null) return;

      await showAppUpdateDialog(
        context: context,
        updateInfo: updateInfo,
        service: service,
      );
    } catch (_) {
      // Silenciosamente ignorado conforme RN-041
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mascotConfigAsync = ref.watch(mascotConfigStreamProvider);
    final mascotConfig =
        mascotConfigAsync.asData?.value ?? MascotConfig.defaultMomo;

    final monthController = ref.watch(
      monthBalanceWidgetControllerProvider(
        MonthBalanceWidgetParams(
          monthSummaryRepository: ref.watch(monthSummaryRepositoryProvider),
        ),
      ),
    );

    final dueBillsController = ref.watch(
      dueBillsWidgetControllerProvider(
        DueBillsWidgetParams(
          billRepository: ref.watch(billRepositoryProvider),
          paymentRepository: ref.watch(billPaymentRepositoryProvider),
        ),
      ),
    );

    final todayTasksController = ref.watch(
      todayTasksWidgetControllerProvider(
        TodayTasksWidgetParams(
          taskRepository: ref.watch(taskRepositoryProvider),
        ),
      ),
    );

    final shoppingListController = ref.watch(
      shoppingListWidgetControllerProvider(
        ShoppingListWidgetParams(
          shoppingListRepository: ref.watch(shoppingListRepositoryProvider),
        ),
      ),
    );

    final layoutController = ref.watch(dashboardLayoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sweet Home'),
        actions: [
          Semantics(
            label: 'Busca',
            button: true,
            child: IconButton(
              key: const Key('global_search_button'),
              icon: const Icon(AppIcons.search),
              tooltip: 'Busca global',
              onPressed: () => context.push('/busca'),
            ),
          ),
          Semantics(
            label: l10n.customizeDashboardAction,
            button: true,
            child: IconButton(
              key: const Key('customize_dashboard_button'),
              icon: const Icon(AppIcons.customizeDashboard),
              tooltip: l10n.customizeDashboardAction,
              onPressed: () => _openCustomizeSheet(context, layoutController),
            ),
          ),
          Semantics(
            label: 'Ajustes',
            button: true,
            child: IconButton(
              icon: const Icon(AppIcons.settings),
              tooltip: 'Ajustes',
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            monthController.load(),
            dueBillsController.load(),
            todayTasksController.load(),
            shoppingListController.load(),
            layoutController.load(),
          ]);
        },
        child: ListenableBuilder(
          listenable: Listenable.merge([
            monthController,
            todayTasksController,
            layoutController,
          ]),
          builder: (context, _) {
            final monthState = monthController.value;
            final tasksState = todayTasksController.value;
            final layoutState = layoutController.value;

            final visibleItems = layoutState is DashboardLayoutLoaded
                ? layoutState.visibleItems
                : DashboardLayoutConfig.defaultOrder;

            final budgetExpression = _resolveBudgetMascotExpression(monthState);

            if (visibleItems.isEmpty) {
              return ListView(
                padding: const EdgeInsets.only(
                  left: Spacing.md,
                  top: Spacing.md,
                  right: Spacing.md,
                  bottom: Spacing.xxl + 48,
                ),
                children: [
                  AppEmptyState(
                    key: const Key('dashboard_empty_state'),
                    icon: AppIcons.customizeDashboard,
                    title: l10n.customizeDashboardEmptyTitle,
                    description: 'Personalize seu painel inicial adicionando os módulos que desejar.',
                    actionLabel: l10n.customizeDashboardEmptyAction,
                    onAction: () =>
                        _openCustomizeSheet(context, layoutController),
                  ),
                ],
              );
            }

            final itemsWidgets = <Widget>[];
            for (int i = 0; i < visibleItems.length; i++) {
              final kind = visibleItems[i];
              final widget = _buildDashboardItem(
                context: context,
                kind: kind,
                mascotConfig: mascotConfig,
                monthState: monthState,
                tasksState: tasksState,
                monthController: monthController,
                dueBillsController: dueBillsController,
                todayTasksController: todayTasksController,
                shoppingListController: shoppingListController,
                budgetExpression: budgetExpression,
                l10n: l10n,
              );
              if (widget != null) {
                if (itemsWidgets.isNotEmpty) {
                  itemsWidgets.add(const SizedBox(height: Spacing.md));
                }
                itemsWidgets.add(widget);
              }
            }

            return ListView(
              padding: const EdgeInsets.only(
                left: Spacing.md,
                top: Spacing.md,
                right: Spacing.md,
                bottom: Spacing.xxl + 48,
              ),
              children: itemsWidgets,
            );
          },
        ),
      ),
    );
  }

  void _openCustomizeSheet(
    BuildContext context,
    DashboardLayoutController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DashboardCustomizeSheet(controller: controller),
    );
  }

  Widget? _buildDashboardItem({
    required BuildContext context,
    required DashboardItemKind kind,
    required MascotConfig mascotConfig,
    required MonthBalanceWidgetState monthState,
    required TodayTasksWidgetState tasksState,
    required MonthBalanceWidgetController monthController,
    required DueBillsWidgetController dueBillsController,
    required TodayTasksWidgetController todayTasksController,
    required ShoppingListWidgetController shoppingListController,
    required MascotExpression budgetExpression,
    required AppLocalizations l10n,
  }) {
    switch (kind) {
      case DashboardItemKind.mascotGreeting:
        return DashboardMascotGreeting(
          config: mascotConfig,
          monthState: monthState,
          tasksState: tasksState,
        );
      case DashboardItemKind.monthBalance:
        return MonthBalanceWidget(
          controller: monthController,
          title: l10n.dashboardMonthBalanceTitle,
          mascot: MascotWidget(
            config: mascotConfig,
            expression: budgetExpression,
            size: 32,
            isDecorative: true,
          ),
          onTapViewDetails: () async {
            await context.push('/despesas');
            await monthController.load();
          },
        );
      case DashboardItemKind.dueBills:
        return DueBillsWidget(
          controller: dueBillsController,
          title: l10n.dashboardDueBillsTitle,
          onTapBill: (_) async {
            await context.push('/contas');
            await dueBillsController.load();
          },
          onTapViewAll: () async {
            await context.push('/contas');
            await dueBillsController.load();
          },
        );
      case DashboardItemKind.todayTasks:
        return TodayTasksWidget(
          controller: todayTasksController,
          title: l10n.dashboardTodayTasksTitle,
          onTapTask: (_) async {
            await context.push('/tarefas');
            await todayTasksController.load();
          },
          onTapViewAll: () async {
            await context.push('/tarefas');
            await todayTasksController.load();
          },
        );
      case DashboardItemKind.shoppingList:
        return ShoppingListWidget(
          controller: shoppingListController,
          onTapList: (list) async {
            await context.push('/listas/${list.id}');
            await shoppingListController.load();
          },
          onTapViewAll: () async {
            await context.push('/listas');
            await shoppingListController.load();
          },
        );
      case DashboardItemKind.stockAlert:
        return StockDashboardCard(
          onTap: () async {
            await context.push('/estoque');
          },
        );
      case DashboardItemKind.firstHomeChecklist:
        return ChecklistDashboardCard(
          onTap: () async {
            await context.push('/checklist');
          },
        );
      case DashboardItemKind.economyGoal:
        return EconomyDashboardCard(
          onTap: () async {
            await context.push('/economia');
          },
        );
      case DashboardItemKind.favoriteRecipes:
        return RecipesDashboardCard(
          onTap: () async {
            await context.push('/receitas');
          },
        );
    }
  }

  static MascotExpression _resolveBudgetMascotExpression(
    MonthBalanceWidgetState state,
  ) {
    if (state is MonthBalanceWidgetSuccess) {
      final summary = state.summary;
      if (summary.budget != null &&
          summary.remaining != null &&
          summary.remaining!.cents < 0) {
        return MascotExpression.worried;
      }
      if (summary.budget != null &&
          summary.budget!.cents > 0 &&
          (summary.actual.cents / summary.budget!.cents) >= 0.9) {
        return MascotExpression.thinking;
      }
      if (summary.budget != null) {
        return MascotExpression.happy;
      }
    }
    return MascotExpression.budget;
  }
}

/// Momo welcome card with speech bubble and welcoming messages (CA-110.6, RN-283, RN-284, CA-289.1).
class DashboardMascotGreeting extends StatelessWidget {
  const DashboardMascotGreeting({
    super.key,
    required this.config,
    required this.monthState,
    required this.tasksState,
  });

  final MascotConfig config;
  final MonthBalanceWidgetState monthState;
  final TodayTasksWidgetState tasksState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    MascotExpression expression = MascotExpression.waving;
    final String greetingTitle = config.displayName == 'Momo'
        ? l10n.momoGreeting
        : 'Oi! Eu sou a ${config.displayName} 💕';
    String greetingSubtitle =
        'Estou aqui para cuidar do seu cantinho com você!';

    if (tasksState is TodayTasksWidgetSuccess) {
      final t = tasksState as TodayTasksWidgetSuccess;
      if (t.tasks.isNotEmpty && t.pendingCount == 0) {
        expression = MascotExpression.relaxed;
        greetingSubtitle = l10n.momoDayOff;
      }
    }

    if (monthState is MonthBalanceWidgetSuccess) {
      final m = monthState as MonthBalanceWidgetSuccess;
      final summary = m.summary;
      if (summary.budget != null &&
          summary.remaining != null &&
          summary.remaining!.cents < 0) {
        expression = MascotExpression.worried;
        greetingSubtitle =
            'Atenção com as continhas este mês! Mas estamos juntas nisso 💕';
      } else if (summary.budget != null &&
          summary.budget!.cents > 0 &&
          (summary.actual.cents / summary.budget!.cents) >= 0.9) {
        expression = MascotExpression.thinking;
        greetingSubtitle = 'Quase no limite do orçamento! Vamos cuidar com carinho dos gastos 💕';
      }
    }

    final semanticText =
        'Mascote ${config.displayName}: $greetingTitle. $greetingSubtitle';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticText,
      child: AppCard(
        key: const Key('dashboard_mascot_greeting_card'),
        child: Row(
          children: [
            MascotWidget(
              config: config,
              expression: expression,
              size: 64,
              isDecorative: true,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(Radius.card),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greetingTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greetingSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
