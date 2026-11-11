import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_category_repository.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/fake_expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/services/expense_exporter.dart';
import 'package:my_sweet_home/features/expenses/domain/services/default_expense_exporter.dart';

import '../../fakes/fake_clock.dart';

void main() {
  group('DefaultExpenseExporter - CA-6.1', () {
    late FakeExpenseRepository expenseRepo;
    late FakeCategoryRepository categoryRepo;
    late DefaultExpenseExporter exporter;

    setUp(() async {
      final clock = FakeClock(DateTime(2026, 9, 30));
      expenseRepo = FakeExpenseRepository(clock);
      categoryRepo = FakeCategoryRepository();
      await categoryRepo.ensureDefaults();

      exporter = DefaultExpenseExporter(
        expenseRepository: expenseRepo,
        categoryRepository: categoryRepo,
      );
    });

    test('Dadas 50 despesas de setembro, exporta CSV e PDF', () async {
      // Cria 50 despesas em setembro de 2026
      for (var i = 1; i <= 50; i++) {
        await expenseRepo.add(
          NewExpense(
            amount: const Money(3200), // R$ 32,00
            occurredOn: DateTime(2026, 9, 15),
            description: 'Despesa \$i',
            categoryId: const CategoryId(
              'cat_market',
            ), // 'Mercado' assume-se que exista no fake
          ),
        );
      }

      final range = DateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      // Teste CSV
      final csvResult = await exporter.toCsv(range);
      expect(csvResult, isA<Ok<ExportedFile, Failure>>());
      final csvFile = csvResult.valueOrNull!;

      expect(csvFile.name, 'despesas_20260901-20260930.csv');
      expect(csvFile.mimeType, 'text/csv');

      // Verifica o BOM
      expect(csvFile.bytes[0], 0xEF);
      expect(csvFile.bytes[1], 0xBB);
      expect(csvFile.bytes[2], 0xBF);

      final csvString = utf8.decode(csvFile.bytes);

      // Verify header and separator
      expect(csvString.contains('Data;Descrição;Categoria;Valor'), isTrue);

      // Verify value (32.00 in pt-BR standard: 32,00)
      expect(csvString.contains(';32,00'), isTrue);

      // Conta as linhas: BOM+Header (1) + 50 despesas + Total (1) + final \n
      // But split('\n') can produce an extra element if trailing with newline.
      final lines = csvString.trim().split('\n');
      expect(lines.length, 52); // Header + 50 + Total

      // Verifica o Total: 50 * 32,00 = 1600,00
      expect(lines.last.contains('Total;1600,00'), isTrue);

      // Teste PDF
      final pdfResult = await exporter.toPdf(range);
      expect(pdfResult, isA<Ok<ExportedFile, Failure>>());
      final pdfFile = pdfResult.valueOrNull!;

      expect(pdfFile.name, 'despesas_20260901-20260930.pdf');
      expect(pdfFile.mimeType, 'application/pdf');
      expect(pdfFile.bytes.isNotEmpty, isTrue);
    });
  });
}
