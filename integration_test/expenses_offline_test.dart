import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_category_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/services/default_expense_exporter.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Airplane mode active: network request blocked in offline test environment',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  group('Offline expenses and CSV/PDF export', () {
    late AppDatabase db;
    late DriftExpenseRepository expenseRepo;
    late DriftCategoryRepository categoryRepo;
    late DefaultExpenseExporter exporter;

    setUp(() async {
      db = AppDatabase.memory();
      const clock = SystemClock();
      const idGen = UuidV7Generator();
      final trashPolicy = DriftTrashPolicy(db: db, clock: clock);

      expenseRepo = DriftExpenseRepository(
        db: db,
        idGenerator: idGen,
        clock: clock,
        trashPolicy: trashPolicy,
      );

      categoryRepo = DriftCategoryRepository(db, clock);
      await categoryRepo.ensureDefaults();

      exporter = DefaultExpenseExporter(
        expenseRepository: expenseRepo,
        categoryRepository: categoryRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Adds, edits, deletes, and exports expenses in offline airplane mode',
      () async {
        // 1. Add expense
        final localNow = DateTime.now(); // Test execution environment is fine
        final newExpense = NewExpense(
          amount: const Money(3200),
          occurredOn: localNow,
          description: 'Initial market',
        );

        final addResult = await expenseRepo.add(newExpense);
        expect(
          addResult.isOk,
          isTrue,
          reason: 'Must save offline successfully',
        );
        final savedExpense = addResult.valueOrNull!;

        // 2. Edit expense
        final editResult = await expenseRepo.update(
          savedExpense.id,
          NewExpense(
            amount: const Money(3500),
            occurredOn: savedExpense.occurredOn,
            description: 'Edited market',
            categoryId: savedExpense.categoryId,
          ),
        );
        expect(
          editResult.isOk,
          isTrue,
          reason: 'Must edit offline successfully',
        );

        // 3. Delete expense
        final deleteResult = await expenseRepo.remove(savedExpense.id);
        expect(
          deleteResult.isOk,
          isTrue,
          reason: 'Must delete offline successfully',
        );

        // 4. Create multiple expenses to verify CSV Excel pt-BR formatting
        final range = DateRange(
          DateTime(localNow.year, localNow.month),
          DateTime(localNow.year, localNow.month, 28),
        );

        for (var i = 0; i < 50; i++) {
          await expenseRepo.add(
            NewExpense(
              amount: const Money(1000),
              occurredOn: range.start.add(Duration(days: i % 25)),
              description: 'Test $i',
            ),
          );
        }

        // 5. Export to CSV
        final csvResult = await exporter.toCsv(range);
        expect(
          csvResult.isOk,
          isTrue,
          reason: 'Must generate CSV offline successfully',
        );

        final csvFile = csvResult.valueOrNull!;
        expect(csvFile.name.endsWith('.csv'), isTrue);
        expect(csvFile.bytes.isNotEmpty, isTrue);

        final csvString = utf8.decode(csvFile.bytes);
        // Validating pt-BR currency formatting (e.g., 35,00 or 10,00) and semicolon separator
        expect(csvString.contains(';10,00'), isTrue);
        expect(csvString.contains(';Total;500,00'), isTrue);

        // 6. Export to PDF
        final pdfResult = await exporter.toPdf(range);
        expect(
          pdfResult.isOk,
          isTrue,
          reason: 'Must generate PDF offline successfully',
        );
        final pdfFile = pdfResult.valueOrNull!;
        expect(pdfFile.name.endsWith('.pdf'), isTrue);
        expect(pdfFile.bytes.isNotEmpty, isTrue);
      },
    );
  });
}
