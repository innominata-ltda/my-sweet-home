import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/recurrence/expense_materializer.dart';

import '../../fakes/fake_clock.dart'; // Fixed path

void main() {
  late AppDatabase db;
  late ExpenseMaterializer materializer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    materializer = ExpenseMaterializer(
      db: db,
      idGenerator: const UuidV7Generator(), // Fixed class name
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('CA-2.1: Materializes 3 months and is idempotent', () async {
    final clock = FakeClock(DateTime.utc(2026, 3, 10));

    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'rule-1',
            kind: 'expense',
            rrule: 'FREQ=MONTHLY;BYMONTHDAY=5',
            startsOn: '2026-01-05',
            amountCents: const Value(2190),
            title: 'Spotify',
            categoryId: const Value(null),
          ),
        );

    final result1 = await materializer.materializeUpTo(clock.nowUtc());
    expect(result1.valueOrNull, 3); // 05/01, 05/02, 05/03

    final expenses1 = await db.select(db.expenses).get();
    expect(expenses1.length, 3);
    final dates = expenses1.map((e) => e.occurredOn).toList()..sort();
    expect(dates, ['2026-01-05', '2026-02-05', '2026-03-05']);

    // Act 2: Materialize again (idempotency check)
    final result2 = await materializer.materializeUpTo(clock.nowUtc());
    expect(result2.valueOrNull, 0);

    final expenses2 = await db.select(db.expenses).get();
    expect(expenses2.length, 3); // Must not duplicate
  });

  test('CA-2.2: Day 31 rule in February', () async {
    final clock = FakeClock(DateTime.utc(2026, 3, 1));

    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'rule-2',
            kind: 'expense',
            rrule: 'FREQ=MONTHLY;BYMONTHDAY=31',
            startsOn: '2026-01-31',
            amountCents: const Value(1000),
            title: 'Netflix',
            categoryId: const Value(null),
          ),
        );

    final result = await materializer.materializeUpTo(clock.nowUtc());
    expect(result.valueOrNull, 2); // 31/01 and 28/02

    var expenses = await db.select(db.expenses).get();
    expect(expenses.length, 2);
    final dates = expenses.map((e) => e.occurredOn).toList()..sort();
    expect(dates, ['2026-01-31', '2026-02-28']);

    final result2 = await materializer.materializeUpTo(clock.nowUtc());
    expect(result2.valueOrNull, 0);

    expenses = await db.select(db.expenses).get();
    expect(expenses.length, 2);
  });

  test(
    'CA-2.3: Changes amount, verifies past 3 months remain unchanged',
    () async {
      final clock = FakeClock(DateTime.utc(2026, 3, 10));

      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: 'rule-3',
              kind: 'expense',
              rrule: 'FREQ=MONTHLY;BYMONTHDAY=5',
              startsOn: '2026-01-05',
              amountCents: const Value(2190),
              title: 'Assinatura',
              categoryId: const Value(null),
            ),
          );

      await materializer.materializeUpTo(clock.nowUtc());
      final idempotencyCheck1 = await materializer.materializeUpTo(
        clock.nowUtc(),
      );
      expect(idempotencyCheck1.valueOrNull, 0);

      var expenses = await db.select(db.expenses).get();
      expect(expenses.every((e) => e.amountCents == 2190), isTrue);

      await (db.update(db.recurringRules)..where((t) => t.id.equals('rule-3')))
          .write(const RecurringRulesCompanion(amountCents: Value(2590)));

      clock.advance(const Duration(days: 31)); // to 2026-04-10
      final result = await materializer.materializeUpTo(clock.nowUtc());
      expect(result.valueOrNull, 1); // 05/04

      final idempotencyCheck2 = await materializer.materializeUpTo(
        clock.nowUtc(),
      );
      expect(idempotencyCheck2.valueOrNull, 0);

      expenses =
          await (db.select(db.expenses)..orderBy([
                (t) => OrderingTerm(
                  expression: t.occurredOn,
                  mode: OrderingMode.asc,
                ),
              ]))
              .get();
      expect(expenses.length, 4);
      expect(expenses[0].amountCents, 2190);
      expect(expenses[1].amountCents, 2190);
      expect(expenses[2].amountCents, 2190);
      expect(expenses[3].amountCents, 2590); // 2026-04-05
    },
  );
}
