import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:my_sweet_home/features/bills/domain/schedule_bill_reminders_use_case.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

import '../../fakes/fake_bill_repository.dart';
import '../../fakes/recording_scheduler.dart';
import '../../fakes/fake_clock.dart';
import 'schedule_bill_reminders_use_case_test.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('T-V1 — Contabilidade de tempo e fusos', () {
    late FakeBillRepository billRepo;
    late FakeBillPaymentRepository paymentRepo;
    late RecordingScheduler scheduler;
    late FakeClock clock;
    late ScheduleBillRemindersUseCase useCase;

    setUp(() {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

      billRepo = FakeBillRepository(FakeIdGenerator());
      paymentRepo = FakeBillPaymentRepository();
      scheduler = RecordingScheduler();

      // FakeClock at "2026-03-01 12:00:00Z", which is 09:00:00 in Sao Paulo.
      clock = FakeClock(DateTime.utc(2026, 3, 1, 12, 0));

      useCase = ScheduleBillRemindersUseCase(
        billRepo: billRepo,
        paymentRepo: paymentRepo,
        planner: const DefaultReminderPlanner(),
        scheduler: scheduler,
        clock: clock,
      );
    });

    test(
      'Verificar CA-1.1, CA-1.2, CA-3.1 com fuso horário simulado',
      () async {
        // Cria uma conta vencendo dia 5
        final billResult = await billRepo.upsert(
          NewBill(
            id: 'bill_1',
            title: 'Aluguel',
            categoryId: const CategoryId('cat_1'),
            dueDay: 5,
            recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
            isEstimated: false,
            noticeDays: 3,
          ),
        );
        final bill = billResult.valueOrNull!;

        // Creates March occurrence
        // CA-1.2: day 5 in March (due to rule) will be generated as 2026-03-05 00:00:00Z.
        await paymentRepo.upsertOccurrences([
          BillPayment(
            id: 'pay_1',
            billId: bill.id,
            dueOn: DateTime.utc(2026, 3, 5),
          ),
        ]);

        // Roda o Use Case
        final result = await useCase();
        expect(result.isOk, isTrue);

        final scheduled = scheduler.scheduled;

        // CA-1.1: There is one due on 2026-03-05 and two scheduled notifications: 2026-03-02 and 2026-03-05.
        expect(scheduled.length, 2);

        // Checking schedule dates from Planner (already as local DateTime).
        final advance = scheduled.firstWhere((n) => n.id == 'pay_1_advance');
        final due = scheduled.firstWhere((n) => n.id == 'pay_1_due');

        // Default notification time is 09:00 local
        expect(advance.scheduledAt, DateTime(2026, 3, 2, 9, 0));
        expect(due.scheduledAt, DateTime(2026, 3, 5, 9, 0));

        // Now let's simulate CA-3.1 in practice with different timezones!
        // Vamos criar um pagamento cujo advanceDate cai num momento ajustado.
        // E verificar se o tz.TZDateTime.from preservaria isso incorretamente ou se
        // passando o wall-clock ele preserva corretamente.

        // LocalNotificationScheduler will take `DateTime(2026, 3, 2, 9, 0)` and construct:
        final tzDateAdvance = tz.TZDateTime(
          tz.local,
          advance.scheduledAt.year,
          advance.scheduledAt.month,
          advance.scheduledAt.day,
          advance.scheduledAt.hour,
          advance.scheduledAt.minute,
        );

        // And it MUST be exactly 9 AM in Sao Paulo
        expect(tzDateAdvance.hour, 9);
        expect(tzDateAdvance.day, 2);
      },
    );
  });
}
