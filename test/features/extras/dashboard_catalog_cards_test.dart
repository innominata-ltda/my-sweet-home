import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/data/repositories/fake_checklist_repository.dart';
import 'package:my_sweet_home/features/extras/data/repositories/fake_savings_goal_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/checklist_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/recipes_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_dashboard_card.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_providers.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_recipe_repository.dart';
import '../../fakes/fake_stock_repository.dart';

class FakeMonthSummaryRepository implements MonthSummaryRepository {
  FakeMonthSummaryRepository([MonthSummary? summary])
    : summary =
          summary ??
          const MonthSummary(
            month: YearMonth('2026-10'),
            actual: Money(100000),
            budget: Money(150000),
            remaining: Money(50000),
            byCategory: [],
            monthsOfHistory: 1,
          );

  final MonthSummary summary;

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth month) async {
    return Ok(summary);
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 24, 12, 0);
  final clock = FakeClock(now);

  group('StockDashboardCard (RF-102, RF-105, RN-370, CA-3.5)', () {
    testWidgets(
      'exibe contagem de itens em estoque e dispara onTap para /estoque',
      (tester) async {
        final fakeStockRepo = FakeStockRepository();
        await fakeStockRepo.upsertStockItem(
          productId: 'prod-arroz',
          quantity: const Quantity(2000, Unit.kg),
        );
        await fakeStockRepo.upsertStockItem(
          productId: 'prod-feijao',
          quantity: const Quantity(1000, Unit.kg),
        );

        final stockController = StockController(fakeStockRepo);
        await stockController.loadStockItems();

        bool tapped = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: StockDashboardCard(
                  controller: stockController,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('stock_dashboard_card')), findsOneWidget);
        expect(find.text('Estoque Doméstico'), findsOneWidget);
        expect(find.text('2 produto(s) no estoque doméstico'), findsOneWidget);

        final cardSize = tester.getSize(
          find.byKey(const Key('stock_dashboard_card')),
        );
        expect(cardSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

        await tester.tap(find.byKey(const Key('stock_dashboard_card')));
        expect(tapped, isTrue);

        stockController.dispose();
      },
    );

    testWidgets('displays empty state when no products in stock', (
      tester,
    ) async {
      final fakeStockRepo = FakeStockRepository();
      final stockController = StockController(fakeStockRepo);
      await stockController.loadStockItems();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StockDashboardCard(controller: stockController),
            ),
          ),
        ),
      );

      expect(
        find.text('Nenhum produto monitorado no estoque.'),
        findsOneWidget,
      );
      stockController.dispose();
    });
  });

  group('ChecklistDashboardCard (RF-100, RF-102, RF-105, RN-370, CA-3.5)', () {
    testWidgets(
      'exibe progresso real e barra de progresso, disparando onTap para /checklist',
      (tester) async {
        final fakeChecklistRepo = FakeChecklistRepository();
        // Inicializar e marcar 5 itens (CA-1.1: 5 de 20 = 25%)
        final items = (await fakeChecklistRepo.getItems()).valueOrNull!;
        for (int i = 0; i < 5; i++) {
          await fakeChecklistRepo.toggleItemMarked(items[i].id);
        }

        final checklistController = ChecklistController(fakeChecklistRepo);
        await checklistController.load();

        bool tapped = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ChecklistDashboardCard(
                  controller: checklistController,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const Key('checklist_dashboard_card')),
          findsOneWidget,
        );
        expect(find.text('Checklist da Primeira Casa'), findsOneWidget);
        final expectedPercent = (checklistController.value.progress * 100)
            .toStringAsFixed(0);
        expect(find.text('$expectedPercent%'), findsOneWidget);
        expect(
          find.text(
            '${checklistController.value.markedCount} de ${checklistController.value.totalCount} itens prontos',
          ),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        final cardSize = tester.getSize(
          find.byKey(const Key('checklist_dashboard_card')),
        );
        expect(cardSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

        await tester.tap(find.byKey(const Key('checklist_dashboard_card')));
        expect(tapped, isTrue);

        checklistController.dispose();
      },
    );
  });

  group('EconomyDashboardCard (RF-103, RF-102, RF-105, RN-370, RN-254, CA-3.5)', () {
    testWidgets(
      'exibe meta definida e mensagem neutra, disparando onTap para /economia',
      (tester) async {
        final fakeGoalRepo = FakeSavingsGoalRepository();
        await fakeGoalRepo.setGoal(
          const YearMonth('2026-10'),
          const Money(50000), // R$ 500,00
        );

        final fakeSummaryRepo = FakeMonthSummaryRepository();

        final economyController = EconomyController(
          savingsGoalRepo: fakeGoalRepo,
          monthSummaryRepo: fakeSummaryRepo,
          initialMonth: const YearMonth('2026-10'),
        );
        await economyController.load(const YearMonth('2026-10'));

        bool tapped = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EconomyDashboardCard(
                  controller: economyController,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('economy_dashboard_card')), findsOneWidget);
        expect(find.text('Modo Economia'), findsOneWidget);
        expect(find.text('Meta: R\$ 500,00'), findsOneWidget);

        final cardSize = tester.getSize(
          find.byKey(const Key('economy_dashboard_card')),
        );
        expect(cardSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

        await tester.tap(find.byKey(const Key('economy_dashboard_card')));
        expect(tapped, isTrue);

        economyController.dispose();
      },
    );

    testWidgets(
      'exibe prompt para definir meta quando não há meta cadastrada',
      (tester) async {
        final fakeGoalRepo = FakeSavingsGoalRepository();
        final fakeSummaryRepo = FakeMonthSummaryRepository();
        final economyController = EconomyController(
          savingsGoalRepo: fakeGoalRepo,
          monthSummaryRepo: fakeSummaryRepo,
          initialMonth: const YearMonth('2026-10'),
        );
        await economyController.load(const YearMonth('2026-10'));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EconomyDashboardCard(controller: economyController),
              ),
            ),
          ),
        );

        expect(find.text('Definir meta de economia'), findsOneWidget);
        economyController.dispose();
      },
    );
  });

  group('RecipesDashboardCard (RF-102, RF-105, RN-370, CA-3.5)', () {
    testWidgets(
      'exibe total de receitas favoritas e dispara onTap para /receitas',
      (tester) async {
        final fakeRecipeRepo = FakeRecipeRepository(clock);
        await fakeRecipeRepo.upsert(
          const NewRecipe(
            title: 'Macarrão com Alho e Óleo',
            ingredients: [Ingredient(name: 'Macarrão')],
            prepText: 'Cozinhe o macarrão e refogue com alho.',
            timeMinutes: 15,
            servings: 2,
            isFavorite: true,
          ),
        );
        await fakeRecipeRepo.upsert(
          const NewRecipe(
            title: 'Omelete Rápido',
            ingredients: [Ingredient(name: 'Ovos')],
            prepText: 'Bata e doure na frigideira.',
            timeMinutes: 5,
            servings: 1,
            isFavorite: true,
          ),
        );

        bool tapped = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: RecipesDashboardCard(
                  repository: fakeRecipeRepo,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('recipes_dashboard_card')), findsOneWidget);
        expect(find.text('Receitas Favoritas'), findsOneWidget);
        expect(
          find.text('2 receita(s) favorita(s) para o seu dia a dia'),
          findsOneWidget,
        );

        final cardSize = tester.getSize(
          find.byKey(const Key('recipes_dashboard_card')),
        );
        expect(cardSize.height, greaterThanOrEqualTo(Spacing.touchTarget));

        await tester.tap(find.byKey(const Key('recipes_dashboard_card')));
        expect(tapped, isTrue);
      },
    );

    testWidgets('displays message when no favorite recipes', (tester) async {
      final fakeRecipeRepo = FakeRecipeRepository(clock);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecipesDashboardCard(repository: fakeRecipeRepo),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nenhuma receita favoritada ainda.'), findsOneWidget);
    });
  });

  group('CA-3.5: Navigation integration for all new catalog cards', () {
    testWidgets(
      'todos os 4 novos cards navegam para as rotas corretas ao serem tocados',
      (tester) async {
        final routesTapped = <String>[];

        final fakeStockRepo = FakeStockRepository();
        final stockController = StockController(fakeStockRepo);
        await stockController.loadStockItems();

        final fakeChecklistRepo = FakeChecklistRepository();
        await fakeChecklistRepo.addItem(
          roomCategory: 'Sala',
          title: 'Lâmpadas',
        );
        final checklistController = ChecklistController(fakeChecklistRepo);
        await checklistController.load();

        final fakeGoalRepo = FakeSavingsGoalRepository();
        final fakeSummaryRepo = FakeMonthSummaryRepository();
        final economyController = EconomyController(
          savingsGoalRepo: fakeGoalRepo,
          monthSummaryRepo: fakeSummaryRepo,
          initialMonth: const YearMonth('2026-10'),
        );
        await economyController.load(const YearMonth('2026-10'));

        final fakeRecipeRepo = FakeRecipeRepository(clock);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    StockDashboardCard(
                      controller: stockController,
                      onTap: () => routesTapped.add('/estoque'),
                    ),
                    ChecklistDashboardCard(
                      controller: checklistController,
                      onTap: () => routesTapped.add('/checklist'),
                    ),
                    EconomyDashboardCard(
                      controller: economyController,
                      onTap: () => routesTapped.add('/economia'),
                    ),
                    RecipesDashboardCard(
                      repository: fakeRecipeRepo,
                      onTap: () => routesTapped.add('/receitas'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('stock_dashboard_card')));
        await tester.tap(find.byKey(const Key('checklist_dashboard_card')));
        await tester.tap(find.byKey(const Key('economy_dashboard_card')));
        await tester.tap(find.byKey(const Key('recipes_dashboard_card')));

        expect(routesTapped, [
          '/estoque',
          '/checklist',
          '/economia',
          '/receitas',
        ]);

        stockController.dispose();
        checklistController.dispose();
        economyController.dispose();
      },
    );
  });
}
