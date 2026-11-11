// Testes de normalizeProductName — cobertura ≥ 95% (SPEC-001, 004-testing.md §2)
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';

void main() {
  group('normalizeProductName — casos base', () {
    test('LEITE INTEGRAL 1L → leite integral', () {
      expect(normalizeProductName('LEITE INTEGRAL 1L'), 'leite integral');
    });

    test('PAO DE SAL → pao sal', () {
      expect(normalizeProductName('PAO DE SAL'), 'pao sal');
    });

    test('Arroz Tipo 1 5KG → arroz tipo 1', () {
      expect(normalizeProductName('Arroz Tipo 1 5KG'), 'arroz tipo 1');
    });

    test('FEIJAO PRETO -> feijao preto (removes accent)', () {
      expect(normalizeProductName('FEIJÃO PRETO'), 'feijao preto');
    });

    test('Oleo de Soja 900ML -> oleo soja', () {
      expect(normalizeProductName('Óleo de Soja 900ML'), 'oleo soja');
    });

    test('MACARRAO 500G ESPAGUETE → macarrao espaguete', () {
      expect(
        normalizeProductName('MACARRAO 500G ESPAGUETE'),
        'macarrao espaguete',
      );
    });

    test('Cafe com Leite 200g -> cafe leite', () {
      expect(normalizeProductName('Café com Leite 200g'), 'cafe leite');
    });

    test('AGUA MINERAL 1.5L → agua mineral', () {
      expect(normalizeProductName('AGUA MINERAL 1.5L'), 'agua mineral');
    });

    test('Nescau 2.0 400g → nescau 2.0', () {
      expect(normalizeProductName('Nescau 2.0 400g'), 'nescau 2.0');
    });
  });

  group('normalizeProductName — empty strings and whitespace', () {
    test('string vazia → string vazia', () {
      expect(normalizeProductName(''), '');
    });

    test('only whitespace -> empty string', () {
      expect(normalizeProductName('   '), '');
    });
  });

  group('normalizeProductName — erros de OCR e casos especiais', () {
    test('PA0 DE SAL (zero instead of O) -> pa0 sal (best effort)', () {
      // "0" is digit, not letter, but not stopword -> kept
      final result = normalizeProductName('PA0 DE SAL');
      expect(result, isNot(contains('de')));
      expect(result, contains('sal'));
    });

    test('12X1L AGUA → agua (remove pack multiplier + unidade)', () {
      // 12X1L is quantity x unit pattern -> removed; 'agua' remains
      final result = normalizeProductName('12X1L AGUA');
      expect(result, contains('agua'));
      expect(result, isNot(contains('12x1l')));
    });
  });

  group('normalizeProductName — stopwords', () {
    test('removes Portuguese prepositions and articles: de, da, do', () {
      expect(
        normalizeProductName('Molho de Tomate da Vovó'),
        isNot(contains(' de ')),
      );
      expect(
        normalizeProductName('Molho de Tomate da Vovó'),
        isNot(contains(' da ')),
      );
    });

    test('removes common stopword prepositions', () {
      final result = normalizeProductName(
        'Suco para Crianças com Vitaminas em Pó',
      );
      expect(result, isNot(contains(' para ')));
      expect(result, isNot(contains(' com ')));
      expect(result, isNot(contains(' em ')));
    });

    test('remove unidades como stopwords: kg, g, ml, l, lt', () {
      // Standalone units (without number) are removed as stopwords
      expect(normalizeProductName('Farinha kg'), isNot(contains('kg')));
    });

    test('remove embalagem: caixa, pacote, unid', () {
      final result = normalizeProductName('Biscoito Caixa Grande');
      expect(result, isNot(contains('caixa')));
    });
  });

  group('normalizeProductName — acentos', () {
    test('á → a', () => expect(normalizeProductName('Pão'), contains('pao')));
    test('é → e', () => expect(normalizeProductName('Café'), contains('cafe')));
    test(
      'ç → c',
      () => expect(normalizeProductName('Almoço'), contains('almoco')),
    );
    test('ã → a', () => expect(normalizeProductName('Maçã'), contains('maca')));
    test(
      'ê → e',
      () => expect(
        normalizeProductName('Frango Assado Rêgio'),
        contains('regio'),
      ),
    );
    test(
      'ú → u',
      () => expect(normalizeProductName('Açúcar'), contains('acucar')),
    );
    test(
      'ô → o',
      () => expect(normalizeProductName('Arroz Côco'), contains('coco')),
    );
    test('í → i', () => expect(normalizeProductName('Açaí'), contains('acai')));
    test('ó → o', () => expect(normalizeProductName('Óleo'), contains('oleo')));
  });

  group('normalizeProductName — multiple spaces', () {
    test('collapses multiple spaces', () {
      final result = normalizeProductName('LEITE   INTEGRAL');
      expect(result, 'leite integral');
    });

    test('trim nas bordas', () {
      final result = normalizeProductName('  leite  ');
      expect(result, 'leite');
    });

    test('corrige digitos comuns de OCR em palavras curtas e longas', () {
      expect(normalizeProductName('molho d0 tomate'), 'molho tomate');
      expect(normalizeProductName('cafe a0 leite'), 'cafe ao leite');
      expect(normalizeProductName('pao n0 forno'), 'pao no forno');
      expect(normalizeProductName('arr0z sa8ao'), 'arroz sabao');
    });
  });

  group('normalizeProductName — unidades variadas', () {
    test('remove 500G no meio', () {
      expect(
        normalizeProductName('MACARRAO 500G ESPAGUETE'),
        'macarrao espaguete',
      );
    });

    test('remove 1KG', () {
      expect(normalizeProductName('Arroz 1KG Branco'), 'arroz branco');
    });

    test('remove 200ML', () {
      expect(normalizeProductName('Suco 200ML Laranja'), 'suco laranja');
    });

    test('remove 1.5L', () {
      expect(normalizeProductName('AGUA MINERAL 1.5L'), 'agua mineral');
    });
  });
}
