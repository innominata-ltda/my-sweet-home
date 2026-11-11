import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';

/// Accounting month. Value object representing a year-month period without
/// loose integers to prevent transition month errors.
extension type const YearMonth(String iso) {
  // "2026-09"
  factory YearMonth.of(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    return YearMonth('$y-$m');
  }

  YearMonth get previous {
    final parts = iso.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]);
    if (m == 1) {
      y--;
      m = 12;
    } else {
      m--;
    }
    return YearMonth(
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}',
    );
  }

  YearMonth get next {
    final parts = iso.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]);
    if (m == 12) {
      y++;
      m = 1;
    } else {
      m++;
    }
    return YearMonth(
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}',
    );
  }

  DateRange get bounds {
    final parts = iso.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final start = DateTime(y, m);
    final end = DateTime(y, m + 1, 0); // last day of month
    return DateRange(start, end);
  }
}
