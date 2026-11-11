import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  group('DriftMonthSummaryRepository', () {
    late AppDatabase db;
    late DriftMonthSummaryRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftMonthSummaryRepository(db);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              name: 'Alimentação',
              iconKey: 'food',
              kind: 'expense',
              isSystem: const Value(true),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('summarize handles overall and category budgets correctly', () async {
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: 'b1',
              yearMonth: '2026-09',
              limitCents: 100000,
            ),
          );

      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: 'b2',
              yearMonth: '2026-09',
              categoryId: const Value('c1'),
              limitCents: 50000,
            ),
          );

      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'e1',
              amountCents: 50000,
              occurredOn: '2026-09-05',
              categoryId: const Value('c1'),
            ),
          );

      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'e2',
              amountCents: 26000,
              occurredOn: '2026-09-10',
            ),
          );

      final result = await repo.summarize(const YearMonth('2026-09'));
      expect(result.isOk, isTrue);

      final summary = result.valueOrNull!;
      expect(summary.budget, const Money(100000));
      expect(summary.actual, const Money(76000));
      expect(summary.remaining, const Money(24000));

      final c1Slice = summary.byCategory.firstWhere(
        (s) => s.categoryId.value == 'c1',
      );
      expect(c1Slice.actual, const Money(50000));
      expect(c1Slice.budget, const Money(50000));
      expect(c1Slice.remaining, const Money(0));
    });
  });
}
