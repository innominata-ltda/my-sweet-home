import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

abstract interface class BillPaymentRepository {
  Future<Result<List<BillPayment>, Failure>> ofMonth(YearMonth m);
  Future<Result<BillPayment, Failure>> markPaid(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  });
  Future<Result<BillPayment, Failure>> unmarkPaid(BillPaymentId id);
  Future<Result<List<BillPayment>, Failure>> historyOf(BillId id);

  /// Inserts occurrences, ignoring existing ones per uniqueness rule
  /// (account, due date) (RN-132).
  /// Returns number of occurrences actually inserted.
  Future<Result<int, Failure>> upsertOccurrences(List<BillPayment> payments);
  Future<Result<BillPayment?, Failure>> byId(BillPaymentId id);
}
