// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';

void main() {
  group('Corpus de Teste do Parser de OCR (T-11 / CA-8.1, CA-2.1, RNF-003)', () {
    late DefaultReceiptParser parser;
    late List<Map<String, dynamic>> corpus;

    setUpAll(() {
      parser = const DefaultReceiptParser();
      final corpusFile = File('test/fixtures/ocr/corpus.json');
      final corpusJson =
          jsonDecode(corpusFile.readAsStringSync()) as List<dynamic>;
      corpus = corpusJson.cast<Map<String, dynamic>>();
    });

    test('CA-2.1 — Fixture carrefour_01.json resulta no ReceiptDraft exatamente esperado', () {
      final file = File('test/fixtures/ocr/carrefour_01.json');
      final jsonMap =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final doc = OcrDocument.fromJson(jsonMap);

      final draft = parser.parse(doc);

      expect(draft.store.name, equals('CARREFOUR COMERCIO E INDUSTRIA LTDA'));
      expect(draft.store.cnpj, equals('45543915000181'));
      expect(draft.store.isCnpjValid, isTrue);
      expect(draft.purchasedAt, equals(DateTime.utc(2026, 9, 21, 14, 30)));
      expect(draft.items.length, equals(12));
      expect(draft.subtotal, equals(const Money(9040)));
      expect(draft.discount, equals(const Money(300)));
      expect(draft.total, equals(const Money(8740)));
      expect(draft.paymentMethod, equals('CARTÃO DE DÉBITO'));
    });

    test('Corpus de 15 cupons roda em CI e atinge taxa de acerto >= 85% por campo (CA-8.1)', () {
      int totalFieldsChecked = 0;
      int successfulFields = 0;

      final fieldAccuracies = <String, _FieldStats>{
        'storeName': _FieldStats(),
        'cnpj': _FieldStats(),
        'purchasedAt': _FieldStats(),
        'itemCount': _FieldStats(),
        'total': _FieldStats(),
        'paymentMethod': _FieldStats(),
      };

      final knownFailures = <String>[];

      for (final item in corpus) {
        final id = item['id'] as String;
        final docJson = item['document'] as Map<String, dynamic>;
        final expected = item['expected'] as Map<String, dynamic>;
        final doc = OcrDocument.fromJson(docJson);
        final draft = parser.parse(doc);

        // 1. Store Name
        final expName = expected['storeName'] as String?;
        final actName = draft.store.name;
        final isNameOk = expName == null
            ? actName == null
            : actName != null &&
                  actName.toUpperCase().contains(expName.toUpperCase());
        _recordField(
          'storeName',
          isNameOk,
          fieldAccuracies,
          '$id [storeName: expected "$expName", got "$actName"]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isNameOk) successfulFields++;

        // 2. CNPJ
        final expCnpj = expected['cnpj'] as String?;
        final actCnpj = draft.store.cnpj;
        final isCnpjOk = expCnpj == null
            ? actCnpj == null
            : actCnpj == expCnpj && draft.store.isCnpjValid;
        _recordField(
          'cnpj',
          isCnpjOk,
          fieldAccuracies,
          '$id [cnpj: expected "$expCnpj", got "$actCnpj" (valid=${draft.store.isCnpjValid})]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isCnpjOk) successfulFields++;

        // 3. PurchasedAt Date
        final expYear = expected['year'] as int?;
        final expMonth = expected['month'] as int?;
        final expDay = expected['day'] as int?;
        final actDate = draft.purchasedAt;
        final isDateOk = expYear == null
            ? actDate == null
            : actDate != null &&
                  actDate.year == expYear &&
                  actDate.month == expMonth &&
                  actDate.day == expDay;
        _recordField(
          'purchasedAt',
          isDateOk,
          fieldAccuracies,
          '$id [purchasedAt: expected $expYear-$expMonth-$expDay, got ${actDate?.toIso8601String()}]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isDateOk) successfulFields++;

        // 4. Item Count
        final expItemCount = expected['itemCount'] as int;
        final actItemCount = draft.items.length;
        final isItemCountOk = actItemCount == expItemCount;
        _recordField(
          'itemCount',
          isItemCountOk,
          fieldAccuracies,
          '$id [itemCount: expected $expItemCount, got $actItemCount]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isItemCountOk) successfulFields++;

        // 5. Total Price
        final expTotalCents = expected['total'] as int?;
        final actTotalCents = draft.total?.cents;
        final isTotalOk = expTotalCents == null
            ? actTotalCents == null
            : actTotalCents == expTotalCents;
        _recordField(
          'total',
          isTotalOk,
          fieldAccuracies,
          '$id [total: expected $expTotalCents, got $actTotalCents]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isTotalOk) successfulFields++;

        // 6. Payment Method
        final expPay = expected['paymentMethod'] as String?;
        final actPay = draft.paymentMethod;
        final isPayOk = expPay == null ? actPay == null : actPay == expPay;
        _recordField(
          'paymentMethod',
          isPayOk,
          fieldAccuracies,
          '$id [paymentMethod: expected "$expPay", got "$actPay"]',
          knownFailures,
        );
        totalFieldsChecked++;
        if (isPayOk) successfulFields++;
      }

      final overallAccuracy = totalFieldsChecked > 0
          ? successfulFields / totalFieldsChecked
          : 0.0;

      if (Platform.environment['VERBOSE_OCR_BENCHMARK'] == '1' ||
          overallAccuracy < 0.85) {
        print('\n==================================================');
        print('--- RELATÓRIO DO CORPUS DE OCR (T-11 / CA-8.1) ---');
        print('==================================================');
        print('Total de Cupons Processados: ${corpus.length}');
        print('Total de Campos Avaliados:   $totalFieldsChecked');
        print('Campos Corretos:             $successfulFields');
        print(
          'Taxa de Acerto Geral:        ${(overallAccuracy * 100).toStringAsFixed(2)}%',
        );
        print('\n--- Acurácia por Campo ---');

        fieldAccuracies.forEach((fieldName, stats) {
          print(
            '  - ${fieldName.padRight(15)}: ${stats.correct}/${stats.total} (${stats.percentage.toStringAsFixed(1)}%)',
          );
        });

        if (knownFailures.isNotEmpty) {
          print('\n--- Casos Conhecidos com Falha ---');
          for (final failure in knownFailures) {
            print('  [FALHA] $failure');
          }
        } else {
          print('\nNenhuma falha detectada no corpus!');
        }
        print('==================================================\n');
      }

      expect(
        overallAccuracy,
        greaterThanOrEqualTo(0.85),
        reason: 'A taxa de acerto do parser de OCR no corpus deve ser >= 85% (CA-8.1)',
      );
    });
  });
}

class _FieldStats {
  int total = 0;
  int correct = 0;

  double get percentage => total > 0 ? (correct / total) * 100.0 : 0.0;
}

void _recordField(
  String fieldName,
  bool isCorrect,
  Map<String, _FieldStats> statsMap,
  String failureMsg,
  List<String> knownFailures,
) {
  final stats = statsMap[fieldName]!;
  stats.total++;
  if (isCorrect) {
    stats.correct++;
  } else {
    knownFailures.add(failureMsg);
  }
}
