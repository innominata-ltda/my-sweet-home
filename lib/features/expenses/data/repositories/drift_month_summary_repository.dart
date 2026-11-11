import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';

class DriftMonthSummaryRepository implements MonthSummaryRepository {
  final AppDatabase db;

  DriftMonthSummaryRepository(this.db);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async {
    try {
      final actualQuery = db.customSelect(
        '''
        SELECT category_id, SUM(amount_cents) as total
        FROM expenses
        WHERE occurred_on LIKE ? AND deleted_at IS NULL
        GROUP BY category_id
        ''',
        variables: [Variable.withString('${m.iso}-%')],
      );
      final actualRows = await actualQuery.get();

      final actualMap = <String?, int>{};
      int totalActualCents = 0;
      for (final row in actualRows) {
        final catId = row.read<String?>('category_id');
        final total = row.read<int>('total');
        actualMap[catId] = total;
        totalActualCents += total;
      }

      final budgetQuery = db.select(db.budgets)
        ..where((t) => t.yearMonth.equals(m.iso));
      final budgetRows = await budgetQuery.get();

      final budgetMap = <String?, int>{};
      int? totalBudgetCents;
      for (final row in budgetRows) {
        final catId = row.categoryId;
        if (catId == null) {
          totalBudgetCents = row.limitCents;
        } else {
          budgetMap[catId] = row.limitCents;
        }
      }

      if (totalBudgetCents == null) {
        final baseQuery = db.select(db.budgets)
          ..where(
            (t) =>
                t.categoryId.isNull() & t.baseIncomeCents.isBiggerThanValue(0),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.yearMonth)])
          ..limit(1);
        final baseRow = await baseQuery.getSingleOrNull();
        if (baseRow != null && baseRow.baseIncomeCents > 0) {
          totalBudgetCents = baseRow.baseIncomeCents;
        }
      }

      final historyQuery = db.customSelect(
        '''
        SELECT COUNT(DISTINCT substr(occurred_on, 1, 7)) as count
        FROM expenses
        WHERE occurred_on < ? AND deleted_at IS NULL
        ''',
        variables: [Variable.withString('${m.iso}-01')],
      );
      final historyRow = await historyQuery.getSingle();
      final monthsOfHistory = historyRow.read<int>('count');

      final categoryIds = <String>{};
      for (final k in actualMap.keys) {
        if (k != null) categoryIds.add(k);
      }
      for (final k in budgetMap.keys) {
        if (k != null) categoryIds.add(k);
      }

      final slices = categoryIds.map((id) {
        final a = actualMap[id] ?? 0;
        final b = budgetMap[id];
        return CategorySlice(
          categoryId: CategoryId(id),
          actual: Money(a),
          budget: b != null ? Money(b) : null,
          remaining: b != null ? Money(b - a) : null,
        );
      }).toList();

      return Ok(
        MonthSummary(
          month: m,
          actual: Money(totalActualCents),
          budget: totalBudgetCents != null ? Money(totalBudgetCents) : null,
          remaining: totalBudgetCents != null
              ? Money(totalBudgetCents - totalActualCents)
              : null,
          byCategory: slices,
          monthsOfHistory: monthsOfHistory,
        ),
      );
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }
}
