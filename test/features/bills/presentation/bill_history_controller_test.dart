import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/presentation/bill_history_controller.dart';

import '../../../fakes/fake_bill_repository.dart';
import '../../../fakes/fake_bill_payment_repository.dart';

import 'package:my_sweet_home/core/id/id_generator.dart';

void main() {
  late FakeBillRepository billRepo;
  late FakeBillPaymentRepository paymentRepo;

  setUp(() {
    billRepo = FakeBillRepository(const UuidV7Generator());
    paymentRepo = FakeBillPaymentRepository();
  });

  test('loads history successfully', () async {
    final newBill = NewBill(
      id: 'b1',
      title: 'Aluguel',
      categoryId: CategoryId('1'),
      dueDay: 5,
      recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
      isEstimated: false,
    );
    await billRepo.upsert(newBill);

    final payment1 = BillPayment(
      id: 'p1',
      billId: 'b1',
      dueOn: DateTime(2026, 3, 5),
      paidOn: DateTime(2026, 3, 6),
      paidAmount: const Money(120000),
    );
    final payment2 = BillPayment(
      id: 'p2',
      billId: 'b1',
      dueOn: DateTime(2026, 4, 5),
    );
    await paymentRepo.upsertOccurrences([payment1, payment2]);

    final controller = BillHistoryController(
      billId: 'b1',
      billRepository: billRepo,
      paymentRepository: paymentRepo,
    );

    await Future<void>.delayed(Duration.zero); // Wait for load()

    final state = controller.value;
    expect(state, isA<BillHistorySuccess>());
    if (state is BillHistorySuccess) {
      expect(state.bill.id, 'b1');
      expect(state.payments.length, 2);
      expect(state.payments.first.id, 'p2'); // Descending order
    }
  });

  test('returns error if bill not found', () async {
    final controller = BillHistoryController(
      billId: 'b1',
      billRepository: billRepo,
      paymentRepository: paymentRepo,
    );

    await Future<void>.delayed(Duration.zero); // Wait for load()

    final state = controller.value;
    expect(state, isA<BillHistoryError>());
  });
}
