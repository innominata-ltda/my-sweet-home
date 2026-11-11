import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/savings_goal_repository.dart';

class DriftSavingsGoalRepository implements SavingsGoalRepository {
  final AppDatabase db;
  final Clock _clock;

  DriftSavingsGoalRepository(this.db, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  String _keyForMonth(YearMonth month) => 'savings_goal_${month.iso}';

  @override
  Future<Result<SavingsGoal?, Failure>> getGoal(YearMonth month) async {
    try {
      final key = _keyForMonth(month);
      final query = db.select(db.settings)..where((t) => t.key.equals(key));
      final row = await query.getSingleOrNull();

      if (row == null) {
        return const Ok(null);
      }

      final cents = int.tryParse(row.value) ?? 0;
      return Ok(SavingsGoal(month: month, target: Money(cents)));
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }

  @override
  Future<Result<SavingsGoal, Failure>> setGoal(
    YearMonth month,
    Money target,
  ) async {
    try {
      final key = _keyForMonth(month);
      final nowStr = _clock.nowUtc().toIso8601String();

      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(
              key: key,
              value: target.cents.toString(),
              updatedAt: Value(nowStr),
            ),
          );

      return Ok(SavingsGoal(month: month, target: target));
    } catch (e) {
      return Err(StorageFailure(detail: 'DbError: $e'));
    }
  }
}
