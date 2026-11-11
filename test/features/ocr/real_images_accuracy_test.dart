// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/text/similarity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';

void main() {
  group('OCR Parser Accuracy on Real Photos', () {
    const parser = DefaultReceiptParser();

    late File groundTruthFile;
    late File ocrDocsFile;
    late Map<String, Map<String, dynamic>> groundTruth;
    late Map<String, dynamic> ocrDocuments;

    setUpAll(() {
      groundTruthFile = File('test/fixtures/ocr/images_ground_truth.json');
      ocrDocsFile = File('test/fixtures/ocr/real_images_ocr.json');

      groundTruth = {};
      if (groundTruthFile.existsSync()) {
        final list = jsonDecode(groundTruthFile.readAsStringSync()) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          groundTruth[map['id'] as String] =
              map['expected'] as Map<String, dynamic>;
        }
      }

      ocrDocuments = {};
      if (ocrDocsFile.existsSync()) {
        ocrDocuments =
            jsonDecode(ocrDocsFile.readAsStringSync()) as Map<String, dynamic>;
      }
    });

    test('Verifies mapping and ground truth files exist', () {
      expect(
        groundTruthFile.existsSync(),
        isTrue,
        reason: 'test/fixtures/ocr/images_ground_truth.json must exist.',
      );
      expect(
        groundTruth.isNotEmpty,
        isTrue,
        reason: 'Ground truth must contain mapped receipts.',
      );
    });

    test('Runs offline benchmark against recorded ML Kit OcrDocuments', () {
      if (ocrDocuments.isEmpty) {
        print(
          '[INFO] test/fixtures/ocr/real_images_ocr.json has not been generated yet or is empty.\n'
          'Run the benchmark once on device to generate the dump:\n'
          '  flutter test integration_test/ocr_real_benchmark_test.dart -d <device-id>\n'
          '  adb pull /sdcard/Download/ocr_fixtures/extracted_ocr_documents.json test/fixtures/ocr/real_images_ocr.json',
        );
        return;
      }

      int totalFields = 0;
      int correctFields = 0;

      final fieldStats = <String, int>{
        'storeName': 0,
        'storeName_ok': 0,
        'cnpj': 0,
        'cnpj_ok': 0,
        'purchasedAt': 0,
        'purchasedAt_ok': 0,
        'itemCount': 0,
        'itemCount_ok': 0,
        'total': 0,
        'total_ok': 0,
        'paymentMethod': 0,
        'paymentMethod_ok': 0,
      };

      final divergences = <String>[];
      final itemDivergences = <String>[];

      int totalExpectedItems = 0;
      int totalDetectedItems = 0;
      int totalCorrectItems = 0;
      int totalPriceDiffItems = 0;
      int totalMissingItems = 0;
      int totalSpuriousItems = 0;

      for (final entry in ocrDocuments.entries) {
        final imageId = entry.key;
        final docJson = entry.value as Map<String, dynamic>;
        final doc = OcrDocument.fromJson(docJson);

        final expected = groundTruth[imageId];
        if (expected == null) continue;

        final draft = parser.parse(doc);

        // 1. Store
        fieldStats['storeName'] = fieldStats['storeName']! + 1;
        totalFields++;
        final expStore = expected['storeName'] as String?;
        final actStore = draft.store.name;
        final isStoreOk = expStore == null
            ? actStore == null
            : actStore != null &&
                  actStore.toUpperCase().contains(expStore.toUpperCase());
        if (isStoreOk) {
          fieldStats['storeName_ok'] = fieldStats['storeName_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [loja: esperava "$expStore", obteve "$actStore"]',
          );
        }

        // 2. CNPJ
        fieldStats['cnpj'] = fieldStats['cnpj']! + 1;
        totalFields++;
        final expCnpj = expected['cnpj'] as String?;
        final actCnpj = draft.store.cnpj;
        final isCnpjOk = expCnpj == null
            ? actCnpj == null
            : actCnpj == expCnpj && draft.store.isCnpjValid;
        if (isCnpjOk) {
          fieldStats['cnpj_ok'] = fieldStats['cnpj_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [CNPJ: esperava "$expCnpj", obteve "$actCnpj"]',
          );
        }

        // 3. Data
        fieldStats['purchasedAt'] = fieldStats['purchasedAt']! + 1;
        totalFields++;
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
        if (isDateOk) {
          fieldStats['purchasedAt_ok'] = fieldStats['purchasedAt_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [date: expected $expYear-$expMonth-$expDay, got ${actDate?.toIso8601String()}]',
          );
        }

        // 4. Items (+- 2 tolerance)
        fieldStats['itemCount'] = fieldStats['itemCount']! + 1;
        totalFields++;
        final expItems = expected['itemCount'] as int;
        final actItems = draft.items.length;
        final isItemsOk =
            actItems == expItems ||
            (actItems >= expItems - 2 && actItems <= expItems + 2);
        if (isItemsOk) {
          fieldStats['itemCount_ok'] = fieldStats['itemCount_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [items: expected $expItems, got $actItems]',
          );
        }

        // 5. Total
        fieldStats['total'] = fieldStats['total']! + 1;
        totalFields++;
        final expTotal = expected['total'] as int?;
        final actTotal = draft.total?.cents;
        final isTotalOk = expTotal == null
            ? actTotal == null
            : actTotal == expTotal;
        if (isTotalOk) {
          fieldStats['total_ok'] = fieldStats['total_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [total: expected $expTotal cents, got $actTotal]',
          );
        }

        // 6. Pagamento
        fieldStats['paymentMethod'] = fieldStats['paymentMethod']! + 1;
        totalFields++;
        final expPay = expected['paymentMethod'] as String?;
        final actPay = draft.paymentMethod;
        final isPayOk = expPay == null ? true : actPay == expPay;
        if (isPayOk) {
          fieldStats['paymentMethod_ok'] = fieldStats['paymentMethod_ok']! + 1;
          correctFields++;
        } else {
          divergences.add(
            '$imageId [payment: expected "$expPay", got "$actPay"]',
          );
        }

        // 7. Item-by-item evaluation (Precision of each item and price)
        final expectedItemsList = (expected['items'] as List<dynamic>?) ?? [];
        totalExpectedItems += expectedItemsList.length;
        totalDetectedItems += draft.items.length;

        final unmatchedExpected = List<Map<String, dynamic>>.from(
          expectedItemsList.map((e) => e as Map<String, dynamic>),
        );

        for (final actItem in draft.items) {
          final actDesc = actItem.rawDescription.toUpperCase();
          final actCents = actItem.totalPrice.cents;

          int bestMatchIndex = -1;
          double bestScore = 0.0;

          for (int i = 0; i < unmatchedExpected.length; i++) {
            final exp = unmatchedExpected[i];
            final expDesc = (exp['description'] as String).toUpperCase();
            final score = similarity(actDesc, expDesc);
            if (score > bestScore) {
              bestScore = score;
              bestMatchIndex = i;
            }
          }

          if (bestScore >= 0.45 && bestMatchIndex >= 0) {
            final matchedExp = unmatchedExpected.removeAt(bestMatchIndex);
            final expCents = matchedExp['total'] as int;
            final isPriceMatch = (actCents - expCents).abs() <= 2;

            if (isPriceMatch) {
              totalCorrectItems++;
            } else {
              totalPriceDiffItems++;
              itemDivergences.add(
                '$imageId [preço item]: "${actItem.rawDescription}" obteve $actCents centavos, esperava $expCents centavos',
              );
            }
          } else {
            totalSpuriousItems++;
          }
        }

        totalMissingItems += unmatchedExpected.length;
        for (final missing in unmatchedExpected) {
          itemDivergences.add(
            '$imageId [item não detectado]: "${missing['description']}" (${missing['total']} centavos)',
          );
        }
      }

      final rate = totalFields > 0
          ? (correctFields / totalFields) * 100.0
          : 0.0;

      final itemRecall = totalExpectedItems > 0
          ? (totalCorrectItems / totalExpectedItems) * 100.0
          : 0.0;
      final itemPrecision = totalDetectedItems > 0
          ? (totalCorrectItems / totalDetectedItems) * 100.0
          : 0.0;
      final itemF1 = (itemRecall + itemPrecision) > 0
          ? (2 * itemRecall * itemPrecision) / (itemRecall + itemPrecision)
          : 0.0;

      if (Platform.environment['VERBOSE_OCR_BENCHMARK'] == '1') {
        print('\n======================================================');
        print('--- BENCHMARK OFFLINE DE PRECISÃO (SEM IA / SEM CELULAR) ---');
        print('======================================================');
        print('Cupons avaliados:       ${ocrDocuments.length}');
        print(
          'Campos globais corretos: $correctFields/$totalFields (${rate.toStringAsFixed(1)}%)',
        );
        print('------------------------------------------------------');
        print('METRICAS DE ITENS E PRECOS:');
        print('  Total Itens Reais (Ground Truth) : $totalExpectedItems');
        print('  Total Itens Lidos pelo Parser    : $totalDetectedItems');
        print('  Itens Perfeitos (Nome + Preço)   : $totalCorrectItems');
        print('  Itens com Preço Divergente       : $totalPriceDiffItems');
        print('  Itens Não Detectados (Faltantes) : $totalMissingItems');
        print('  Itens Espúrios (Falso Positivo)  : $totalSpuriousItems');
        print('  ----------------------------------------------------');
        print(
          '  ITEM RECALL   (itens capturados) : ${itemRecall.toStringAsFixed(1)}%',
        );
        print(
          '  ITEM PRECISION (acerto do lido)  : ${itemPrecision.toStringAsFixed(1)}%',
        );
        print(
          '  ITEM F1-SCORE                    : ${itemF1.toStringAsFixed(1)}%',
        );
        print('------------------------------------------------------');
        print('Acurácia por Campo de Cabeçalho/Totais:');
        for (final key in [
          'storeName',
          'cnpj',
          'purchasedAt',
          'itemCount',
          'total',
          'paymentMethod',
        ]) {
          final total = fieldStats[key]!;
          final ok = fieldStats['${key}_ok']!;
          final p = total > 0 ? (ok / total) * 100.0 : 0.0;
          print(
            '  - ${key.padRight(15)}: $ok/$total (${p.toStringAsFixed(1)}%)',
          );
        }
        print('------------------------------------------------------');
        if (itemDivergences.isNotEmpty) {
          print('Divergências de Itens (primeiras 10):');
          for (final idiv in itemDivergences.take(10)) {
            print('  * $idiv');
          }
          if (itemDivergences.length > 10) {
            print(
              '  ... e mais ${itemDivergences.length - 10} divergências de itens.',
            );
          }
        }
        print('======================================================\n');
      }
    });
  });
}
