import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/reminder_planner.dart';
import 'package:my_sweet_home/features/bills/domain/schedule_bill_reminders_use_case.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

import '../../fakes/fake_bill_repository.dart';
import '../../fakes/fake_clock.dart';
import '../../fakes/recording_scheduler.dart';

import 'package:my_sweet_home/core/id/id_generator.dart';

class FakeIdGenerator implements IdGenerator {
  @override
  String newId() => 'id_${DateTime.now().millisecondsSinceEpoch}';
}

class FakeBillPaymentRepository implements BillPaymentRepository {
  final Map<BillPaymentId, BillPayment> _payments = {};

  @override
  Future<Result<List<BillPayment>, Failure>> ofMonth(YearMonth m) async {
    return Ok(
      _payments.values.where((p) => YearMonth.of(p.dueOn) == m).toList(),
    );
  }

  @override
  Future<Result<BillPayment, Failure>> markPaid(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  }) async {
    final p = _payments[id];
    if (p == null) return const Err(StorageFailure(detail: 'not found'));
    final updated = BillPayment(
      id: p.id,
      billId: p.billId,
      dueOn: p.dueOn,
      paidAmount: amount,
      paidOn: paidOn,
    );
    _payments[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<BillPayment, Failure>> unmarkPaid(BillPaymentId id) async {
    final p = _payments[id];
    if (p == null) return const Err(StorageFailure(detail: 'not found'));
    final updated = BillPayment(
      id: p.id,
      billId: p.billId,
      dueOn: p.dueOn,
      paidAmount: null,
      paidOn: null,
    );
    _payments[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<List<BillPayment>, Failure>> historyOf(BillId id) async {
    return Ok(_payments.values.where((p) => p.billId == id).toList());
  }

  @override
  Future<Result<int, Failure>> upsertOccurrences(
    List<BillPayment> payments,
  ) async {
    for (final p in payments) {
      _payments[p.id] = p;
    }
    return Ok(payments.length);
  }

  @override
  Future<Result<BillPayment?, Failure>> byId(BillPaymentId id) async {
    return Ok(_payments[id]);
  }
}

void main() {
  group('ScheduleBillRemindersUseCase (T-04)', () {
    late FakeBillRepository billRepo;
    late FakeBillPaymentRepository paymentRepo;
    late RecordingScheduler scheduler;
    late FakeClock clock;
    late ScheduleBillRemindersUseCase useCase;

    setUp(() {
      billRepo = FakeBillRepository(FakeIdGenerator());
      paymentRepo = FakeBillPaymentRepository();
      scheduler = RecordingScheduler();
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
      'agenda notificaÃ§Ãµes para contas ativas com histÃ³rico pendente',
      () async {
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

        await paymentRepo.upsertOccurrences([
          BillPayment(
            id: 'pay_1',
            billId: bill.id,
            dueOn: DateTime.utc(2026, 3, 5),
          ),
        ]);

        final result = await useCase();
        expect(result.isOk, isTrue);

        final scheduled = scheduler.scheduled;
        expect(scheduled.length, 2); // prÃ©via e do dia
        expect(scheduled.any((n) => n.id == 'pay_1_advance'), isTrue);
        expect(scheduled.any((n) => n.id == 'pay_1_due'), isTrue);
      },
    );

    test(
      'does not schedule notifications for already paid bills (RN-134)',
      () async {
        final billResult = await billRepo.upsert(
          NewBill(
            id: 'bill_1',
            title: 'Internet',
            categoryId: const CategoryId('cat_1'),
            dueDay: 10,
            recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY')!,
            isEstimated: false,
          ),
        );
        final bill = billResult.valueOrNull!;

        await paymentRepo.upsertOccurrences([
          BillPayment(
            id: 'pay_1',
            billId: bill.id,
            dueOn: DateTime.utc(2026, 3, 10),
            paidOn: DateTime.utc(2026, 3, 5),
          ),
        ]);

        final result = await useCase();
        expect(result.isOk, isTrue);
        expect(scheduler.scheduled, isEmpty);
      },
    );
  });
}
