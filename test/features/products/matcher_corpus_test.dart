// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/features/products/domain/default_product_matcher.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

void main() {
  group('Corpus de Teste de Matcher (T-05)', () {
    late ProductIndex index;
    late DefaultProductMatcher matcher;
    late List<Map<String, dynamic>> corpus;

    setUpAll(() {
      matcher = DefaultProductMatcher();

      // Carrega os sinonimos (seed)
      final seedFile = File('assets/seed/synonyms.json');
      final seedJson =
          jsonDecode(seedFile.readAsStringSync()) as Map<String, dynamic>;
      final productsData = (seedJson['products'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final products = <Product>[];
      final aliases = <ProductAlias>[];

      int pIdCounter = 1;
      int aIdCounter = 1;

      for (final p in productsData) {
        final canonicalName = p['canonicalName'] as String;
        final categoryId = p['categoryId'] as String;
        final defaultUnitStr = p['defaultUnit'] as String;
        final pAliases = List<String>.from(
          (p['aliases'] as List<dynamic>?) ?? [],
        );

        final unit = Unit.values.firstWhere(
          (u) => u.name == defaultUnitStr,
          orElse: () => Unit.un,
        );

        final pId = 'p$pIdCounter';
        pIdCounter++;

        final product = Product(
          id: pId,
          canonicalName: canonicalName,
          categoryId: categoryId,
          defaultUnit: unit,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        products.add(product);

        // Adiciona o canonical name como alias
        aliases.add(
          ProductAlias(
            id: 'a$aIdCounter',
            productId: pId,
            alias: canonicalName,
            normalizedAlias: normalizeProductName(canonicalName),
            source: AliasSource.seed,
            createdAt: DateTime.now(),
          ),
        );
        aIdCounter++;

        // Adiciona os outros aliases
        for (final aliasText in pAliases) {
          aliases.add(
            ProductAlias(
              id: 'a$aIdCounter',
              productId: pId,
              alias: aliasText,
              normalizedAlias: normalizeProductName(aliasText),
              source: AliasSource.seed,
              createdAt: DateTime.now(),
            ),
          );
          aIdCounter++;
        }
      }

      index = ProductIndex.from(products, aliases, []);

      // Carrega o corpus gerado
      final corpusFile = File('test/fixtures/matching/corpus.json');
      final corpusJson =
          jsonDecode(corpusFile.readAsStringSync()) as List<dynamic>;
      corpus = corpusJson.cast<Map<String, dynamic>>();
    });

    test('Must achieve at least 85% accuracy on corpus', () {
      int successCount = 0;
      final failures = <String>[];

      for (final item in corpus) {
        final raw = item['raw'] as String;
        final expected = item['expected'] as String;

        final result = matcher.match(raw, index);

        bool success = false;
        String? matchedName;

        if (result is SingleMatch) {
          matchedName = result.match.product.canonicalName;
          if (matchedName == expected) {
            success = true;
          }
        } else if (result is AmbiguousMatch) {
          final candidateNames = result.candidates
              .map((c) => c.product.canonicalName)
              .toList();
          matchedName = 'Ambiguous: ${candidateNames.join(', ')}';
          if (candidateNames.contains(expected)) {
            success = true;
          }
        } else if (result is NoMatch) {
          matchedName = 'NoMatch';
        }

        if (success) {
          successCount++;
        } else {
          failures.add(
            'Falha em "$raw" -> Esperado: "$expected", Obtido: "$matchedName"',
          );
        }
      }

      final total = corpus.length;
      final successRate = successCount / total;

      print('--- Resultado do Corpus (T-05) ---');
      print('Total de Casos: $total');
      print('Acertos: $successCount');
      print('Erros: ${failures.length}');
      print('Taxa de Acerto: ${(successRate * 100).toStringAsFixed(2)}%');

      if (failures.isNotEmpty) {
        print('\n--- Casos Conhecidos (Falhas) ---');
        for (final f in failures) {
          print(f);
        }
      }

      expect(
        successRate,
        greaterThanOrEqualTo(0.85),
        reason: 'A taxa de acerto do matcher no corpus deve ser >= 85%',
      );
    });
  });
}
