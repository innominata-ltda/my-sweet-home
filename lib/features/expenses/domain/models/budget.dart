import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

class Budget {
  final String id;
  final YearMonth month;
  final CategoryId? category;
  final Money limit;

  const Budget({
    required this.id,
    required this.month,
    this.category,
    required this.limit,
  });
}
