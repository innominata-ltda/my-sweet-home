import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';

abstract interface class BillRepository {
  Future<Result<Bill, Failure>> upsert(NewBill b);
  Future<Result<void, Failure>> pause(BillId id); // preserves history (RN-137)
  Future<Result<void, Failure>> delete(BillId id);
  Future<Result<List<Bill>, Failure>> active();
  Future<Result<Bill?, Failure>> byId(BillId id);
}
