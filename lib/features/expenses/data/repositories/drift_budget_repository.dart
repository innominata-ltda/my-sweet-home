import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart'
    as domain;
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/budget_repository.dart';

class MonthBudgetIncome {
  final Money baseIncome;
  final Money extraIncome;

  const MonthBudgetIncome({
    this.baseIncome = const Money(0),
    this.extraIncome = const Money(0),
  });

  Money get totalBudget => Money(baseIncome.cents + extraIncome.cents);
}

class DriftBudgetRepository implements BudgetRepository {
  final AppDatabase db;
  final Clock _clock;

  DriftBudgetRepository(this.db, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  @override
  Future<Result<List<domain.Budget>, Failure>> ofMonth(YearMonth m) async {
    try {
      final query = db.select(db.budgets)
        ..where((t) => t.yearMonth.equals(m.iso));
      final rows = await query.get();

      final budgets = rows.map((row) {
        return domain.Budget(
          id: row.id,
          month: YearMonth(row.yearMonth),
          category: row.categoryId != null ? CategoryId(row.categoryId!) : null,
          limit: Money(row.limitCents),
        );
      }).toList();

      final hasOverall = budgets.any((b) => b.category == null);
      if (!hasOverall) {
        final baseResult = await getBaseRecurringIncome();
        final baseIncome = baseResult.valueOrNull ?? const Money(0);
        if (baseIncome.cents > 0) {
          budgets.insert(
            0,
            domain.Budget(
              id: 'inherited_${m.iso}',
              month: m,
              limit: baseIncome,
            ),
          );
        }
      }

      return Ok(budgets);
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }

  /// Retorna a receita base recorrente mais recente configurada
  Future<Result<Money, Failure>> getBaseRecurringIncome() async {
    try {
      final query = db.select(db.budgets)
        ..where(
          (t) => t.categoryId.isNull() & t.baseIncomeCents.isBiggerThanValue(0),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.yearMonth)])
        ..limit(1);

      final row = await query.getSingleOrNull();
      if (row != null) {
        return Ok(Money(row.baseIncomeCents));
      }
      return const Ok(Money(0));
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }

  /// Returns income composition for month (recurring base and one-offs)
  Future<Result<MonthBudgetIncome, Failure>> getIncome(YearMonth m) async {
    try {
      final query = db.select(db.budgets)
        ..where((t) => t.yearMonth.equals(m.iso) & t.categoryId.isNull());
      final row = await query.getSingleOrNull();

      if (row != null) {
        if (row.baseIncomeCents > 0 || row.extraIncomeCents > 0) {
          return Ok(
            MonthBudgetIncome(
              baseIncome: Money(row.baseIncomeCents),
              extraIncome: Money(row.extraIncomeCents),
            ),
          );
        } else if (row.limitCents > 0) {
          return Ok(MonthBudgetIncome(baseIncome: Money(row.limitCents)));
        }
      }

      // If month has no income configured yet, inherits recurring base income
      final baseResult = await getBaseRecurringIncome();
      final recurringBase = baseResult.valueOrNull ?? const Money(0);
      return Ok(MonthBudgetIncome(baseIncome: recurringBase));
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }

  /// Saves base and one-off income for month, updating total budget limit
  Future<Result<domain.Budget, Failure>> saveIncome({
    required YearMonth month,
    required Money baseIncome,
    required Money extraIncome,
  }) async {
    try {
      return await db.transaction(() async {
        final totalLimit = Money(baseIncome.cents + extraIncome.cents);
        final existingQuery = db.select(db.budgets)
          ..where((t) => t.yearMonth.equals(month.iso) & t.categoryId.isNull());

        final existing = await existingQuery.getSingleOrNull();

        if (existing != null) {
          await (db.update(
            db.budgets,
          )..where((t) => t.id.equals(existing.id))).write(
            BudgetsCompanion(
              limitCents: Value(totalLimit.cents),
              baseIncomeCents: Value(baseIncome.cents),
              extraIncomeCents: Value(extraIncome.cents),
            ),
          );

          return Ok(
            domain.Budget(id: existing.id, month: month, limit: totalLimit),
          );
        } else {
          final id = 'bg_${_clock.nowUtc().microsecondsSinceEpoch}';
          await db
              .into(db.budgets)
              .insert(
                BudgetsCompanion.insert(
                  id: id,
                  yearMonth: month.iso,
                  categoryId: const Value(null),
                  limitCents: totalLimit.cents,
                  baseIncomeCents: Value(baseIncome.cents),
                  extraIncomeCents: Value(extraIncome.cents),
                ),
              );

          return Ok(domain.Budget(id: id, month: month, limit: totalLimit));
        }
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }

  @override
  Future<Result<domain.Budget, Failure>> setLimit(
    YearMonth m,
    CategoryId? category,
    Money limit,
  ) async {
    try {
      return await db.transaction(() async {
        final existingQuery = db.select(db.budgets)
          ..where((t) {
            final monthFilter = t.yearMonth.equals(m.iso);
            final catFilter = category == null
                ? t.categoryId.isNull()
                : t.categoryId.equals(category.value);
            return monthFilter & catFilter;
          });

        final existing = await existingQuery.getSingleOrNull();

        if (existing != null) {
          await (db.update(
            db.budgets,
          )..where((t) => t.id.equals(existing.id))).write(
            BudgetsCompanion(
              limitCents: Value(limit.cents),
              baseIncomeCents:
                  category == null &&
                      existing.baseIncomeCents == 0 &&
                      existing.extraIncomeCents == 0
                  ? Value(limit.cents)
                  : const Value.absent(),
            ),
          );

          return Ok(
            domain.Budget(
              id: existing.id,
              month: m,
              category: category,
              limit: limit,
            ),
          );
        } else {
          final id = 'bg_${_clock.nowUtc().microsecondsSinceEpoch}';
          await db
              .into(db.budgets)
              .insert(
                BudgetsCompanion.insert(
                  id: id,
                  yearMonth: m.iso,
                  categoryId: Value(category?.value),
                  limitCents: limit.cents,
                  baseIncomeCents: category == null
                      ? Value(limit.cents)
                      : const Value.absent(),
                ),
              );

          return Ok(
            domain.Budget(id: id, month: m, category: category, limit: limit),
          );
        }
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }
}
