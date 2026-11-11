import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:my_sweet_home/core/concurrency/background_runner_port.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/services/expense_exporter.dart';

class DefaultExpenseExporter implements ExpenseExporter {
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;
  final BackgroundRunnerPort? runner;

  DefaultExpenseExporter({
    required this.expenseRepository,
    required this.categoryRepository,
    this.runner,
  });

  @override
  Future<Result<ExportedFile, Failure>> toCsv(DateRange range) async {
    try {
      final expensesResult = await _getExpensesInRange(range);
      if (expensesResult is Err<List<Expense>, Failure>) {
        return Err(expensesResult.failureOrNull!);
      }
      final expenses = expensesResult.valueOrNull!;

      final categoriesResult = await categoryRepository.all();
      if (categoriesResult is Err<List<Category>, Failure>) {
        return Err(categoriesResult.failureOrNull!);
      }
      final categories = categoriesResult.valueOrNull!;
      final categoryMap = {for (final c in categories) c.id: c.name};

      final startFmt = DateFormat('yyyyMMdd').format(range.start);
      final endFmt = DateFormat('yyyyMMdd').format(range.end);

      Uint8List buildCsv() {
        final buffer = StringBuffer();
        // UTF-8 BOM
        buffer.write('\uFEFF');

        // Header
        buffer.writeln('Data;Descrição;Categoria;Valor');

        var totalCents = 0;

        for (final e in expenses) {
          final dateStr = DateFormat('dd/MM/yyyy').format(e.occurredOn);
          final description = e.description ?? '';
          final category = e.categoryId != null
              ? (categoryMap[e.categoryId!] ?? 'Sem Categoria')
              : 'Sem Categoria';

          final absAmount = e.amount.cents.abs();
          final amountStr =
              '${absAmount ~/ 100},${(absAmount % 100).toString().padLeft(2, '0')}';
          final sign = e.amount.cents < 0 ? '-' : '';

          // Escape description if needed
          final escapedDesc =
              description.contains(';') ||
                  description.contains('"') ||
                  description.contains('\n')
              ? '"${description.replaceAll('"', '""')}"'
              : description;

          buffer.writeln('$dateStr;$escapedDesc;$category;$sign$amountStr');
          totalCents += e.amount.cents;
        }

        final absTotal = totalCents.abs();
        final totalStr =
            '${absTotal ~/ 100},${(absTotal % 100).toString().padLeft(2, '0')}';
        final totalSign = totalCents < 0 ? '-' : '';

        buffer.writeln(';;Total;$totalSign$totalStr');

        return Uint8List.fromList(utf8.encode(buffer.toString()));
      }

      final Uint8List bytes;
      if (runner != null) {
        bytes = await runner!.run(buildCsv);
      } else {
        bytes = buildCsv();
      }

      return Ok(
        ExportedFile(
          name: 'despesas_$startFmt-$endFmt.csv',
          bytes: bytes,
          mimeType: 'text/csv',
        ),
      );
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao gerar CSV', cause: e));
    }
  }

  @override
  Future<Result<ExportedFile, Failure>> toPdf(DateRange range) async {
    try {
      final expensesResult = await _getExpensesInRange(range);
      if (expensesResult is Err<List<Expense>, Failure>) {
        return Err(expensesResult.failureOrNull!);
      }
      final expenses = expensesResult.valueOrNull!;

      final categoriesResult = await categoryRepository.all();
      if (categoriesResult is Err<List<Category>, Failure>) {
        return Err(categoriesResult.failureOrNull!);
      }
      final categories = categoriesResult.valueOrNull!;
      final categoryMap = {for (final c in categories) c.id: c.name};

      final startFmt = DateFormat('yyyyMMdd').format(range.start);
      final endFmt = DateFormat('yyyyMMdd').format(range.end);
      final startLabel = DateFormat('dd/MM/yyyy').format(range.start);
      final endLabel = DateFormat('dd/MM/yyyy').format(range.end);

      Future<Uint8List> buildPdf() async {
        final pdf = pw.Document();

        var totalCents = 0;
        final rows = <List<String>>[];
        for (final e in expenses) {
          final dateStr = DateFormat('dd/MM/yyyy').format(e.occurredOn);
          final description = e.description ?? '';
          final category = e.categoryId != null
              ? (categoryMap[e.categoryId!] ?? 'Sem Categoria')
              : 'Sem Categoria';
          final amountStr = e.amount.formatPtBr();

          rows.add([dateStr, description, category, amountStr]);
          totalCents += e.amount.cents;
        }

        final totalMoney = Money(totalCents);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Relatório de Despesas',
                  style: const pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'Período: $startLabel a $endLabel',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Descrição', 'Categoria', 'Valor'],
                data: rows,
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ',
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.Text(
                    totalMoney.formatPtBr(),
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final bytes = await pdf.save();
        return bytes;
      }

      final Uint8List bytes;
      if (runner != null) {
        bytes = await runner!.run(buildPdf);
      } else {
        bytes = await buildPdf();
      }

      return Ok(
        ExportedFile(
          name: 'despesas_$startFmt-$endFmt.pdf',
          bytes: bytes,
          mimeType: 'application/pdf',
        ),
      );
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao gerar PDF', cause: e));
    }
  }

  Future<Result<List<Expense>, Failure>> _getExpensesInRange(
    DateRange range,
  ) async {
    final startYearMonth = YearMonth.of(range.start);
    final endYearMonth = YearMonth.of(range.end);

    final expenses = <Expense>[];

    // We only iterate through the months covered by the range
    // Assuming the range doesn't span decades, a simple loop is fine
    var current = startYearMonth;
    while (current.iso.compareTo(endYearMonth.iso) <= 0) {
      final res = await expenseRepository.ofMonth(current);
      if (res is Err<List<Expense>, Failure>) return res;
      expenses.addAll(res.valueOrNull!);

      // Advance to next month
      final currentStart = current.bounds.start;
      final nextMonthDate = DateTime(currentStart.year, currentStart.month + 1);
      current = YearMonth.of(nextMonthDate);
    }

    // Filter exactly within range
    final filtered = expenses.where((e) {
      final dt = e.occurredOn;
      // DateRange boundaries are inclusive
      return (dt.isAtSameMomentAs(range.start) || dt.isAfter(range.start)) &&
          (dt.isAtSameMomentAs(range.end) || dt.isBefore(range.end));
    }).toList();

    // Sort by date desc
    filtered.sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

    return Ok(filtered);
  }
}
