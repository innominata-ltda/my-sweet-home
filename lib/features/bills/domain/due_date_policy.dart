import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

/// PURE. The short month rule, where this kind of app often fails.
abstract interface class DueDatePolicy {
  DateTime dueDateFor({required int dueDay, required YearMonth month});
}

class StandardDueDatePolicy implements DueDatePolicy {
  const StandardDueDatePolicy();

  @override
  DateTime dueDateFor({required int dueDay, required YearMonth month}) {
    final bounds = month.bounds;
    final year = bounds.start.year;
    final monthInt = bounds.start.month;

    // Calculates last day of month in UTC to remain consistent with domain.
    final lastDayOfMonth = DateTime.utc(year, monthInt + 1, 0).day;

    return DateTime.utc(
      year,
      monthInt,
      dueDay > lastDayOfMonth ? lastDayOfMonth : dueDay,
    );
  }
}
