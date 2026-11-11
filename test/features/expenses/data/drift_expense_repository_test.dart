import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  late AppDatabase db;
  late SystemClock clock;
  late IdGenerator idGenerator;
  late DriftTrashPolicy trashPolicy;
  late DriftExpenseRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = SystemClock();
    idGenerator = const UuidV7Generator();
    trashPolicy = DriftTrashPolicy(db: db, clock: clock);
    repository = DriftExpenseRepository(
      db: db,
      clock: clock,
      idGenerator: idGenerator,
      trashPolicy: trashPolicy,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('add should create a new expense', () async {
    final result = await repository.add(
      NewExpense(
        amount: const Money(10000),
        occurredOn: DateTime.utc(2026, 9, 15),
        description: 'Mercado',
      ),
    );

    // print removed
    expect(result.isOk, isTrue);
    final expense = result.valueOrNull!;
    expect(expense.amount, const Money(10000));
    expect(expense.description, 'Mercado');
    expect(expense.occurredOn, DateTime.utc(2026, 9, 15));
  });

  test('update should modify an existing expense', () async {
    final addResult = await repository.add(
      NewExpense(
        amount: const Money(10000),
        occurredOn: DateTime.utc(2026, 9, 15),
      ),
    );
    final expenseId = addResult.valueOrNull!.id;

    final updateResult = await repository.update(
      expenseId,
      NewExpense(
        amount: const Money(20000),
        occurredOn: DateTime.utc(2026, 9, 16),
        description: 'Padaria',
      ),
    );

    expect(updateResult.isOk, isTrue);
    final updated = updateResult.valueOrNull!;
    expect(updated.amount, const Money(20000));
    expect(updated.description, 'Padaria');
  });

  test('byId should return null for non-existent expense', () async {
    final result = await repository.byId(const ExpenseId('non-existent'));
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('ofMonth should return expenses for the specified month', () async {
    await repository.add(
      NewExpense(
        amount: const Money(100),
        occurredOn: DateTime.utc(2026, 9, 1),
      ),
    );
    await repository.add(
      NewExpense(
        amount: const Money(200),
        occurredOn: DateTime.utc(2026, 9, 30),
      ),
    );
    await repository.add(
      NewExpense(
        amount: const Money(300),
        occurredOn: DateTime.utc(2026, 10, 1),
      ),
    );

    final result = await repository.ofMonth(const YearMonth('2026-09'));
    expect(result.isOk, isTrue);
    final expenses = result.valueOrNull!;
    expect(expenses.length, 2);
  });
}
