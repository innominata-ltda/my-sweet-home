import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';

void main() {
  group('ReminderPlanner (CA-1.1)', () {
    late ReminderPlanner planner;
    late QuietHours quiet;

    setUp(() {
      planner = const DefaultReminderPlanner();
      quiet = const QuietHours();
    });

    test('01/03 -> notifications 02/03 and 05/03', () {
      final payment = BillPayment(
        id: 'pay_1',
        billId: 'bill_1',
        dueOn: DateTime.utc(2026, 3, 5), // dueOn IS still UTC in domain
      );

      final now = DateTime(2026, 3, 1, 12, 0); // now is local

      final notifications = planner.plan(
        payment: payment,
        billTitle: 'Aluguel',
        daysBefore: 3,
        now: now,
        quiet: quiet,
      );

      expect(notifications.length, 2);

      expect(notifications[0].id, 'pay_1_advance');
      expect(notifications[0].scheduledAt, DateTime(2026, 3, 2, 9, 0));

      expect(notifications[1].id, 'pay_1_due');
      expect(notifications[1].scheduledAt, DateTime(2026, 3, 5, 9, 0));
    });

    test('does not plan for paid occurrence (RN-134)', () {
      final payment = BillPayment(
        id: 'pay_1',
        billId: 'bill_1',
        dueOn: DateTime.utc(2026, 3, 5),
        paidOn: DateTime.utc(2026, 3, 2),
      );

      final notifications = planner.plan(
        payment: payment,
        billTitle: 'Aluguel',
        daysBefore: 3,
        now: DateTime(2026, 3, 1),
        quiet: quiet,
      );

      expect(notifications, isEmpty);
    });
  });

  group('QuietHours (CA-3.1)', () {
    test('scheduling at 23h moves to 08h of next day', () {
      const quiet = QuietHours();

      final original = DateTime(2026, 3, 5, 23, 0);
      final adjusted = quiet.adjust(original);

      expect(adjusted, DateTime(2026, 3, 6, 8, 0));
    });

    test('scheduling at 02h moves to 08h of same day', () {
      const quiet = QuietHours();

      final original = DateTime(2026, 3, 6, 2, 0);
      final adjusted = quiet.adjust(original);

      expect(adjusted, DateTime(2026, 3, 6, 8, 0));
    });

    test('scheduling at 10h remains 10h', () {
      const quiet = QuietHours();

      final original = DateTime(2026, 3, 6, 10, 0);
      final adjusted = quiet.adjust(original);

      expect(adjusted, DateTime(2026, 3, 6, 10, 0));
    });
  });
}
