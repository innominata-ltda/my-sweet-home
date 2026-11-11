import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_budget_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_budget_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';

void main() {
  group('BudgetRepository', () {
    late AppDatabase db;
    late List<BudgetRepository> repos;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Seed category
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

      repos = [DriftBudgetRepository(db), FakeBudgetRepository()];
    });

    tearDown(() async {
      await db.close();
    });

    test('setLimit cria novo orcamento', () async {
      for (final repo in repos) {
        final month = YearMonth('2026-09');
        final category = CategoryId('cat-1');
        final limit = Money(10000);

        final result = await repo.setLimit(month, category, limit);
        expect(
          result.isOk,
          isTrue,
          reason: '${repo.runtimeType} falhou: ${result.failureOrNull}',
        );

        final budget = result.valueOrNull!;
        expect(budget.month.iso, '2026-09');
        expect(budget.category?.value, 'cat-1');
        expect(budget.limit.cents, 10000);

        final monthBudgetsResult = await repo.ofMonth(month);
        final monthBudgets = monthBudgetsResult.valueOrNull!;
        expect(monthBudgets.length, 1);
        expect(monthBudgets.first.id, budget.id);
      }
    });

    test('setLimit atualiza orcamento existente', () async {
      for (final repo in repos) {
        final month = YearMonth('2026-09');
        final category = CategoryId('cat-1');

        final r1 = await repo.setLimit(month, category, Money(10000));
        expect(
          r1.isOk,
          isTrue,
          reason: '${repo.runtimeType} falhou r1: ${r1.failureOrNull}',
        );
        final id1 = r1.valueOrNull!.id;

        final r2 = await repo.setLimit(month, category, Money(20000));
        expect(
          r2.isOk,
          isTrue,
          reason: '${repo.runtimeType} falhou r2: ${r2.failureOrNull}',
        );
        final id2 = r2.valueOrNull!.id;

        expect(
          id1,
          id2,
          reason: '${repo.runtimeType} deve atualizar o mesmo ID',
        );
        expect(r2.valueOrNull!.limit.cents, 20000);

        final allResult = await repo.ofMonth(month);
        final all = allResult.valueOrNull!;
        expect(all.length, 1);
        expect(all.first.limit.cents, 20000);
      }
    });

    test('setLimit com category null (orcamento total)', () async {
      for (final repo in repos) {
        final month = YearMonth('2026-09');

        final r1 = await repo.setLimit(month, null, Money(50000));
        expect(
          r1.isOk,
          isTrue,
          reason: '${repo.runtimeType} falhou: ${r1.failureOrNull}',
        );
        expect(r1.valueOrNull!.category, null);

        final allResult = await repo.ofMonth(month);
        expect(allResult.valueOrNull!.first.limit.cents, 50000);
      }
    });

    test('ofMonth returns empty list when there are no budgets', () async {
      for (final repo in repos) {
        final result = await repo.ofMonth(YearMonth('2026-09'));
        expect(result.isOk, isTrue);
        expect(result.valueOrNull!, isEmpty);
      }
    });
  });
}
