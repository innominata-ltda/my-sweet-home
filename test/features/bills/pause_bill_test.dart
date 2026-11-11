import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/pause_bill_use_case.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

import '../../fakes/fake_bill_payment_repository.dart';
import '../../fakes/fake_bill_repository.dart';
import '../../fakes/fake_clock.dart';
import '../../fakes/recording_scheduler.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  late FakeBillRepository billRepo;
  late FakeBillPaymentRepository paymentRepo;
  late RecordingScheduler scheduler;
  late FakeClock clock;
  late PauseBillUseCase useCase;

  setUp(() {
    billRepo = FakeBillRepository(SequentialIdGenerator(prefix: 'b'));
    paymentRepo = FakeBillPaymentRepository();
    scheduler = RecordingScheduler();
    clock = FakeClock(DateTime.utc(2026, 3, 1, 10)); // 2026-03-01
    useCase = DefaultPauseBillUseCase(billRepo, paymentRepo, scheduler, clock);
  });

  test('CA-5.1 / RN-137: Pausing a bill stops generation and cancels notifications, preserving history', () async {
    // 1. Cadastrar uma conta
    final newBill = NewBill(
      title: 'Academia',
      categoryId: const CategoryId('cat1'),
      dueDay: 5,
      recurrence: RecurrenceRule.tryParse(
        'FREQ=MONTHLY',
        dtStart: DateTime.utc(2026, 1, 5),
      )!,
      isEstimated: false,
    );
    final billResult = await billRepo.upsert(newBill);
    final billId = billResult.valueOrNull!.id;

    // 2. Insert occurrences in history (1 paid, 1 pending)
    final p1 = BillPayment(
      id: 'p1',
      billId: billId,
      dueOn: DateTime.utc(2026, 2, 5),
      paidOn: DateTime.utc(2026, 2, 4),
    );
    final p2 = BillPayment(
      id: 'p2',
      billId: billId,
      dueOn: DateTime.utc(2026, 3, 5),
    );
    await paymentRepo.upsertOccurrences([p1, p2]);

    // 3. Simulate scheduled notifications for p2
    await scheduler.schedule(
      ScheduledNotification(
        id: 'p2_advance',
        title: 'Aviso',
        body: 'Corpo',
        scheduledAt: DateTime.utc(2026, 3, 2, 8),
      ),
    );
    await scheduler.schedule(
      ScheduledNotification(
        id: 'p2_due',
        title: 'Hoje',
        body: 'Corpo',
        scheduledAt: DateTime.utc(2026, 3, 5, 8),
      ),
    );

    expect(scheduler.scheduled.length, 2);

    // 4. Pausar a conta
    final res = await useCase(billId);
    expect(res.isOk, isTrue);

    // Verify bill is paused
    final updatedBill = (await billRepo.byId(billId)).valueOrNull!;
    expect(updatedBill.isPaused, isTrue);

    // Verify bill is no longer returned in active()
    final activeBills = (await billRepo.active()).valueOrNull!;
    expect(activeBills, isEmpty);

    // Verify history remains
    final history = (await paymentRepo.historyOf(billId)).valueOrNull!;
    expect(history.length, 2);

    // Verify future notifications were cancelled
    expect(scheduler.scheduled.length, 0);
  });
}
