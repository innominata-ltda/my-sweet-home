// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/core/text/similarity.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/ml_kit_text_recognizer_adapter.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';
import 'package:path_provider/path_provider.dart';

class OcrBenchmarkPage extends StatefulWidget {
  const OcrBenchmarkPage({super.key});

  @override
  State<OcrBenchmarkPage> createState() => _OcrBenchmarkPageState();
}

class _OcrBenchmarkPageState extends State<OcrBenchmarkPage> {
  bool _isRunning = false;
  double _progress = 0.0;
  String _currentStatus = '';
  Map<String, dynamic>? _results;

  late final Map<String, Map<String, dynamic>> _groundTruth;

  @override
  void initState() {
    super.initState();
    _groundTruth = _loadGroundTruth();
  }

  Map<String, Map<String, dynamic>> _loadGroundTruth() {
    final map = <String, Map<String, dynamic>>{};
    final candidateFiles = [
      File('/sdcard/Download/ocr_fixtures/images_ground_truth.json'),
      File(
        '/sdcard/Android/data/br.com.innominata.mysweethome/files/ocr_fixtures/images_ground_truth.json',
      ),
    ];

    String? jsonContent;
    for (final file in candidateFiles) {
      try {
        if (file.existsSync()) {
          jsonContent = file.readAsStringSync();
          break;
        }
      } catch (_) {}
    }
    jsonContent ??= _embeddedGroundTruthJson;

    try {
      final list = jsonDecode(jsonContent) as List<dynamic>;
      for (final item in list) {
        final entry = item as Map<String, dynamic>;
        map[entry['id'] as String] = entry['expected'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return map;
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _currentStatus = 'Localizando imagens de teste no dispositivo...';
      _results = null;
    });

    final candidateDirs = <Directory>[];
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        candidateDirs.add(Directory('${extDir.path}/ocr_fixtures/images'));
      }
    } catch (_) {}

    candidateDirs.addAll([
      Directory('/sdcard/Download/ocr_fixtures/images'),
      Directory('/sdcard/Download/ocr_fixtures'),
      Directory(
        '/sdcard/Android/data/br.com.innominata.mysweethome/files/ocr_fixtures/images',
      ),
    ]);

    List<File> imageFiles = [];
    for (final dir in candidateDirs) {
      try {
        if (dir.existsSync()) {
          final list = dir
              .listSync()
              .whereType<File>()
              .where(
                (f) =>
                    f.path.toLowerCase().endsWith('.jpg') ||
                    f.path.toLowerCase().endsWith('.jpeg'),
              )
              .toList();
          if (list.isNotEmpty) {
            imageFiles = list;
            break;
          }
        }
      } catch (_) {}
    }

    if (imageFiles.isEmpty) {
      setState(() {
        _isRunning = false;
        _currentStatus =
            'Nenhuma foto encontrada em /sdcard/Download/ocr_fixtures/images.\n'
            'Envie as imagens pelo ADB para iniciar o benchmark.';
      });
      return;
    }

    imageFiles.sort((a, b) => a.path.compareTo(b.path));

    final adapter = MlKitTextRecognizerAdapter();
    const parser = DefaultReceiptParser();
    final allExtractedDocs = <String, dynamic>{};

    int totalFields = 0;
    int correctFields = 0;

    final fieldAccuracies = <String, _FieldStats>{
      'storeName': _FieldStats('Loja / Razão Social'),
      'cnpj': _FieldStats('CNPJ'),
      'purchasedAt': _FieldStats('Data da Compra'),
      'itemCount': _FieldStats('Qtd Itens (+-2)'),
      'total': _FieldStats('Valor Total'),
      'paymentMethod': _FieldStats('Forma de Pagto'),
    };

    int totalExpectedItems = 0;
    int totalDetectedItems = 0;
    int totalCorrectItems = 0;
    int totalPriceDiffItems = 0;
    int totalMissingItems = 0;
    int totalSpuriousItems = 0;

    final receiptResults = <_ReceiptBenchmarkEntry>[];
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final filename = file.uri.pathSegments.last;

      setState(() {
        _progress = (i + 1) / imageFiles.length;
        _currentStatus = 'Processando ${i + 1}/${imageFiles.length}: $filename';
      });

      final docResult = await adapter.recognizeFile(file.path);
      if (docResult.isErr) continue;

      final doc = docResult.valueOrNull!;
      allExtractedDocs[filename] = doc.toJson();

      final draft = parser.parse(doc);
      final expected = _groundTruth[filename];

      bool isNameOk = false;
      bool isCnpjOk = false;
      bool isDateOk = false;
      bool isItemsOk = false;
      bool isTotalOk = false;
      bool isPayOk = false;
      int receiptExpItems = 0;
      int receiptCorrectItems = 0;

      if (expected != null) {
        // 1. Store
        final expName = expected['storeName'] as String?;
        final actName = draft.store.name;
        isNameOk = expName == null
            ? actName == null
            : actName != null &&
                  actName.toUpperCase().contains(expName.toUpperCase());
        fieldAccuracies['storeName']!.record(isNameOk);
        totalFields++;
        if (isNameOk) correctFields++;

        // 2. CNPJ
        final expCnpj = expected['cnpj'] as String?;
        final actCnpj = draft.store.cnpj;
        isCnpjOk = expCnpj == null
            ? actCnpj == null
            : actCnpj == expCnpj && draft.store.isCnpjValid;
        fieldAccuracies['cnpj']!.record(isCnpjOk);
        totalFields++;
        if (isCnpjOk) correctFields++;

        // 3. Data
        final expYear = expected['year'] as int?;
        final expMonth = expected['month'] as int?;
        final expDay = expected['day'] as int?;
        final actDate = draft.purchasedAt;
        isDateOk = expYear == null
            ? actDate == null
            : actDate != null &&
                  actDate.year == expYear &&
                  actDate.month == expMonth &&
                  actDate.day == expDay;
        fieldAccuracies['purchasedAt']!.record(isDateOk);
        totalFields++;
        if (isDateOk) correctFields++;

        // 4. Items (tolerance +-2)
        final expItems = expected['itemCount'] as int;
        final actItems = draft.items.length;
        isItemsOk =
            actItems == expItems ||
            (actItems >= expItems - 2 && actItems <= expItems + 2);
        fieldAccuracies['itemCount']!.record(isItemsOk);
        totalFields++;
        if (isItemsOk) correctFields++;

        // 5. Total
        final expTotal = expected['total'] as int?;
        final actTotal = draft.total?.cents;
        isTotalOk = expTotal == null ? actTotal == null : actTotal == expTotal;
        fieldAccuracies['total']!.record(isTotalOk);
        totalFields++;
        if (isTotalOk) correctFields++;

        // 6. Pagamento
        final expPay = expected['paymentMethod'] as String?;
        final actPay = draft.paymentMethod;
        isPayOk = expPay == null ? true : actPay == expPay;
        fieldAccuracies['paymentMethod']!.record(isPayOk);
        totalFields++;
        if (isPayOk) correctFields++;

        // 7. ITEM BY ITEM evaluation (Precision of each item and price)
        final expectedItemsList = (expected['items'] as List<dynamic>?) ?? [];
        receiptExpItems = expectedItemsList.length;
        totalExpectedItems += receiptExpItems;
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
              receiptCorrectItems++;
            } else {
              totalPriceDiffItems++;
            }
          } else {
            totalSpuriousItems++;
          }
        }

        totalMissingItems += unmatchedExpected.length;
      }

      receiptResults.add(
        _ReceiptBenchmarkEntry(
          filename: filename,
          storeName: draft.store.name,
          total: draft.total?.formatPtBr(),
          isAllOk:
              isNameOk &&
              isCnpjOk &&
              isDateOk &&
              isItemsOk &&
              isTotalOk &&
              isPayOk,
          itemsSummary: receiptExpItems > 0
              ? '$receiptCorrectItems/$receiptExpItems itens corretos'
              : '${draft.items.length} itens detectados',
        ),
      );
    }

    stopwatch.stop();

    // Save dump for export and offline use
    try {
      final dumpFile = File(
        '/sdcard/Download/ocr_fixtures/real_images_ocr.json',
      );
      dumpFile.writeAsStringSync(jsonEncode(allExtractedDocs));
    } catch (_) {}

    final itemRecall = totalExpectedItems > 0
        ? (totalCorrectItems / totalExpectedItems) * 100.0
        : 0.0;
    final itemPrecision = totalDetectedItems > 0
        ? (totalCorrectItems / totalDetectedItems) * 100.0
        : 0.0;
    final itemF1 = (itemRecall + itemPrecision) > 0
        ? (2 * itemRecall * itemPrecision) / (itemRecall + itemPrecision)
        : 0.0;

    setState(() {
      _isRunning = false;
      _currentStatus =
          'Benchmark concluído em ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';
      _results = {
        'totalImages': imageFiles.length,
        'totalTimeMs': stopwatch.elapsedMilliseconds,
        'avgTimeMs': (stopwatch.elapsedMilliseconds / imageFiles.length)
            .round(),
        'overallAccuracy': totalFields > 0
            ? (correctFields / totalFields) * 100.0
            : 0.0,
        'fieldAccuracies': fieldAccuracies,
        'receipts': receiptResults,
        'itemMetrics': {
          'expected': totalExpectedItems,
          'detected': totalDetectedItems,
          'correct': totalCorrectItems,
          'priceDiff': totalPriceDiffItems,
          'missing': totalMissingItems,
          'spurious': totalSpuriousItems,
          'recall': itemRecall,
          'precision': itemPrecision,
          'f1': itemF1,
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benchmark de Precisão OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.priceHistory, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Validação de Precisão do ML Kit',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Executa o motor nativo do Google ML Kit em fotos reais de cupons fiscais brasileiros '
                      'e compara os campos extraídos contra o ground truth mapeado manualmente (sem necessidade de IA).',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ground Truth: ${_groundTruth.length} cupons fiscais pré-mapeados.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isRunning) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                _currentStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(AppIcons.play),
                label: const Text('Executar Benchmark Completo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _runBenchmark,
              ),
              if (_currentStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _currentStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
            if (_results != null) ...[
              const SizedBox(height: 24),
              _buildMetricsSummary(context),
              const SizedBox(height: 16),
              _buildItemAccuracyCard(context),
              const SizedBox(height: 16),
              _buildFieldBreakdown(context),
              const SizedBox(height: 16),
              _buildReceiptsList(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSummary(BuildContext context) {
    final accuracy = _results!['overallAccuracy'] as double;
    final totalImages = _results!['totalImages'] as int;
    final avgTime = _results!['avgTimeMs'] as int;

    final isGreat = accuracy >= 85.0;

    return Card(
      color: isGreat ? Colors.green.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: isGreat ? Colors.green.shade800 : Colors.amber.shade900,
              ),
            ),
            const Text(
              'Taxa Global de Precisão',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Fotos', '$totalImages'),
                _buildMiniStat('Média/Foto', '${avgTime}ms'),
                _buildMiniStat(
                  'Status',
                  isGreat ? 'Aprovado (>=85%)' : 'Abaixo da meta',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildFieldBreakdown(BuildContext context) {
    final fields = _results!['fieldAccuracies'] as Map<String, _FieldStats>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acurácia por Campo',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...fields.values.map((f) {
              final pct = f.percentage;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f.label, style: const TextStyle(fontSize: 13)),
                        Text(
                          '${f.correct}/${f.total} (${pct.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: pct >= 85
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: f.total > 0 ? f.correct / f.total : 0.0,
                      backgroundColor: Colors.grey.shade200,
                      color: pct >= 85 ? Colors.green : Colors.amber.shade700,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemAccuracyCard(BuildContext context) {
    final itemMetrics = _results!['itemMetrics'] as Map<String, dynamic>? ?? {};
    final expected = itemMetrics['expected'] as int? ?? 0;
    final detected = itemMetrics['detected'] as int? ?? 0;
    final correct = itemMetrics['correct'] as int? ?? 0;
    final priceDiff = itemMetrics['priceDiff'] as int? ?? 0;
    final missing = itemMetrics['missing'] as int? ?? 0;
    final spurious = itemMetrics['spurious'] as int? ?? 0;

    final recall = itemMetrics['recall'] as double? ?? 0.0;
    final precision = itemMetrics['precision'] as double? ?? 0.0;
    final f1 = itemMetrics['f1'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Acurácia Item a Item (Itens & Preços)',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'F1: ${f1.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: f1 >= 75
                        ? Colors.green.shade700
                        : Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Mede a taxa de captura de cada produto individual da nota e conferência do preço exato em centavos.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  'Recall (Captura)',
                  '${recall.toStringAsFixed(1)}%',
                ),
                _buildMiniStat('Precisão', '${precision.toStringAsFixed(1)}%'),
                _buildMiniStat('F1-Score', '${f1.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  backgroundColor: Colors.blue.shade50,
                  label: Text(
                    'Esperados: $expected',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.indigo.shade50,
                  label: Text(
                    'Detectados: $detected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.green.shade50,
                  label: Text(
                    'Perfeitos (Nome+Preço): $correct',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.amber.shade50,
                  label: Text(
                    'Preço Divergente: $priceDiff',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.red.shade50,
                  label: Text(
                    'Não Detectados: $missing',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(
                    'Falso Positivo: $spurious',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList(BuildContext context) {
    final receipts = _results!['receipts'] as List<_ReceiptBenchmarkEntry>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cupons Analisados (${receipts.length})',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...receipts.map((r) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                r.isAllOk ? AppIcons.check : AppIcons.warning,
                color: r.isAllOk ? Colors.green : Colors.amber.shade800,
              ),
              title: Text(
                r.filename,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                'Loja: ${r.storeName ?? 'Não id.'} • Total: ${r.total ?? 'Não id.'}\n${r.itemsSummary}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ReceiptBenchmarkEntry {
  final String filename;
  final String? storeName;
  final String? total;
  final bool isAllOk;
  final String itemsSummary;

  const _ReceiptBenchmarkEntry({
    required this.filename,
    required this.storeName,
    required this.total,
    required this.isAllOk,
    required this.itemsSummary,
  });
}

class _FieldStats {
  final String label;
  int total = 0;
  int correct = 0;

  _FieldStats(this.label);

  void record(bool isOk) {
    total++;
    if (isOk) correct++;
  }

  double get percentage => total > 0 ? (correct / total) * 100.0 : 0.0;
}

const _embeddedGroundTruthJson = r'''
[
  {"id":"20261003_203526.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":10,"day":1,"itemCount":18,"total":25115,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203537.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":24,"itemCount":18,"total":23993,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203543.jpg","expected":{"storeName":"CIA BRASILEIRA DE DISTRIBUICAO","cnpj":"47508411114402","year":2026,"month":9,"day":24,"itemCount":7,"total":15039,"paymentMethod":null}},
  {"id":"20261003_203548.jpg","expected":{"storeName":"KALUNGA","cnpj":"43283811019764","year":2026,"month":9,"day":12,"itemCount":3,"total":17780,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203555.jpg","expected":{"storeName":"RAIADROGASIL","cnpj":"61585865239375","year":2026,"month":9,"day":16,"itemCount":5,"total":12360,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203610.jpg","expected":{"storeName":"MERCADINHO SEMPRE MAIS","cnpj":"12472401000123","year":2026,"month":10,"day":2,"itemCount":1,"total":659,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203618.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":27,"itemCount":17,"total":22771,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203624.jpg","expected":{"storeName":"iFood","cnpj":null,"year":2026,"month":9,"day":26,"itemCount":6,"total":9408,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203632.jpg","expected":{"storeName":"PANIFICADORA SAO JORGE","cnpj":"40712488000102","year":2026,"month":9,"day":26,"itemCount":6,"total":5329,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203655.jpg","expected":{"storeName":"KALUNGA","cnpj":"43283811019764","year":2026,"month":9,"day":19,"itemCount":2,"total":4190,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203701.jpg","expected":{"storeName":"DROGARIA DROGAVISTA","cnpj":"00958548006260","year":2026,"month":9,"day":20,"itemCount":5,"total":16563,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203707.jpg","expected":{"storeName":"RAIADROGASIL","cnpj":"61585865239375","year":2026,"month":9,"day":21,"itemCount":3,"total":21238,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203717.jpg","expected":{"storeName":"Bacio di Latte","cnpj":"11950487021430","year":2026,"month":9,"day":26,"itemCount":1,"total":5190,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203726.jpg","expected":{"storeName":"CIA BRASILEIRA DE DISTRIBUICAO","cnpj":"47508411114402","year":2026,"month":9,"day":30,"itemCount":20,"total":33790,"paymentMethod":null}},
  {"id":"20261003_203733.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":29,"itemCount":15,"total":17577,"paymentMethod":"CARTÃO DE CRÉDITO"}},
  {"id":"20261003_203739.jpg","expected":{"storeName":"ZAMP","cnpj":"13574594133820","year":2026,"month":9,"day":27,"itemCount":9,"total":17147,"paymentMethod":null}},
  {"id":"20261003_203757.jpg","expected":{"storeName":"COMERCIAL DE ALIMENTOS PEREIRA","cnpj":"03109785000123","year":2026,"month":9,"day":27,"itemCount":1,"total":824,"paymentMethod":"DINHEIRO"}},
  {"id":"20261003_204710.jpg","expected":{"storeName":"DROGARIA DROGAVISTA","cnpj":"00958548001463","year":2026,"month":9,"day":12,"itemCount":1,"total":799,"paymentMethod":"CARTÃO DE CRÉDITO"}}
]
''';
