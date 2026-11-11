import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/totals_parser.dart';

void main() {
  const parser = TotalsParser();

  group('TotalsParser - Totals, discount and payment method extraction (T-07 / RN-193 / CA-2.4)', () {
    group('Isolated Total extraction', () {
      test('extracts TOTAL R\$ 87,40 from plain text', () {
        final result = parser.parseText('TOTAL R\$ 87,40');
        expect(result.total, equals(const Money(8740)));
        expect(result.subtotal, isNull);
        expect(result.discount, isNull);
        expect(result.paymentMethod, isNull);
      });

      test('extracts VALOR A PAGAR R\$ 150,00', () {
        final result = parser.parseText('VALOR A PAGAR: R\$ 150,00');
        expect(result.total, equals(const Money(15000)));
      });

      test('extracts VALOR PAGO R\$ 45,50', () {
        final result = parser.parseText('VALOR PAGO 45,50');
        expect(result.total, equals(const Money(4550)));
      });

      test(
        'extracts total with period decimal separator in OCR noise (87.40)',
        () {
          final result = parser.parseText('TOTAL R\$ 87.40');
          expect(result.total, equals(const Money(8740)));
        },
      );
    });

    group('Joint Subtotal, Discount and Total extraction (CA-2.4)', () {
      test('extracts full receipt with R\$ 3,00 discount and closes with paid amount (CA-2.4 / Carrefour)', () {
        const text = '''
CARREFOUR COMERCIO E INDUSTRIA LTDA
SUBTOTAL R\$ 90,40
DESCONTO R\$ 3,00
TOTAL R\$ 87,40
CARTAO DE DEBITO 87,40
''';
        final result = parser.parseText(text);

        expect(result.subtotal, equals(const Money(9040)));
        expect(result.discount, equals(const Money(300)));
        expect(result.total, equals(const Money(8740)));
        expect(result.paymentMethod, equals('CARTÃO DE DÉBITO'));

        // Verifies that subtotal - discount == total (CA-2.4)
        expect(result.subtotal! - result.discount!, equals(result.total));
      });

      test('extracts negative discount (-3,00) as positive Money (3,00)', () {
        const text = '''
SUBTOTAL: 90,40
DESCONTO: -3,00
VALOR A PAGAR: 87,40
''';
        final result = parser.parseText(text);

        expect(result.subtotal, equals(const Money(9040)));
        expect(result.discount, equals(const Money(300)));
        expect(result.total, equals(const Money(8740)));
      });

      test('extracts discount with trailing minus suffix (3,00-)', () {
        const text = '''
SUBTOTAL 100,00
DESC. 10,00-
TOTAL 90,00
''';
        final result = parser.parseText(text);

        expect(result.subtotal, equals(const Money(10000)));
        expect(result.discount, equals(const Money(1000)));
        expect(result.total, equals(const Money(9000)));
      });

      test('extracts receipt with TOTAL BRUTO and ABATIMENTO', () {
        const text = '''
TOTAL BRUTO: 200,00
ABATIMENTO: 20,00
TOTAL LIQUIDO: 180,00
''';
        final result = parser.parseText(text);

        expect(result.subtotal, equals(const Money(20000)));
        expect(result.discount, equals(const Money(2000)));
        expect(result.total, equals(const Money(18000)));
      });
    });

    group('Payment Method extraction', () {
      test('recognizes CARTAO DE DEBITO', () {
        final result = parser.parseText('FORMA DE PAGAMENTO: CARTAO DE DEBITO');
        expect(result.paymentMethod, equals('CARTÃO DE DÉBITO'));
      });

      test('recognizes CARTAO DE CREDITO', () {
        final result = parser.parseText('PAGAMENTO: CARTAO DE CREDITO');
        expect(result.paymentMethod, equals('CARTÃO DE CRÉDITO'));
      });

      test('recognizes DINHEIRO / ESPECIE', () {
        expect(
          parser.parseText('DINHEIRO R\$ 50,00').paymentMethod,
          equals('DINHEIRO'),
        );
        expect(
          parser.parseText('EM ESPÉCIE').paymentMethod,
          equals('DINHEIRO'),
        );
      });

      test('recognizes PIX', () {
        final result = parser.parseText('PAGAMENTO PIX R\$ 35,00');
        expect(result.paymentMethod, equals('PIX'));
      });

      test('recognizes VALE ALIMENTACAO (VA)', () {
        expect(
          parser.parseText('VALE ALIMENTACAO R\$ 120,00').paymentMethod,
          equals('VALE ALIMENTAÇÃO'),
        );
        expect(
          parser.parseText('PAGTO VA R\$ 50,00').paymentMethod,
          equals('VALE ALIMENTAÇÃO'),
        );
      });

      test('recognizes VALE REFEICAO (VR)', () {
        expect(
          parser.parseText('VALE REFEICAO R\$ 40,00').paymentMethod,
          equals('VALE REFEIÇÃO'),
        );
        expect(
          parser.parseText('PAGTO VR R\$ 30,00').paymentMethod,
          equals('VALE REFEIÇÃO'),
        );
      });

      test('recognizes card brands (MASTERCARD / VISA)', () {
        expect(
          parser.parseText('CARTAO MASTERCARD R\$ 100,00').paymentMethod,
          equals('CARTÃO'),
        );
        expect(
          parser.parseText('VISA DEBITO R\$ 50,00').paymentMethod,
          equals('CARTÃO DE DÉBITO'),
        );
        expect(
          parser.parseText('ELO CREDITO R\$ 75,00').paymentMethod,
          equals('CARTÃO DE CRÉDITO'),
        );
      });
    });

    group(
      'Integration with ColumnDetector and OcrDocument (T-03 / RN-193)',
      () {
        test('parseDocument extracts totals from OcrDocument with bounding boxes and calculates confidence', () {
          const docLine1 = OcrTextLine(
            text: 'SUBTOTAL R\$ 50,00',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 380,
              bottom: 120,
            ),
            confidence: 0.90,
          );
          const docLine2 = OcrTextLine(
            text: 'DESCONTO R\$ 5,00',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 10,
              right: 380,
              bottom: 150,
            ),
            confidence: 0.92,
          );
          const docLine3 = OcrTextLine(
            text: 'TOTAL R\$ 45,00',
            boundingBox: OcrBoundingBox(
              top: 160,
              left: 10,
              right: 380,
              bottom: 180,
            ),
            confidence: 0.98,
          );
          const docLine4 = OcrTextLine(
            text: 'PIX R\$ 45,00',
            boundingBox: OcrBoundingBox(
              top: 190,
              left: 10,
              right: 380,
              bottom: 210,
            ),
            confidence: 0.96,
          );

          final doc = OcrDocument(
            lines: [docLine1, docLine2, docLine3, docLine4],
          );

          final result = parser.parseDocument(doc);

          expect(result.subtotal, equals(const Money(5000)));
          expect(result.discount, equals(const Money(500)));
          expect(result.total, equals(const Money(4500)));
          expect(result.paymentMethod, equals('PIX'));
          expect(result.confidence, closeTo(0.94, 0.01));
        });

        test('parseRows extracts totals from OcrRows with geometrically grouped columns', () {
          const segLeft = OcrColumnSegment(
            text: 'VALOR TOTAL A PAGAR R\$',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 200,
              bottom: 220,
            ),
            zone: OcrColumnZone.left,
            confidence: 0.95,
          );
          const segRight = OcrColumnSegment(
            text: '120,50',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 300,
              right: 380,
              bottom: 220,
            ),
            zone: OcrColumnZone.right,
            confidence: 0.99,
          );
          const line = OcrTextLine(
            text: 'VALOR TOTAL A PAGAR R\$ 120,50',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 220,
            ),
            confidence: 0.97,
          );

          const row = OcrRow(
            rowIndex: 0,
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 220,
            ),
            lines: [line],
            elements: [],
            segments: [segLeft, segRight],
            text: 'VALOR TOTAL A PAGAR R\$ 120,50',
            averageConfidence: 0.97,
          );

          final result = parser.parseRows([row]);

          expect(result.total, equals(const Money(12050)));
          expect(result.confidence, closeTo(0.97, 0.001));
        });
      },
    );

    group('Lines with negation and TOTAL false positives', () {
      test('ignores line QTD. TOTAL DE ITENS 12', () {
        const text = '''
QTD. TOTAL DE ITENS 12
TOTAL R\$ 48,00
''';
        final result = parser.parseText(text);

        expect(result.total, equals(const Money(4800)));
      });

      test('ignores line TOTAL DE ITENS 5', () {
        const text = '''
TOTAL DE ITENS: 5
VALOR A PAGAR: R\$ 25,00
''';
        final result = parser.parseText(text);

        expect(result.total, equals(const Money(2500)));
      });
    });

    group('Empty document and no totals validations', () {
      test('returns TotalsResult with null fields and 0.0 confidence for empty document', () {
        final result = parser.parseDocument(OcrDocument());

        expect(result.subtotal, isNull);
        expect(result.discount, isNull);
        expect(result.total, isNull);
        expect(result.paymentMethod, isNull);
        expect(result.confidence, equals(0.0));
      });

      test('returns TotalsResult with null fields for text without totals', () {
        final result = parser.parseText(
          'CARREFOUR COMERCIO E INDUSTRIA LTDA\nAV PAULISTA 1000',
        );

        expect(result.total, isNull);
        expect(result.confidence, equals(0.0));
      });
    });

    group('Alias TotalParser', () {
      test('TotalParser works identically to TotalsParser', () {
        const TotalParser aliasParser = TotalParser();
        final result = aliasParser.parseText('TOTAL R\$ 10,00');
        expect(result.total, equals(const Money(1000)));
      });
    });

    group('Equality, hashCode and toString of TotalsResult', () {
      test('operator == and hashCode work correctly', () {
        const res1 = TotalsResult(
          subtotal: Money(9040),
          discount: Money(300),
          total: Money(8740),
          paymentMethod: 'CARTÃO DE DÉBITO',
          confidence: 0.95,
        );
        const res2 = TotalsResult(
          subtotal: Money(9040),
          discount: Money(300),
          total: Money(8740),
          paymentMethod: 'CARTÃO DE DÉBITO',
          confidence: 0.95,
        );

        expect(res1, equals(res2));
        expect(res1.hashCode, equals(res2.hashCode));
      });

      test('toString returns formatted representation', () {
        const res = TotalsResult(
          total: Money(1000),
          paymentMethod: 'PIX',
          confidence: 1.0,
        );
        expect(res.toString(), contains('TotalsResult'));
        expect(res.toString(), contains('paymentMethod: PIX'));
      });
    });
  });
}
