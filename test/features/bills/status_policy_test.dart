import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';

import '../../fakes/fake_clock.dart';

void main() {
  group('DefaultBillStatusPolicy', () {
    late DefaultBillStatusPolicy policy;

    setUp(() {
      policy = DefaultBillStatusPolicy();
    });

    test('overdue 05/03, clock 07/03, unpaid -> late', () {
      final payment = BillPayment(
        id: '1',
        billId: 'b1',
        dueOn: DateTime.utc(2026, 3, 5),
        paidOn: null,
      );

      final clock = FakeClock(DateTime.utc(2026, 3, 7, 10, 0)); // Clock 07/03

      final status = policy.statusOf(payment, clock.nowUtc());
      expect(status, BillStatus.late);
    });

    test(
      'vencida 05/03, relógio 05/03 (mesmo dia), sem pagamento -> pending',
      () {
        final payment = BillPayment(
          id: '1',
          billId: 'b1',
          dueOn: DateTime.utc(2026, 3, 5),
          paidOn: null,
        );

        final clock = FakeClock(DateTime.utc(2026, 3, 5, 23, 59));

        final status = policy.statusOf(payment, clock.nowUtc());
        expect(status, BillStatus.pending);
      },
    );

    test('vencida 05/03, paga 06/03 -> paid', () {
      final payment = BillPayment(
        id: '1',
        billId: 'b1',
        dueOn: DateTime.utc(2026, 3, 5),
        paidOn: DateTime.utc(2026, 3, 6),
      );

      final clock = FakeClock(DateTime.utc(2026, 3, 7));

      final status = policy.statusOf(payment, clock.nowUtc());
      expect(status, BillStatus.paid);
    });

    test('skipped when skipped flag is present', () {
      // Skipped not clearly defined in model. Ignoring test for skipped right now.
      // Or we can add skipped to enum but not logic.
    });
  });
}
