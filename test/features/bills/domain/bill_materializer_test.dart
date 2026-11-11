import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart' as domain;
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

void main() {
  late AppDatabase db;
  late DriftBillRepository billRepo;
  late DriftBillPaymentRepository paymentRepo;
  late BillMaterializer materializer;

  setUp(() async {
    db = AppDatabase.memory();
    billRepo = DriftBillRepository(db);
    paymentRepo = DriftBillPaymentRepository(db);
    materializer = BillMaterializer(
      billRepo: billRepo,
      paymentRepo: paymentRepo,
      dueDatePolicy: const StandardDueDatePolicy(),
    );

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
  });

  tearDown(() async {
    await db.close();
  });

  test('kind is RecurrenceKind.bill', () {
    expect(materializer.kind, RecurrenceKind.bill);
  });

  test('materializeUpTo returns 0 when no active bills exist', () async {
    final result = await materializer.materializeUpTo(
      DateTime.utc(2026, 10, 14),
    );
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, 0);
  });

  test('materializeUpTo generates occurrences and persists payments', () async {
    await billRepo.upsert(
      domain.NewBill(
        title: 'Internet',
        categoryId: const CategoryId('cat_housing'),
        dueDay: 15,
        recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
        amount: const Money(10000),
        isEstimated: false,
      ),
    );

    final instant = DateTime.utc(2026, 10, 14);
    final result = await materializer.materializeUpTo(instant);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, greaterThan(0));

    // Verify payments in database
    final rows = await db.select(db.billPayments).get();
    expect(rows, isNotEmpty);
  });
}
