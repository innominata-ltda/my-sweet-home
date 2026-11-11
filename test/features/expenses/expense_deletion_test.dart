import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

void main() {
  late AppDatabase db;
  late SystemClock clock;
  late IdGenerator idGenerator;
  late DriftTrashPolicy trashPolicy;
  late DriftExpenseRepository expenseRepository;
  late DriftMonthSummaryRepository monthSummaryRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = SystemClock();
    idGenerator = const UuidV7Generator();
    trashPolicy = DriftTrashPolicy(db: db, clock: clock);
    expenseRepository = DriftExpenseRepository(
      db: db,
      clock: clock,
      idGenerator: idGenerator,
      trashPolicy: trashPolicy,
    );
    monthSummaryRepository = DriftMonthSummaryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'CA-5.1: Excluir despesa e desfazer ajusta o dashboard adequadamente',
    () async {
      // 1. Setup: Create category and budget
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat1',
              name: 'AlimentaÃ§Ã£o',
              iconKey: 'food',
              kind: 'expense',
              isSystem: const Value(true),
            ),
          );

      const monthStr = '2026-09';
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: 'b1',
              yearMonth: monthStr,
              limitCents: 100000, // R$ 1000,00
            ),
          );

      // 2. Adicionar uma despesa de R$ 150,00
      final expenseDate = DateTime.utc(2026, 9, 10);
      final expenseResult = await expenseRepository.add(
        NewExpense(
          amount: const Money(15000),
          occurredOn: expenseDate,
          categoryId: const CategoryId('cat1'),
        ),
      );
      expect(expenseResult.isOk, isTrue);
      final expenseId = expenseResult.valueOrNull!.id;

      // 3. Verifica o dashboard antes de deletar
      final summaryBefore = await monthSummaryRepository.summarize(
        const YearMonth(monthStr),
      );
      expect(summaryBefore.isOk, isTrue);
      expect(summaryBefore.valueOrNull!.actual, const Money(15000));
      expect(
        summaryBefore.valueOrNull!.remaining,
        const Money(85000),
      ); // 1000 - 150

      // 4. Deletar a despesa
      final removeResult = await expenseRepository.remove(expenseId);
      expect(removeResult.isOk, isTrue);
      final trashTicket = removeResult.valueOrNull!;
      expect(trashTicket.table, 'expenses');

      // 5. Verify dashboard after deletion (expense no longer counted)
      final summaryAfterDelete = await monthSummaryRepository.summarize(
        const YearMonth(monthStr),
      );
      expect(summaryAfterDelete.isOk, isTrue);
      expect(summaryAfterDelete.valueOrNull!.actual, const Money(0));
      expect(summaryAfterDelete.valueOrNull!.remaining, const Money(100000));

      // 6. User taps "Undo" (invokes restore)
      final restoreResult = await trashPolicy.restore(trashTicket);
      expect(restoreResult.isOk, isTrue);

      // 7. Verify dashboard after undo (expense counted again)
      final summaryAfterRestore = await monthSummaryRepository.summarize(
        const YearMonth(monthStr),
      );
      expect(summaryAfterRestore.isOk, isTrue);
      expect(summaryAfterRestore.valueOrNull!.actual, const Money(15000));
      expect(summaryAfterRestore.valueOrNull!.remaining, const Money(85000));
    },
  );
}
