import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/budget.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

abstract interface class BudgetRepository {
  Future<Result<List<Budget>, Failure>> ofMonth(YearMonth m);
  Future<Result<Budget, Failure>> setLimit(
    YearMonth m,
    CategoryId? category,
    Money limit,
  );
}
