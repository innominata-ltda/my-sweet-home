import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  group('DriftBudgetRepository', () {
    late AppDatabase db;
    late DriftBudgetRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftBudgetRepository(db);

      // Seed a category for testing
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-1',
              name: 'Categoria 1',
              kind: 'expense',
              iconKey: 'test',
              isSystem: const Value(false),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('setLimit creates new budget', () async {
      final month = const YearMonth('2026-09');
      final category = const CategoryId('cat-1');
      final limit = const Money(10000);

      final result = await repo.setLimit(month, category, limit);
      expect(result.isOk, isTrue);

      final budget = result.valueOrNull!;
      expect(budget.month.iso, '2026-09');
      expect(budget.category?.value, 'cat-1');
      expect(budget.limit.cents, 10000);
    });

    test('setLimit updates existing budget', () async {
      final month = const YearMonth('2026-09');
      final category = const CategoryId('cat-1');

      final r1 = await repo.setLimit(month, category, const Money(10000));
      expect(r1.isOk, isTrue);

      final r2 = await repo.setLimit(month, category, const Money(20000));
      expect(r2.isOk, isTrue);

      expect(r1.valueOrNull!.id, r2.valueOrNull!.id);
      expect(r2.valueOrNull!.limit.cents, 20000);
    });

    test('setLimit with null category creates overall budget', () async {
      final month = const YearMonth('2026-09');

      final r1 = await repo.setLimit(month, null, const Money(50000));
      expect(r1.isOk, isTrue);
      expect(r1.valueOrNull!.category, isNull);

      final allResult = await repo.ofMonth(month);
      expect(allResult.valueOrNull!.first.limit.cents, 50000);
    });

    test('saveIncome salva receita base recorrente e avulsa e atualiza limite total', () async {
      final month = const YearMonth('2026-09');
      final baseIncome = const Money(300000); // R$ 3.000,00
      final extraIncome = const Money(50000); // R$ 500,00

      final res = await repo.saveIncome(
        month: month,
        baseIncome: baseIncome,
        extraIncome: extraIncome,
      );
      expect(res.isOk, isTrue);

      final budget = res.valueOrNull!;
      expect(budget.month, month);
      expect(budget.category, isNull);
      expect(budget.limit.cents, 350000); // Soma total: 3.500,00

      final incomeRes = await repo.getIncome(month);
      expect(incomeRes.isOk, isTrue);
      final income = incomeRes.valueOrNull!;
      expect(income.baseIncome.cents, 300000);
      expect(income.extraIncome.cents, 50000);
      expect(income.totalBudget.cents, 350000);
    });

    test('saveIncome updates income values for existing month', () async {
      final month = const YearMonth('2026-09');

      await repo.saveIncome(
        month: month,
        baseIncome: const Money(250000),
        extraIncome: const Money(20000),
      );

      final res = await repo.saveIncome(
        month: month,
        baseIncome: const Money(300000),
        extraIncome: const Money(80000),
      );
      expect(res.isOk, isTrue);

      final incomeRes = await repo.getIncome(month);
      final income = incomeRes.valueOrNull!;
      expect(income.baseIncome.cents, 300000);
      expect(income.extraIncome.cents, 80000);
      expect(income.totalBudget.cents, 380000);
    });

    test('getIncome inherits base recurring income from prior months if month lacks own income', () async {
      final m1 = const YearMonth('2026-08');
      final m2 = const YearMonth('2026-09');

      // Configure month 08 with base 4000 and extra 600
      await repo.saveIncome(
        month: m1,
        baseIncome: const Money(400000),
        extraIncome: const Money(60000),
      );

      // Query month 09 which has no registered budget yet
      final m2IncomeRes = await repo.getIncome(m2);
      expect(m2IncomeRes.isOk, isTrue);
      final m2Income = m2IncomeRes.valueOrNull!;
      // Inherit base recurring from previous month without one-off extras
      expect(m2Income.baseIncome.cents, 400000);
      expect(m2Income.extraIncome.cents, 0);
      expect(m2Income.totalBudget.cents, 400000);
    });

    test('getBaseRecurringIncome returns zero when no recurring income was configured', () async {
      final res = await repo.getBaseRecurringIncome();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull!.cents, 0);
    });
  });
}
