import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_service.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart' as domain;
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart'
    as domain;
import 'package:my_sweet_home/features/bills/domain/bills_preferences.dart';
import 'package:my_sweet_home/features/bills/domain/status_policy.dart';
import 'package:my_sweet_home/features/bills/presentation/bills_list_controller.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

import '../../../fakes/fake_battery_optimization.dart';
import '../../../fakes/fake_battery_warning_storage.dart';
import '../../../fakes/fake_clock.dart';
import '../../../fakes/recording_scheduler.dart';

class _FakeBillsPreferences implements BillsPreferences {
  @override
  Future<bool> get hasDismissedPermissionWarning async => false;
  @override
  Future<void> dismissPermissionWarning() async {}
}

void main() {
  late AppDatabase db;
  late DriftBillRepository billRepo;
  late DriftBillPaymentRepository paymentRepo;
  late RecordingScheduler scheduler;
  late FakeClock clock;
  late BillsListController controller;

  setUp(() async {
    db = AppDatabase.memory();
    billRepo = DriftBillRepository(db);
    paymentRepo = DriftBillPaymentRepository(db);
    scheduler = RecordingScheduler();
    clock = FakeClock(DateTime.utc(2026, 10, 15, 12));

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat_housing',
            name: 'Moradia',
            kind: 'expense',
            iconKey: 'home',
          ),
        );

    final batteryService = BatteryWarningService(
      FakeBatteryOptimization(isAndroid: false),
      FakeBatteryWarningStorage(),
    );

    controller = BillsListController(
      billRepository: billRepo,
      paymentRepository: paymentRepo,
      notificationScheduler: scheduler,
      preferences: _FakeBillsPreferences(),
      statusPolicy: DefaultBillStatusPolicy(),
      batteryWarningService: batteryService,
      clock: clock,
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('deleteBill exclui conta vinculada a despesa, cancela notificacoes e recarrega lista limpando itens', () async {
    // 1. Cadastra conta
    final res = await billRepo.upsert(
      domain.NewBill(
        title: 'Condominio',
        categoryId: const CategoryId('cat_housing'),
        dueDay: 15,
        recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
        amount: const Money(45000),
        isEstimated: false,
      ),
    );
    expect(res.isOk, isTrue);
    final bill = res.valueOrNull!;

    // 2. Cria fatura e agenda notificacoes
    final payment = domain.BillPayment(
      id: 'pay_condo_1',
      billId: bill.id,
      dueOn: DateTime.utc(2026, 10, 15),
    );
    await paymentRepo.upsertOccurrences([payment]);

    await scheduler.schedule(
      ScheduledNotification(
        id: '${payment.id}_advance',
        title: 'Lembrete',
        body: 'Vence em breve',
        scheduledAt: DateTime.utc(2026, 10, 12, 8),
      ),
    );
    await scheduler.schedule(
      ScheduledNotification(
        id: '${payment.id}_due',
        title: 'Lembrete',
        body: 'Vence hoje',
        scheduledAt: DateTime.utc(2026, 10, 15, 8),
      ),
    );
    expect(scheduler.scheduled.length, 2);

    // 3. Vincula despesa a conta fixa
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'exp_condo_1',
            amountCents: 45000,
            occurredOn: '2026-10-15',
            categoryId: const Value('cat_housing'),
            billId: Value(bill.id),
          ),
        );

    // Carrega controller
    await controller.load();
    expect(controller.value, isA<BillsListSuccess>());
    final initialSuccess = controller.value as BillsListSuccess;
    expect(initialSuccess.items.length, 1);
    expect(initialSuccess.items.first.bill.title, 'Condominio');

    // 4. Executa deleteBill
    final deleteResult = await controller.deleteBill(bill.id);
    expect(
      deleteResult.isOk,
      isTrue,
      reason: deleteResult.failureOrNull?.toString(),
    );

    // 5. Lista deve estar vazia e recarregada
    expect(controller.value, isA<BillsListSuccess>());
    final afterDeleteSuccess = controller.value as BillsListSuccess;
    expect(afterDeleteSuccess.items, isEmpty);

    // 6. Notificacoes devem ter sido canceladas
    expect(scheduler.scheduled, isEmpty);

    // 7. Despesa continua existindo com billId nulo
    final exp = await (db.select(
      db.expenses,
    )..where((t) => t.id.equals('exp_condo_1'))).getSingle();
    expect(exp.billId, isNull);
  });
}
