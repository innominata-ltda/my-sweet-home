import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';

class FakeBillRepository implements BillRepository {
  final IdGenerator _idGenerator;
  final Map<BillId, Bill> _bills = {};

  FakeBillRepository(this._idGenerator);

  @override
  Future<Result<Bill, Failure>> upsert(NewBill b) async {
    final id = b.id ?? _idGenerator.newId();
    final bill = Bill(
      id: id,
      title: b.title,
      categoryId: b.categoryId,
      dueDay: b.dueDay,
      recurrence: b.recurrence,
      amount: b.amount,
      isEstimated: b.isEstimated,
      noticeDays: b.noticeDays,
    );
    _bills[id] = bill;
    return Ok(bill);
  }

  @override
  Future<Result<void, Failure>> pause(BillId id) async {
    final bill = _bills[id];
    if (bill != null) {
      _bills[id] = bill.copyWith(isPaused: true);
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> delete(BillId id) async {
    _bills.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<List<Bill>, Failure>> active() async {
    return Ok(_bills.values.where((b) => !b.isPaused).toList());
  }

  @override
  Future<Result<Bill?, Failure>> byId(BillId id) async {
    return Ok(_bills[id]);
  }
}
