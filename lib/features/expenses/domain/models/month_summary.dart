import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

final class CategorySlice {
  final CategoryId categoryId;
  final Money actual;
  final Money? budget;
  final Money? remaining;

  const CategorySlice({
    required this.categoryId,
    required this.actual,
    this.budget,
    this.remaining,
  });
}

final class MonthSummary {
  final YearMonth month;
  final Money actual; // actual — only what already occurred (RN-108)
  final Money? budget; // null = no budget defined
  final Money? remaining; // budget - actual, null if no budget
  final List<CategorySlice> byCategory; // realizado e limite por categoria
  final int monthsOfHistory; // forecast base (RN-109)

  const MonthSummary({
    required this.month,
    required this.actual,
    this.budget,
    this.remaining,
    required this.byCategory,
    required this.monthsOfHistory,
  });
}
