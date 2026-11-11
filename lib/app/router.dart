import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/main_shell_page.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';
import 'package:my_sweet_home/features/settings/presentation/settings_page.dart';
import 'package:my_sweet_home/features/settings/presentation/about_page.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';
import 'package:my_sweet_home/features/products/presentation/products_page.dart';
import 'package:my_sweet_home/features/products/presentation/product_detail_page.dart';
import 'package:my_sweet_home/features/expenses/presentation/expenses_screen.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_capture_screen.dart';
import 'package:my_sweet_home/features/backup/presentation/backup_menu_page.dart';
import 'package:my_sweet_home/features/backup/presentation/import_backup_screen.dart';
import 'package:my_sweet_home/features/backup/presentation/wipe_all_data_screen.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_screen.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_screen.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_screen.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_screen.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_providers.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_preparation_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_screen.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/features/prices/presentation/purchase_registration_page.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchase_registration_state.dart';
import 'package:my_sweet_home/features/prices/presentation/price_history_page.dart';

import 'package:my_sweet_home/features/bills/presentation/bills_page_container.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/presentation/quick_add_expense_container.dart';

import 'package:my_sweet_home/features/backup/presentation/export_backup_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_containers.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_container.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_benchmark_page.dart';
import 'package:my_sweet_home/features/expenses/presentation/budget_screen.dart';
import 'package:my_sweet_home/features/prices/presentation/purchases_history_screen.dart';
import 'package:my_sweet_home/features/mascot/presentation/pages/mascot_customization_page.dart';
import 'package:my_sweet_home/features/mascot/presentation/pages/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/presentation/quick_add_task_sheet.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';
import 'package:my_sweet_home/features/sync/presentation/household_screen.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShellPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),

          // 003 & 004 — Purchases / Lists
          GoRoute(
            path: '/compras',
            builder: (context, state) => const PurchasesHistoryScreen(),
            routes: [
              GoRoute(
                path: 'nova',
                builder: (context, state) {
                  final initialItems = (state.extra as List<ShoppingItem>?)
                      ?.map(
                        (item) => InitialPurchaseItemDraft(
                          productId: item.productId,
                          name: item.parsedName,
                          quantity: item.parsedQuantity,
                        ),
                      )
                      .toList();
                  return PurchaseRegistrationPage(initialItems: initialItems);
                },
              ),
              GoRoute(
                path: 'historico-precos',
                builder: (context, state) {
                  final productId =
                      state.uri.queryParameters['productId'] ??
                      (state.extra as String?);
                  return PriceHistoryPage(productId: productId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/precos',
            redirect: (context, state) => state.uri.queryParameters.isNotEmpty
                ? '/compras/historico-precos?${state.uri.query}'
                : '/compras/historico-precos',
          ),
          GoRoute(
            path: '/listas',
            builder: (context, state) => ShoppingListScreen(
              listId: 'default',
              onRegisterItems: (items) =>
                  context.push('/compras/nova', extra: items),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ShoppingListScreen(
                    listId: id,
                    onRegisterItems: (items) =>
                        context.push('/compras/nova', extra: items),
                  );
                },
              ),
            ],
          ),

          // 005 — Expenses
          GoRoute(
            path: '/despesas',
            builder: (context, state) => const ExpensesScreen(),
            routes: [
              GoRoute(
                path: 'nova',
                builder: (context, state) => QuickAddExpenseContainer(
                  initialExpense: state.extra as Expense?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/orcamento',
            builder: (context, state) => const BudgetScreen(),
          ),
          // 006 — Bills
          GoRoute(
            path: '/contas',
            builder: (context, state) => const BillsPageContainer(),
          ),

          // 007 — Tasks / Calendar & 014 — Presets
          GoRoute(
            path: '/tarefas',
            builder: (context, state) => const CalendarPage(),
            routes: [
              GoRoute(
                path: 'sugestoes',
                builder: (context, state) => TaskPresetCatalogPage(
                  onOpenDraft: (draft) async {
                    final container = ProviderScope.containerOf(context);
                    final repository = container.read(taskRepositoryProvider);
                    final clock = container.read(clockProvider);
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => QuickAddTaskSheet(
                        repository: repository,
                        clock: clock,
                        initialDate: draft.firstOccurrence,
                        initialDraft: draft,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => OnboardingPage(
            onCompleteWithChecklist: (activate) async {
              if (activate) {
                try {
                  await ref
                      .read(dashboardLayoutControllerProvider)
                      .show(DashboardItemKind.firstHomeChecklist);
                } catch (_) {}
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'casa',
            builder: (context, state) => const HouseholdScreen(),
          ),
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupMenuPage(),
            routes: [
              GoRoute(
                path: 'exportar',
                builder: (context, state) => const ExportBackupScreen(),
              ),
              GoRoute(
                path: 'importar',
                builder: (context, state) => const ImportBackupScreen(),
              ),
              GoRoute(
                path: 'apagar-tudo',
                builder: (context, state) => const WipeAllDataScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ajustes/casa',
        builder: (context, state) => const HouseholdScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),

      // 002 — Products
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProductsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailPage(productId: id);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/calendario',
        builder: (context, state) => const CalendarPage(),
      ),

      // 008 — Recipes
      GoRoute(
        path: '/receitas',
        builder: (context, state) => const RecipeListContainer(),
        routes: [
          GoRoute(
            path: 'nova',
            builder: (context, state) =>
                const RecipeDraftScreen(idGenerator: UuidV7Generator()),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeDetailContainer(recipeId: id);
            },
            routes: [
              GoRoute(
                path: 'preparo',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return RecipePreparationScreen(recipeId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // 009 — OCR
      GoRoute(
        path: '/ocr',
        builder: (context, state) => OcrCaptureScreen(
          onImageCaptured: (path) {
            context.push('/ocr/revisao', extra: path);
          },
          onManualEntry: () {
            context.go('/compras/nova');
          },
        ),
        routes: [
          GoRoute(
            path: 'revisao',
            builder: (context, state) {
              final path = state.extra as String? ?? '';
              return OcrReviewContainer(imagePath: path);
            },
          ),
          GoRoute(
            path: 'benchmark',
            builder: (context, state) => const OcrBenchmarkPage(),
          ),
        ],
      ),

      // 011 — Extras
      GoRoute(
        path: '/checklist',
        builder: (context, state) => const ChecklistScreen(),
      ),
      GoRoute(
        path: '/estoque',
        builder: (context, state) => const StockScreen(),
      ),
      GoRoute(
        path: '/busca',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/economia',
        builder: (context, state) => const EconomyScreen(),
      ),

      // 012 — Mascot and Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          final extraMap = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          final autoTransition =
              state.uri.queryParameters['autoTransition'] == 'true' ||
              state.uri.queryParameters['auto'] == 'true' ||
              state.extra == true ||
              (extraMap?['autoTransition'] == true);
          final destination =
              extraMap?['destination'] as String? ??
              state.uri.queryParameters['destination'] ??
              '/';
          return SplashScreen(
            autoTransition: autoTransition,
            destination: destination,
          );
        },
      ),
      GoRoute(
        path: '/mascot',
        redirect: (context, state) =>
            state.matchedLocation == '/mascot' ? '/mascot/customize' : null,
        builder: (context, state) => const MascotCustomizationPage(),
        routes: [
          GoRoute(
            path: 'customize',
            builder: (context, state) => const MascotCustomizationPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada'))),
  );
}
