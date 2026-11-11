import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

abstract interface class MonthSummaryRepository {
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m);
}
