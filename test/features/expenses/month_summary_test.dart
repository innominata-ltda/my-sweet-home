import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  late AppDatabase db;
  late DriftMonthSummaryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftMonthSummaryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('CA-3.1: in-memory db: budget 1000, actual 760 -> remaining 240, separate forecast', () async {
    // Insert categories
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'c1',
            name: 'Alimentação',
            iconKey: 'food',
            kind: 'expense',
            isSystem: const Value(true),
          ),
        );

    // Insert budgets
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: 'b1',
            yearMonth: '2026-09',
            limitCents: 100000,
          ),
        ); // overall budget 1000.00

    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: 'b2',
            yearMonth: '2026-09',
            categoryId: const Value('c1'),
            limitCents: 50000,
          ),
        ); // category budget 500.00

    // Insert expenses for 2026-09
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'e1',
            amountCents: 50000,
            occurredOn: '2026-09-05',
            categoryId: const Value('c1'),
          ),
        );

    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'e2',
            amountCents: 26000,
            occurredOn: '2026-09-10',
          ),
        );

    // Insert expenses for history (2 distinct months)
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'e3',
            amountCents: 10000,
            occurredOn: '2026-08-15',
          ),
        );

    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'e4',
            amountCents: 15000,
            occurredOn: '2026-07-20',
          ),
        );

    final result = await repository.summarize(const YearMonth('2026-09'));
    expect(result.isOk, isTrue);

    final summary = result.valueOrNull!;
    expect(summary.budget, const Money(100000));
    expect(summary.actual, const Money(76000));
    expect(summary.remaining, const Money(24000));
    expect(summary.monthsOfHistory, 2);

    // Category slices
    final c1Slice = summary.byCategory.firstWhere(
      (s) => s.categoryId.value == 'c1',
    );
    expect(c1Slice.actual, const Money(50000));
    expect(c1Slice.budget, const Money(50000));
    expect(c1Slice.remaining, const Money(0));
  });

  group('YearMonth value object', () {
    test('YearMonth.of formata corretamente com padding', () {
      final ym = YearMonth.of(DateTime(2026, 4, 15));
      expect(ym.iso, '2026-04');
    });

    test('previous calculates previous month with year rollover', () {
      expect(const YearMonth('2026-05').previous.iso, '2026-04');
      expect(const YearMonth('2026-01').previous.iso, '2025-12');
    });

    test('next calculates next month with year rollover', () {
      expect(const YearMonth('2026-05').next.iso, '2026-06');
      expect(const YearMonth('2026-12').next.iso, '2027-01');
    });

    test('bounds returns correct range from first to last day', () {
      final bounds = const YearMonth('2026-02').bounds;
      expect(bounds.start, DateTime(2026, 2, 1));
      expect(bounds.end, DateTime(2026, 2, 28));
    });
  });
}
