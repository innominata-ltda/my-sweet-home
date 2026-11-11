// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/core/text/similarity.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/ml_kit_text_recognizer_adapter.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Benchmark de OCR e Parser com fotos reais em dispositivo físico', (
    tester,
  ) async {
    Directory? imagesDir;
    final candidateDirs = <Directory>[];

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        candidateDirs.add(Directory('${extDir.path}/ocr_fixtures/images'));
      }
    } catch (_) {}

    candidateDirs.addAll([
      Directory('/sdcard/Download/ocr_fixtures/images'),
      Directory(
        '/sdcard/Android/data/br.com.innominata.mysweethome/files/ocr_fixtures/images',
      ),
      Directory(
        '/sdcard/Android/data/br.com.innominata.mysweethome.test/files/ocr_fixtures/images',
      ),
    ]);

    for (final dir in candidateDirs) {
      try {
        print('Checando diretório candidato: ${dir.path}');
        if (dir.existsSync()) {
          final files = dir.listSync().whereType<File>().toList();
          print('  -> Encontrados ${files.length} arquivos');
          if (files.isNotEmpty) {
            imagesDir = dir;
            break;
          }
        } else {
          print('  -> Diretório não existe');
        }
      } catch (e) {
        print('  -> Erro ao acessar: $e');
      }
    }

    expect(
      imagesDir,
      isNotNull,
      reason: 'Diretório de fixtures com imagens deve existir no dispositivo.',
    );

    final groundTruth = <String, Map<String, dynamic>>{};
    for (final parent in [
      imagesDir!.parent,
      Directory(
        '/sdcard/Android/data/br.com.innominata.mysweethome/files/ocr_fixtures',
      ),
      Directory('/sdcard/Download/ocr_fixtures'),
    ]) {
      final f = File('${parent.path}/images_ground_truth.json');
      if (f.existsSync()) {
        try {
          final list = jsonDecode(f.readAsStringSync()) as List;
          for (final item in list) {
            final map = item as Map<String, dynamic>;
            groundTruth[map['id'] as String] =
                map['expected'] as Map<String, dynamic>;
          }
          break;
        } catch (_) {}
      }
    }

    if (groundTruth.isEmpty) {
      // Embedded fallback with ground truth data
      final fallbackList = jsonDecode(_fallbackGroundTruthJson) as List;
      for (final item in fallbackList) {
        final map = item as Map<String, dynamic>;
        groundTruth[map['id'] as String] =
            map['expected'] as Map<String, dynamic>;
      }
    }

    final imageFiles =
        imagesDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.jpg'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    print('\n========================================================');
    print('  INICIANDO BENCHMARK DE OCR (ML KIT NO HARDWARE REAL)  ');
    print('  Dispositivo: Android');
    print('  Total de Imagens: ${imageFiles.length}');
    print('========================================================\n');

    final adapter = MlKitTextRecognizerAdapter();
    const parser = DefaultReceiptParser();

    final allExtractedDocs = <String, dynamic>{};

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

    final details = <String>[];
    final itemDetails = <String>[];

    int totalExpectedItems = 0;
    int totalDetectedItems = 0;
    int totalCorrectItems = 0;
    int totalPriceDiffItems = 0;
    int totalMissingItems = 0;
    int totalSpuriousItems = 0;

    final stopwatch = Stopwatch()..start();

    for (final file in imageFiles) {
      final filename = file.uri.pathSegments.last;
      print(
        '>> Reconhecendo imagem: $filename (${file.lengthSync()} bytes)...',
      );

      final imgStopwatch = Stopwatch()..start();
      final ocrResult = await adapter.recognizeFile(file.path);
      imgStopwatch.stop();

      if (ocrResult.isErr) {
        print(
          '   [ERRO OCR] Falha ao processar $filename: ${ocrResult.failureOrNull?.message}',
        );
        continue;
      }

      final doc = ocrResult.valueOrNull!;
      allExtractedDocs[filename] = doc.toJson();

      final draft = parser.parse(doc);
      print(
        '   OCR concluído em ${imgStopwatch.elapsedMilliseconds} ms | ${doc.lines.length} linhas reconhecidas',
      );
      print(
        '   Parser -> Loja: "${draft.store.name}" | CNPJ: "${draft.store.cnpj}" | Data: ${draft.purchasedAt} | Itens: ${draft.items.length} | Total: ${draft.total?.cents} centavos | Pagto: "${draft.paymentMethod}"',
      );

      final expected = groundTruth[filename];
      if (expected == null) {
        print('   [AVISO] Sem ground truth cadastrado para $filename');
        continue;
      }

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
        '$filename [loja: esperava "$expName", obteve "$actName"]',
        details,
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
        '$filename [CNPJ: esperava "$expCnpj", obteve "$actCnpj"]',
        details,
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
        '$filename [data: esperava $expYear-$expMonth-$expDay, obteve ${actDate?.toIso8601String()}]',
        details,
      );
      totalFieldsChecked++;
      if (isDateOk) successfulFields++;

      // 4. Item Count (tolerance of +- 2 items due to photographic cropping variations)
      final expItemCount = expected['itemCount'] as int;
      final actItemCount = draft.items.length;
      final isItemCountOk =
          actItemCount == expItemCount ||
          (actItemCount >= expItemCount - 2 &&
              actItemCount <= expItemCount + 2);
      _recordField(
        'itemCount',
        isItemCountOk,
        fieldAccuracies,
        '$filename [itens: esperava $expItemCount, obteve $actItemCount]',
        details,
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
        '$filename [total: esperava $expTotalCents centavos, obteve $actTotalCents]',
        details,
      );
      totalFieldsChecked++;
      if (isTotalOk) successfulFields++;

      // 6. Payment Method
      final expPay = expected['paymentMethod'] as String?;
      final actPay = draft.paymentMethod;
      final isPayOk = expPay == null ? true : actPay == expPay;
      _recordField(
        'paymentMethod',
        isPayOk,
        fieldAccuracies,
        '$filename [pagamento: esperava "$expPay", obteve "$actPay"]',
        details,
      );
      totalFieldsChecked++;
      if (isPayOk) successfulFields++;

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

        for (int j = 0; j < unmatchedExpected.length; j++) {
          final exp = unmatchedExpected[j];
          final expDesc = (exp['description'] as String).toUpperCase();
          final score = similarity(actDesc, expDesc);
          if (score > bestScore) {
            bestScore = score;
            bestMatchIndex = j;
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
            itemDetails.add(
              '$filename [preço item]: "${actItem.rawDescription}" obteve $actCents centavos, esperava $expCents centavos',
            );
          }
        } else {
          totalSpuriousItems++;
        }
      }

      totalMissingItems += unmatchedExpected.length;
      for (final missing in unmatchedExpected) {
        itemDetails.add(
          '$filename [item não detectado]: "${missing['description']}" (${missing['total']} centavos)',
        );
      }
    }

    stopwatch.stop();

    // Salva o dump de documentos OCR reconhecidos no aparelho
    try {
      final outputDump = File(
        '${imagesDir.parent.path}/extracted_ocr_documents.json',
      );
      outputDump.writeAsStringSync(jsonEncode(allExtractedDocs));
      print('\nDump de OcrDocuments salvo em: ${outputDump.path}');
    } catch (e) {
      print('\n[AVISO] Não foi possível salvar dump em arquivo: $e');
    }

    final overallAccuracy = totalFieldsChecked > 0
        ? (successfulFields / totalFieldsChecked) * 100.0
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

    print('\n========================================================');
    print('          RELATÓRIO DO BENCHMARK DE OCR REAL            ');
    print('========================================================');
    print('Tempo Total:             ${stopwatch.elapsedMilliseconds} ms');
    print(
      'Média por Imagem:        ${(stopwatch.elapsedMilliseconds / imageFiles.length).toStringAsFixed(0)} ms',
    );
    print('Total de Imagens:        ${imageFiles.length}');
    print('Total de Campos:         $totalFieldsChecked');
    print('Campos Corretos:         $successfulFields');
    print('Acurácia Geral:          ${overallAccuracy.toStringAsFixed(1)}%');
    print('--------------------------------------------------------');
    print('Acurácia por Campo:');
    fieldAccuracies.forEach((name, stats) {
      print(
        '  - ${name.padRight(16)}: ${stats.correct}/${stats.total} (${stats.percentage.toStringAsFixed(1)}%)',
      );
    });
    print('--------------------------------------------------------');
    print('          ACURÁCIA ITEM A ITEM (PRODUTOS & PREÇOS)      ');
    print('--------------------------------------------------------');
    print('Itens Esperados (Ground Truth):  $totalExpectedItems');
    print('Itens Detectados pelo Parser:    $totalDetectedItems');
    print('Itens Perfeitos (Nome + Preço):  $totalCorrectItems');
    print('Itens com Preço Divergente:      $totalPriceDiffItems');
    print('Itens Não Detectados (Missing):  $totalMissingItems');
    print('Itens Espúrios (Falso Positivo): $totalSpuriousItems');
    print('Item Recall (Taxa de captura):   ${itemRecall.toStringAsFixed(1)}%');
    print(
      'Item Precision (Acurácia lida):  ${itemPrecision.toStringAsFixed(1)}%',
    );
    print('Item F1-Score:                   ${itemF1.toStringAsFixed(1)}%');
    print('--------------------------------------------------------');
    if (details.isNotEmpty) {
      print('Divergências de Cabeçalho/Total:');
      for (final d in details) {
        print('  $d');
      }
    }
    if (itemDetails.isNotEmpty) {
      print('Divergências de Itens:');
      for (final d in itemDetails.take(20)) {
        print('  $d');
      }
      if (itemDetails.length > 20) {
        print('  ... e mais ${itemDetails.length - 20} divergências de itens.');
      }
    }
    print('========================================================\n');

    expect(allExtractedDocs.isNotEmpty, isTrue);
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
  List<String> details,
) {
  final stats = statsMap[fieldName]!;
  stats.total++;
  if (isCorrect) {
    stats.correct++;
  } else {
    details.add('[DIVERGÊNCIA] $failureMsg');
  }
}

const _fallbackGroundTruthJson = r'''
[
  {"id":"20261003_203526.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":10,"day":1,"hour":11,"minute":44,"itemCount":18,"total":25115,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203537.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":24,"hour":12,"minute":42,"itemCount":18,"total":23993,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203543.jpg","expected":{"storeName":"CIA BRASILEIRA DE DISTRIBUICAO","cnpj":"47508411114402","year":2026,"month":9,"day":24,"hour":10,"minute":33,"itemCount":7,"total":15039,"paymentMethod":null}},
  {"id":"20261003_203548.jpg","expected":{"storeName":"KALUNGA","cnpj":"43283811019764","year":2026,"month":9,"day":12,"hour":14,"minute":38,"itemCount":3,"total":17780,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203555.jpg","expected":{"storeName":"RAIADROGASIL","cnpj":"61585865239375","year":2026,"month":9,"day":16,"hour":8,"minute":19,"itemCount":5,"total":12360,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203610.jpg","expected":{"storeName":"MERCADINHO SEMPRE MAIS","cnpj":"12472401000123","year":2026,"month":10,"day":2,"hour":13,"minute":40,"itemCount":1,"total":659,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203618.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":27,"hour":8,"minute":46,"itemCount":17,"total":22771,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203624.jpg","expected":{"storeName":"iFood","cnpj":null,"year":2026,"month":9,"day":26,"hour":17,"minute":45,"itemCount":6,"total":9408,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203632.jpg","expected":{"storeName":"PANIFICADORA SAO JORGE","cnpj":"40712488000102","year":2026,"month":9,"day":26,"hour":17,"minute":1,"itemCount":6,"total":5329,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203655.jpg","expected":{"storeName":"KALUNGA","cnpj":"43283811019764","year":2026,"month":9,"day":19,"hour":20,"minute":26,"itemCount":2,"total":4190,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203701.jpg","expected":{"storeName":"DROGARIA DROGAVISTA","cnpj":"00958548006260","year":2026,"month":9,"day":20,"hour":13,"minute":32,"itemCount":5,"total":16563,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203707.jpg","expected":{"storeName":"RAIADROGASIL","cnpj":"61585865239375","year":2026,"month":9,"day":21,"hour":12,"minute":53,"itemCount":3,"total":21238,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203717.jpg","expected":{"storeName":"Bacio di Latte","cnpj":"11950487021430","year":2026,"month":9,"day":26,"hour":12,"minute":34,"itemCount":1,"total":5190,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203726.jpg","expected":{"storeName":"CIA BRASILEIRA DE DISTRIBUICAO","cnpj":"47508411114402","year":2026,"month":9,"day":30,"hour":9,"minute":56,"itemCount":20,"total":33790,"paymentMethod":null}},
  {"id":"20261003_203733.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":29,"hour":17,"minute":16,"itemCount":15,"total":17577,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203739.jpg","expected":{"storeName":"ZAMP","cnpj":"13574594133820","year":2026,"month":9,"day":27,"hour":19,"minute":13,"itemCount":9,"total":17147,"paymentMethod":null}},
  {"id":"20261003_203757.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":27,"hour":8,"minute":31,"itemCount":1,"total":824,"paymentMethod":"DINHEIRO"}},
  {"id":"20261003_204710.jpg","expected":{"storeName":"DROGARIA DROGAVISTA","cnpj":"00958548001463","year":2026,"month":9,"day":12,"hour":19,"minute":22,"itemCount":1,"total":799,"paymentMethod":"CARTÃO DE CRÉDITO"}}
]
''';
