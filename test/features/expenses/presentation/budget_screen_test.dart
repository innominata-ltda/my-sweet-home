import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:drift/native.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide Budget, Category;
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/budget_screen.dart';

class _FakeBudgetRepo implements BudgetRepository {
  List<Budget> budgets = [];

  @override
  Future<Result<List<Budget>, Failure>> ofMonth(YearMonth ym) async {
    return Ok(budgets.where((b) => b.month == ym).toList());
  }

  @override
  Future<Result<Budget, Failure>> setLimit(
    YearMonth m,
    CategoryId? category,
    Money limit,
  ) async {
    final b = Budget(
      id: 'b_${m.iso}',
      month: m,
      category: category,
      limit: limit,
    );
    budgets.removeWhere((item) => item.month == m && item.category == category);
    budgets.add(b);
    return Ok(b);
  }
}

class _FakeCatRepo implements CategoryRepository {
  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async {
    return const Ok([
      Category(
        id: CategoryId('cat-mercado'),
        name: 'Mercado',
        kind: CategoryKind.expense,
        iconKey: 'cart',
        colorHex: '#00FF00',
        isSystem: true,
      ),
    ]);
  }

  @override
  Future<Result<Category, Failure>> upsert(Category c) async => Ok(c);

  @override
  Future<Result<void, Failure>> deactivate(CategoryId id) async =>
      const Ok(null);

  @override
  Future<Result<int, Failure>> ensureDefaults() async => const Ok(0);
}

void main() {
  testWidgets(
    'Renders BudgetScreen with categories and displays monthly budget',
    (tester) async {
      final fakeBudgetRepo = _FakeBudgetRepo();
      final nowMonth = YearMonth.of(DateTime.now());
      fakeBudgetRepo.budgets.add(
        Budget(id: 'b1', month: nowMonth, limit: const Money(200000)),
      );
      final fakeCatRepo = _FakeCatRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetRepositoryProvider.overrideWithValue(fakeBudgetRepo),
            categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BudgetScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BudgetScreen), findsOneWidget);
      expect(find.text('Orçamento'), findsWidgets);
      expect(find.text('Mercado'), findsOneWidget);
    },
  );

  testWidgets(
    'Permite registrar receita base recorrente e receitas avulsas e exibe a soma total do orçamento',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final driftRepo = DriftBudgetRepository(db);
      final fakeCatRepo = _FakeCatRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetRepositoryProvider.overrideWithValue(driftRepo),
            categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BudgetScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Finds edit monthly limit button in total budget card
      final editBtn = find.byTooltip('Editar receita e orçamento');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Dialog must be open with base income and one-off income fields
      expect(find.text('Receita base recorrente *'), findsOneWidget);
      expect(find.text('Receitas adicionais avulsas no mês'), findsOneWidget);
      expect(find.text('Soma total do orçamento:'), findsOneWidget);

      // Preenche receita base: 3000,00
      final baseField = find.byKey(const Key('baseIncomeField'));
      expect(baseField, findsOneWidget);
      await tester.enterText(baseField, '3000,00');
      await tester.pumpAndSettle();

      // Preenche receita avulsa: 500,00
      final extraField = find.byKey(const Key('extraIncomeField'));
      expect(extraField, findsOneWidget);
      await tester.enterText(extraField, '500,00');
      await tester.pumpAndSettle();

      // Verifies calculated total sum displayed in dialog is R$ 3,500.00
      expect(find.text('R\$ 3.500,00'), findsOneWidget);

      // Salva
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Verifies screen displays new total budget and breakdown
      expect(find.text('R\$ 3.500,00'), findsOneWidget);
      expect(find.text('Base: R\$ 3.000,00'), findsOneWidget);
      expect(find.text('Extras: R\$ 500,00'), findsOneWidget);
    },
  );
}
