import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/items_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';

void main() {
  group('ItemsParser - Item Extraction (T-06 / RN-193, RN-195, CA-2.2, CA-2.3)', () {
    const parser = ItemsParser();

    test('empty document returns empty items list', () {
      final doc = OcrDocument();
      final items = parser.parseItems(doc);
      expect(items, isEmpty);
    });

    test('parseRows with empty list returns empty items list', () {
      final items = parser.parseRows(const []);
      expect(items, isEmpty);
    });

    test('simple line extracts item with EAN code, quantity 1 UN and prices (RF-041, RN-193)', () {
      const line = OcrTextLine(
        text: '001 7891000123456 ARROZ BRANCO 5KG 1 UN X 25,90 25,90',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 390,
          bottom: 120,
        ),
        confidence: 0.95,
      );
      final doc = OcrDocument(lines: [line], imageWidth: 400);

      final items = parser.parseItems(doc);

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.rawDescription, equals('ARROZ BRANCO 5KG'));
      expect(item.ean, equals('7891000123456'));
      expect(item.quantity.displayValue, equals(1.0));
      expect(item.quantity.unit, equals(Unit.un));
      expect(item.unitPrice, equals(const Money(2590)));
      expect(item.totalPrice, equals(const Money(2590)));
      expect(item.confidence, closeTo(0.95, 0.01));
      expect(item.selected, isTrue);
    });

    test('CA-2.3 - weighed item (0.734 KG X 39.90) extracts quantity 0.734kg, unit price R\$ 39,90 and total R\$ 29,29', () {
      const line1 = OcrTextLine(
        text: '003 MAÇA GALA NACIONAL',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.92,
      );
      const line2 = OcrTextLine(
        text: '0,734 KG X 39,90',
        boundingBox: OcrBoundingBox(
          top: 122,
          left: 10,
          right: 200,
          bottom: 140,
        ),
        confidence: 0.94,
      );

      final doc = OcrDocument(lines: [line1, line2], imageWidth: 400);

      final items = parser.parseItems(doc);

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.rawDescription, equals('MAÇA GALA NACIONAL'));
      expect(item.quantity.unit, equals(Unit.kg));
      expect(item.quantity.displayValue, closeTo(0.734, 0.001));
      expect(item.quantity.valueMilli, equals(734));
      expect(item.unitPrice, equals(const Money(3990)));
      expect(
        item.totalPrice,
        equals(const Money(2929)),
        reason: '0.734 x 39.90 = 29.2866 => R\$ 29,29',
      );
      expect(item.selected, isTrue);
    });

    test(
      'CA-2.2 — descrição quebrada em duas linhas é combinada em um único item',
      () {
        const line1 = OcrTextLine(
          text: '001 BISC RECHEADO CHOCOLATE',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 250,
            bottom: 120,
          ),
          confidence: 0.90,
        );
        const line2 = OcrTextLine(
          text: 'NESTLE 140G 2 UN X 4,50 9,00',
          boundingBox: OcrBoundingBox(
            top: 125,
            left: 10,
            right: 380,
            bottom: 145,
          ),
          confidence: 0.95,
        );

        final doc = OcrDocument(lines: [line1, line2], imageWidth: 400);

        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        final item = items.first;
        expect(
          item.rawDescription,
          equals('BISC RECHEADO CHOCOLATE NESTLE 140G'),
        );
        expect(item.quantity.displayValue, equals(2.0));
        expect(item.quantity.unit, equals(Unit.un));
        expect(item.unitPrice, equals(const Money(450)));
        expect(item.totalPrice, equals(const Money(900)));
        expect(item.selected, isTrue);
      },
    );

    test('extracts text after quantity expression (textAfter) and captures trailing EAN', () {
      const line1 = OcrTextLine(
        text: '001 SABONETE LIQUIDO 250ML',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.90,
      );
      const line2 = OcrTextLine(
        text: '2 UN X 8,50 17,00 7891234567890 ST',
        boundingBox: OcrBoundingBox(
          top: 125,
          left: 10,
          right: 380,
          bottom: 145,
        ),
        confidence: 0.95,
      );

      final doc = OcrDocument(lines: [line1, line2], imageWidth: 400);
      final items = parser.parseItems(doc);

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.rawDescription, contains('SABONETE LIQUIDO 250ML'));
      expect(item.ean, equals('7891234567890'));
      expect(item.unitPrice, equals(const Money(850)));
      expect(item.totalPrice, equals(const Money(1700)));
    });

    test('RN-195 — item with confidence < 0.6 has selected = false', () {
      const line = OcrTextLine(
        text: '001 CAFE PILAO 500G 1 UN X 18,90 18,90',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.45,
      );
      final doc = OcrDocument(lines: [line], imageWidth: 400);

      final items = parser.parseItems(doc);

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.confidence, equals(0.45));
      expect(
        item.selected,
        isFalse,
        reason: 'Confidence < 0.6 should be unselected by default',
      );
    });

    test(
      'ignores store header lines (CNPJ, CPF, IE, DANFE, SAT) and total lines',
      () {
        const headerLine = OcrTextLine(
          text: 'CARREFOUR COMERCIO LTDA CNPJ: 45.543.915/0001-81 CPF: 123.456.789-00 IE: 123456',
          boundingBox: OcrBoundingBox(
            top: 10,
            left: 10,
            right: 380,
            bottom: 30,
          ),
          confidence: 0.99,
        );
        const satLine = OcrTextLine(
          text: 'SAT CÓDIGO DESCRIÇÃO QTD VL UN VL TOTAL',
          boundingBox: OcrBoundingBox(
            top: 40,
            left: 10,
            right: 380,
            bottom: 60,
          ),
          confidence: 0.98,
        );
        const itemLine = OcrTextLine(
          text: '001 LEITE INTEGRAL 1L 1 UN X 5,50 5,50',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.95,
        );
        const totalLine = OcrTextLine(
          text: 'TOTAL R\$ 5,50',
          boundingBox: OcrBoundingBox(
            top: 200,
            left: 10,
            right: 380,
            bottom: 220,
          ),
          confidence: 0.99,
        );

        final doc = OcrDocument(
          lines: [headerLine, satLine, itemLine, totalLine],
          imageWidth: 400,
        );

        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        expect(items.first.rawDescription, equals('LEITE INTEGRAL 1L'));
        expect(items.first.totalPrice, equals(const Money(550)));
      },
    );

    test(
      'linha com preço isolado no final extrai item com quantidade 1 UN',
      () {
        const line = OcrTextLine(
          text: '001 AÇUCAR REFINADO 1KG 6,90',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.91,
        );
        final doc = OcrDocument(lines: [line], imageWidth: 400);

        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        final item = items.first;
        expect(item.rawDescription, equals('AÇUCAR REFINADO 1KG'));
        expect(item.quantity.displayValue, equals(1.0));
        expect(item.unitPrice, equals(const Money(690)));
        expect(item.totalPrice, equals(const Money(690)));
      },
    );

    test('rightSegment with plain integer (e.g. "001") is not interpreted as price', () {
      const row = OcrRow(
        rowIndex: 0,
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 350,
          bottom: 120,
        ),
        lines: [],
        elements: [],
        segments: [
          OcrColumnSegment(
            text: '001 AÇUCAR REFINADO 1KG',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 250,
              bottom: 120,
            ),
            zone: OcrColumnZone.left,
            confidence: 0.9,
          ),
          OcrColumnSegment(
            text: '001',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 300,
              right: 350,
              bottom: 120,
            ),
            zone: OcrColumnZone.right,
            confidence: 0.9,
          ),
        ],
        text: '001 AÇUCAR REFINADO 1KG 001',
        averageConfidence: 0.9,
      );

      final items = parser.parseRows([row]);
      expect(
        items,
        isEmpty,
        reason:
            'Without price or valid quantity, should not create invalid item',
      );
    });

    test('different units of measure (g, l, ml, pack, cx, pct, etc.) are identified', () {
      final doc = OcrDocument(
        lines: const [
          OcrTextLine(
            text: '001 QUEIJO PARMESÃO 200 G X 15,00',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 380,
              bottom: 120,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '002 SUCO DE LARANJA 1 L X 12,00',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 10,
              right: 380,
              bottom: 150,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '003 REFRIGERANTE 350 ML X 4,00',
            boundingBox: OcrBoundingBox(
              top: 160,
              left: 10,
              right: 380,
              bottom: 180,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '004 CERVEJA 6 PACK X 24,00',
            boundingBox: OcrBoundingBox(
              top: 190,
              left: 10,
              right: 380,
              bottom: 210,
            ),
            confidence: 0.95,
          ),
        ],
        imageWidth: 400,
      );

      final items = parser.parseItems(doc);

      expect(items.length, equals(4));
      expect(items[0].quantity.unit, equals(Unit.g));
      expect(items[1].quantity.unit, equals(Unit.l));
      expect(items[2].quantity.unit, equals(Unit.ml));
      expect(items[3].quantity.unit, equals(Unit.pack));
    });

    test(
      'item pendente é concluído antes de interromper no rodapé (SUBTOTAL)',
      () {
        const line1 = OcrTextLine(
          text: '001 CHOCOLATE',
          boundingBox: OcrBoundingBox(
            top: 80,
            left: 10,
            right: 250,
            bottom: 100,
          ),
          confidence: 0.9,
        );
        const line2 = OcrTextLine(
          text: '1 UN X 12,00 12,00',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.95,
        );
        const subtotalLine = OcrTextLine(
          text: 'SUBTOTAL R\$ 12,00',
          boundingBox: OcrBoundingBox(
            top: 130,
            left: 10,
            right: 380,
            bottom: 150,
          ),
          confidence: 0.99,
        );
        final doc = OcrDocument(
          lines: [line1, line2, subtotalLine],
          imageWidth: 400,
        );
        final items = parser.parseItems(doc);
        expect(items.length, equals(1));
        expect(items.first.rawDescription, equals('CHOCOLATE'));
      },
    );

    test(
      'item pendente é concluído ao encontrar rodapé FORMA DE PAGAMENTO',
      () {
        const line1 = OcrTextLine(
          text: '001 PANETONE 500G 1 UN X 15,00 15,00',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.9,
        );
        const footerLine = OcrTextLine(
          text: 'FORMA DE PAGAMENTO CARTÃO DÉBITO',
          boundingBox: OcrBoundingBox(
            top: 130,
            left: 10,
            right: 380,
            bottom: 150,
          ),
          confidence: 0.9,
        );
        final doc = OcrDocument(lines: [line1, footerLine], imageWidth: 400);
        final items = parser.parseItems(doc);
        expect(items.length, equals(1));
      },
    );

    test('pending item is finalized before skipping table header', () {
      const line1 = OcrTextLine(
        text: '001 BISCOITO MAIZENA 200G 1 UN X 4,50 4,50',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      const headerLine = OcrTextLine(
        text: 'CÓDIGO DESCRIÇÃO QTD VL UN VL TOTAL',
        boundingBox: OcrBoundingBox(
          top: 130,
          left: 10,
          right: 380,
          bottom: 150,
        ),
        confidence: 0.9,
      );
      final doc = OcrDocument(lines: [line1, headerLine], imageWidth: 400);
      final items = parser.parseItems(doc);
      expect(items.length, equals(1));
    });

    test('trailing text line without price or quantity is ignored', () {
      const line = OcrTextLine(
        text: 'TEXTO SOLTO SEM PREÇO',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      final doc = OcrDocument(lines: [line], imageWidth: 400);
      final items = parser.parseItems(doc);
      expect(items, isEmpty);
    });

    test('calculates row average confidence when elements are empty', () {
      const row = OcrRow(
        rowIndex: 0,
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 350,
          bottom: 120,
        ),
        lines: [],
        elements: [],
        segments: [
          OcrColumnSegment(
            text: '001 ARROZ 1 UN X 10,00 10,00',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 350,
              bottom: 120,
            ),
            zone: OcrColumnZone.left,
            confidence: 0.85,
          ),
        ],
        text: '001 ARROZ 1 UN X 10,00 10,00',
        averageConfidence: 0.85,
      );

      final items = parser.parseRows([row]);
      expect(items.length, equals(1));
      expect(items.first.confidence, equals(0.85));
    });

    test('tests unit of measure variations in _parseUnit (caixa, pct, unidade, etc)', () {
      final doc = OcrDocument(
        lines: const [
          OcrTextLine(
            text: '001 SUCO 1 CAIXA X 10,00',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 380,
              bottom: 120,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '002 ARROZ 1 PCT X 20,00',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 10,
              right: 380,
              bottom: 150,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '003 FEIJÃO 1 UNIDADE X 8,00',
            boundingBox: OcrBoundingBox(
              top: 160,
              left: 10,
              right: 380,
              bottom: 180,
            ),
            confidence: 0.95,
          ),
        ],
        imageWidth: 400,
      );
      final items = parser.parseItems(doc);
      expect(items.length, equals(3));
      expect(items[0].quantity.unit, equals(Unit.pack));
      expect(items[1].quantity.unit, equals(Unit.pack));
      expect(items[2].quantity.unit, equals(Unit.un));
    });

    test(
      'serialização round-trip de ReceiptItemDraft (toJson -> fromJson)',
      () {
        final draft = ReceiptItemDraft(
          rawDescription: 'ARROZ BRANCO 5KG',
          ean: '7891000123456',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(2590),
          totalPrice: const Money(2590),
          confidence: 0.95,
        );

        final json = draft.toJson();
        final restored = ReceiptItemDraft.fromJson(json);

        expect(restored, equals(draft));
        expect(restored.selected, isTrue);
      },
    );

    test(
      'serialização round-trip de ReceiptDraft com itemsSum e divergence',
      () {
        final item1 = ReceiptItemDraft(
          rawDescription: 'ARROZ 5KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(2500),
          totalPrice: const Money(2500),
          confidence: 0.9,
        );
        final item2 = ReceiptItemDraft(
          rawDescription: 'FEIJAO 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(1000),
          totalPrice: const Money(1000),
          confidence: 0.4, // desmarcado
        );

        final receipt = ReceiptDraft(
          store: const StoreDraft(
            name: 'Mercado Exemplo',
            cnpj: '12345678000195',
            isCnpjValid: true,
          ),
          items: [item1, item2],
          discount: const Money(200),
          total: const Money(2300),
          confidence: 0.88,
        );

        expect(
          receipt.itemsSum,
          equals(const Money(2500)),
          reason: 'Apenas item1 está selecionado',
        );
        expect(
          receipt.divergence,
          equals(const Money(0)),
          reason: '2500 - 200 - 2300 = 0',
        );

        final json = receipt.toJson();
        final restored = ReceiptDraft.fromJson(json);

        expect(restored.store.name, equals('Mercado Exemplo'));
        expect(restored.items.length, equals(2));
        expect(restored.itemsSum, equals(const Money(2500)));
      },
    );

    test('rightSegment with valid monetary value extracts item price', () {
      const row = OcrRow(
        rowIndex: 0,
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 350,
          bottom: 120,
        ),
        lines: [],
        elements: [],
        segments: [
          OcrColumnSegment(
            text: '001 ARROZ BRANCO 5KG',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 250,
              bottom: 120,
            ),
            zone: OcrColumnZone.left,
            confidence: 0.9,
          ),
          OcrColumnSegment(
            text: '25,90',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 300,
              right: 350,
              bottom: 120,
            ),
            zone: OcrColumnZone.right,
            confidence: 0.9,
          ),
        ],
        text: '001 ARROZ BRANCO 5KG 25,90',
        averageConfidence: 0.9,
      );

      final items = parser.parseRows([row]);
      expect(items.length, equals(1));
      expect(items.first.rawDescription, equals('ARROZ BRANCO 5KG'));
      expect(items.first.totalPrice, equals(const Money(2590)));
    });

    test('extracts price formatted with period decimal separator typical of OCR (e.g. 12.50 -> R\$ 12,50)', () {
      const line = OcrTextLine(
        text: '001 BISCOITO 12.50',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      final doc = OcrDocument(lines: [line], imageWidth: 400);
      final items = parser.parseItems(doc);
      expect(items.length, equals(1));
      expect(
        items.first.totalPrice,
        equals(const Money(1250)),
        reason: '12.50 in OCR represents R\$ 12,50 (1250 cents)',
      );
    });

    test('calculates correct unit price for fractional quantity (0.500 KG X 40.00 -> total 20.00)', () {
      const row = OcrRow(
        rowIndex: 0,
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 350,
          bottom: 120,
        ),
        lines: [],
        elements: [],
        segments: [],
        text: '001 QUEIJO PRATO 0,500 KG X 40,00 20,00',
        averageConfidence: 0.9,
      );

      final items = parser.parseRows([row]);
      expect(items.length, equals(1));
      final item = items.first;
      expect(item.quantity, equals(const Quantity(500, Unit.kg)));
      expect(item.unitPrice, equals(const Money(4000)));
      expect(
        item.totalPrice,
        equals(const Money(2000)),
        reason: '0.5kg x R\$ 40,00 = R\$ 20,00',
      );
    });

    test('discards orphan text without price when starting new item index', () {
      const line1 = OcrTextLine(
        text: '001 TEXTO SOLTO SEM PRECO OU QUANTIDADE',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      const line2 = OcrTextLine(
        text: '002 SABÃO EM PÓ 1 UN X 15,00 15,00',
        boundingBox: OcrBoundingBox(
          top: 130,
          left: 10,
          right: 380,
          bottom: 150,
        ),
        confidence: 0.95,
      );
      final doc = OcrDocument(lines: [line1, line2], imageWidth: 400);

      final items = parser.parseItems(doc);
      expect(items.length, equals(1));
      expect(items.first.rawDescription, equals('SABÃO EM PÓ'));
      expect(items.first.totalPrice, equals(const Money(1500)));
    });

    test('T-B06 — ignores payment methods such as CARTAO DE CREDITO and PIX and headers', () {
      const lines = [
        OcrTextLine(
          text: 'CNPJ: 12.345.678/0001-90 CUPOM FISCAL',
          boundingBox: OcrBoundingBox(
            top: 20,
            left: 10,
            right: 380,
            bottom: 40,
          ),
          confidence: 0.95,
        ),
        OcrTextLine(
          text: '001 ARROZ TIO JOAO 1 UN X 20,00 20,00',
          boundingBox: OcrBoundingBox(
            top: 60,
            left: 10,
            right: 380,
            bottom: 80,
          ),
          confidence: 0.95,
        ),
        OcrTextLine(
          text: 'SUBTOTAL 20,00',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.95,
        ),
        OcrTextLine(
          text: 'PAGAMENTO CARTAO DE CREDITO 20,00',
          boundingBox: OcrBoundingBox(
            top: 130,
            left: 10,
            right: 380,
            bottom: 150,
          ),
          confidence: 0.95,
        ),
        OcrTextLine(
          text: 'PIX 20,00',
          boundingBox: OcrBoundingBox(
            top: 160,
            left: 10,
            right: 380,
            bottom: 180,
          ),
          confidence: 0.95,
        ),
      ];

      final doc = OcrDocument(lines: lines, imageWidth: 400);
      final items = parser.parseItems(doc);

      expect(items.length, equals(1));
      expect(items.first.rawDescription, equals('ARROZ TIO JOAO'));
    });

    group('T-B10 — Isolar dados fiscais, impostos IBPT e formas de pagamento (RF-041, RN-193)', () {
      test(
        'filtra linhas de tributos e impostos IBPT com ou sem valores anexados',
        () {
          const taxLines = [
            OcrTextLine(
              text: '001 ARROZ BRANCO 5KG 1 UN X 25,90 25,90',
              boundingBox: OcrBoundingBox(
                top: 20,
                left: 10,
                right: 380,
                bottom: 40,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Val Aprox Tributos R\$ 4,50 (17,4%)',
              boundingBox: OcrBoundingBox(
                top: 50,
                left: 10,
                right: 380,
                bottom: 70,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Valor Aprox Tributos 3,50',
              boundingBox: OcrBoundingBox(
                top: 80,
                left: 10,
                right: 380,
                bottom: 100,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Vl. Aprox. Tributos R\$ 2,10',
              boundingBox: OcrBoundingBox(
                top: 110,
                left: 10,
                right: 380,
                bottom: 130,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Vlr Aprox Tributos 1,90',
              boundingBox: OcrBoundingBox(
                top: 140,
                left: 10,
                right: 380,
                bottom: 160,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Tributos Incidentes (Lei Federal 12.741/2012) R\$ 8,12',
              boundingBox: OcrBoundingBox(
                top: 170,
                left: 10,
                right: 380,
                bottom: 190,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Total de Tributos: R\$ 5,00',
              boundingBox: OcrBoundingBox(
                top: 200,
                left: 10,
                right: 380,
                bottom: 220,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Fonte IBPT',
              boundingBox: OcrBoundingBox(
                top: 230,
                left: 10,
                right: 380,
                bottom: 250,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Fonte: IBPT R\$ 3,50',
              boundingBox: OcrBoundingBox(
                top: 260,
                left: 10,
                right: 380,
                bottom: 280,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'IBPT R\$ 1,50',
              boundingBox: OcrBoundingBox(
                top: 290,
                left: 10,
                right: 380,
                bottom: 310,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'Total Tributos Federais R\$ 3,00 Estaduais R\$ 2,00',
              boundingBox: OcrBoundingBox(
                top: 320,
                left: 10,
                right: 380,
                bottom: 340,
              ),
              confidence: 0.95,
            ),
          ];

          final doc = OcrDocument(lines: taxLines, imageWidth: 400);
          final items = parser.parseItems(doc);

          expect(items.length, equals(1));
          expect(items.first.rawDescription, equals('ARROZ BRANCO 5KG'));
          expect(items.first.totalPrice, equals(const Money(2590)));
        },
      );

      test('filtra linhas de dados fiscais complementares (chave de acesso, protocolo, consumidor, QR Code)', () {
        const fiscalLines = [
          OcrTextLine(
            text: '001 FEIJÃO CARIOCA 1KG 1 UN X 8,90 8,90',
            boundingBox: OcrBoundingBox(
              top: 20,
              left: 10,
              right: 380,
              bottom: 40,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Chave de acesso: 3521 1100 2200 3300 4400 5500 6600 7700 8800 9900 1122',
            boundingBox: OcrBoundingBox(
              top: 50,
              left: 10,
              right: 380,
              bottom: 70,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Consulte pela chave de acesso em https://www.fazenda.sp.gov.br',
            boundingBox: OcrBoundingBox(
              top: 80,
              left: 10,
              right: 380,
              bottom: 100,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Consulta pela chave',
            boundingBox: OcrBoundingBox(
              top: 110,
              left: 10,
              right: 380,
              bottom: 130,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text:
                'Protocolo de autorização: 135240001234567 16/10/2026 15:30:00',
            boundingBox: OcrBoundingBox(
              top: 140,
              left: 10,
              right: 380,
              bottom: 160,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Protocolo de autorizacao: 135240001234567',
            boundingBox: OcrBoundingBox(
              top: 170,
              left: 10,
              right: 380,
              bottom: 190,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Consumidor não identificado',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 220,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Consumidor nao identificado',
            boundingBox: OcrBoundingBox(
              top: 230,
              left: 10,
              right: 380,
              bottom: 250,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'CPF/CNPJ do Consumidor: Não Identificado',
            boundingBox: OcrBoundingBox(
              top: 260,
              left: 10,
              right: 380,
              bottom: 280,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Consulta via leitor de QR Code',
            boundingBox: OcrBoundingBox(
              top: 290,
              left: 10,
              right: 380,
              bottom: 310,
            ),
            confidence: 0.95,
          ),
        ];

        final doc = OcrDocument(lines: fiscalLines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        expect(items.first.rawDescription, equals('FEIJÃO CARIOCA 1KG'));
        expect(items.first.totalPrice, equals(const Money(890)));
      });

      test('filters payment methods, amounts paid and change preventing them from becoming items', () {
        const paymentLines = [
          OcrTextLine(
            text: '001 MACARRÃO ESPAGUETE 500G 1 UN X 4,50 4,50',
            boundingBox: OcrBoundingBox(
              top: 20,
              left: 10,
              right: 380,
              bottom: 40,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Cartão de Crédito 150,00',
            boundingBox: OcrBoundingBox(
              top: 50,
              left: 10,
              right: 380,
              bottom: 70,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Cartão de Débito 35,00',
            boundingBox: OcrBoundingBox(
              top: 80,
              left: 10,
              right: 380,
              bottom: 100,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'C. Crédito 20,00',
            boundingBox: OcrBoundingBox(
              top: 110,
              left: 10,
              right: 380,
              bottom: 130,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'C. Débito 15,00',
            boundingBox: OcrBoundingBox(
              top: 140,
              left: 10,
              right: 380,
              bottom: 160,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Dinheiro 50,00',
            boundingBox: OcrBoundingBox(
              top: 170,
              left: 10,
              right: 380,
              bottom: 190,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Em Dinheiro 50,00',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 220,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'PIX 25,00',
            boundingBox: OcrBoundingBox(
              top: 230,
              left: 10,
              right: 380,
              bottom: 250,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Troco 10,00',
            boundingBox: OcrBoundingBox(
              top: 260,
              left: 10,
              right: 380,
              bottom: 280,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Troco R\$ 5,00',
            boundingBox: OcrBoundingBox(
              top: 290,
              left: 10,
              right: 380,
              bottom: 310,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Vl. Pago 150,00',
            boundingBox: OcrBoundingBox(
              top: 320,
              left: 10,
              right: 380,
              bottom: 340,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Vlr Pago: 150,00',
            boundingBox: OcrBoundingBox(
              top: 350,
              left: 10,
              right: 380,
              bottom: 370,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Valor Pago R\$ 150,00',
            boundingBox: OcrBoundingBox(
              top: 380,
              left: 10,
              right: 380,
              bottom: 400,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Vale Alimentação 100,00',
            boundingBox: OcrBoundingBox(
              top: 410,
              left: 10,
              right: 380,
              bottom: 430,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Ticket Restaurante 30,00',
            boundingBox: OcrBoundingBox(
              top: 440,
              left: 10,
              right: 380,
              bottom: 460,
            ),
            confidence: 0.95,
          ),
        ];

        final doc = OcrDocument(lines: paymentLines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        expect(items.first.rawDescription, equals('MACARRÃO ESPAGUETE 500G'));
        expect(items.first.totalPrice, equals(const Money(450)));
      });

      test('does not filter false positives: legitimate products like "CHAVE DE FENDA" are preserved', () {
        const lines = [
          OcrTextLine(
            text: '001 CHAVE DE FENDA PHILIPS 1 UN X 12,00 12,00',
            boundingBox: OcrBoundingBox(
              top: 20,
              left: 10,
              right: 380,
              bottom: 40,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '002 SABONETE LIQUIDO 250ML 1 UN X 6,50 6,50',
            boundingBox: OcrBoundingBox(
              top: 50,
              left: 10,
              right: 380,
              bottom: 70,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'SUBTOTAL R\$ 18,50',
            boundingBox: OcrBoundingBox(
              top: 80,
              left: 10,
              right: 380,
              bottom: 100,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'TOTAL R\$ 18,50',
            boundingBox: OcrBoundingBox(
              top: 110,
              left: 10,
              right: 380,
              bottom: 130,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Val Aprox Tributos R\$ 3,20 (17,3%) Fonte IBPT',
            boundingBox: OcrBoundingBox(
              top: 140,
              left: 10,
              right: 380,
              bottom: 160,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'FORMA DE PAGAMENTO: CARTÃO DE CRÉDITO 18,50',
            boundingBox: OcrBoundingBox(
              top: 170,
              left: 10,
              right: 380,
              bottom: 190,
            ),
            confidence: 0.95,
          ),
        ];

        final doc = OcrDocument(lines: lines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(2));
        expect(items[0].rawDescription, equals('CHAVE DE FENDA PHILIPS'));
        expect(items[0].totalPrice, equals(const Money(1200)));
        expect(items[1].rawDescription, equals('SABONETE LIQUIDO 250ML'));
        expect(items[1].totalPrice, equals(const Money(650)));
      });
    });

    group('T-B12 — Real NFC-e cases (Receipts 1, 2 and 3)', () {
      test('Receipt 1: extracts items without X multiplier (1UN / 10N), cleans OCR noisy code (T8912274) and stops before card receipt (COMPR: VALOR:)', () {
        const lines = [
          OcrTextLine(
            text: 'CNPJ do Emitente 03.109.785/0001-23',
            boundingBox: OcrBoundingBox(
              top: 10,
              left: 10,
              right: 380,
              bottom: 25,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'COMERCIAL DE ALIMENTOS PEREIRA LIDA',
            boundingBox: OcrBoundingBox(
              top: 30,
              left: 10,
              right: 380,
              bottom: 45,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'CODIGO DESCRICAO QTDE. UN V.UNIT V.TOTAL',
            boundingBox: OcrBoundingBox(
              top: 60,
              left: 10,
              right: 380,
              bottom: 75,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'T8912274 SOBREMESA BATAVO FLAN 200G CARAMELO 10N 5,99 5,99',
            boundingBox: OcrBoundingBox(
              top: 90,
              left: 10,
              right: 380,
              bottom: 105,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '8410525146435 BALA FINI SM 80G MORANGO CITRICO',
            boundingBox: OcrBoundingBox(
              top: 110,
              left: 10,
              right: 320,
              bottom: 125,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '1UN 7,99 7,99',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 220,
              right: 380,
              bottom: 145,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text:
                'TO847033301 ENERG MONSTER ENERGY 473ML MANGO 1UN 11,49 11,49',
            boundingBox: OcrBoundingBox(
              top: 150,
              left: 10,
              right: 380,
              bottom: 165,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Qtde. Total de Itens 3',
            boundingBox: OcrBoundingBox(
              top: 180,
              left: 10,
              right: 380,
              bottom: 195,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'Valor a Pagar R\$ 25,47',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 215,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'FORMA PAGAMENTO VALOR PAGO',
            boundingBox: OcrBoundingBox(
              top: 220,
              left: 10,
              right: 380,
              bottom: 235,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'CARTAO CREDITO 25,47',
            boundingBox: OcrBoundingBox(
              top: 240,
              left: 10,
              right: 380,
              bottom: 255,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'COMPR:508894426 VALOR: 64,74',
            boundingBox: OcrBoundingBox(
              top: 280,
              left: 10,
              right: 380,
              bottom: 295,
            ),
            confidence: 0.95,
          ),
        ];

        final doc = OcrDocument(lines: lines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(3));
        expect(
          items[0].rawDescription,
          equals('SOBREMESA BATAVO FLAN 200G CARAMELO'),
        );
        expect(items[0].totalPrice, equals(const Money(599)));
        expect(
          items[1].rawDescription,
          equals('BALA FINI SM 80G MORANGO CITRICO'),
        );
        expect(items[1].totalPrice, equals(const Money(799)));
        expect(
          items[2].rawDescription,
          equals('ENERG MONSTER ENERGY 473ML MANGO'),
        );
        expect(items[2].totalPrice, equals(const Money(1149)));
      });

      test('Receipt 2: does not concatenate noisy header into first item and ignores footer/payment with OCR typos', () {
        const lines = [
          OcrTextLine(
            text: 'aONES PAIXAO & CIA LTDÄ',
            boundingBox: OcrBoundingBox(
              top: 10,
              left: 10,
              right: 380,
              bottom: 25,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: 'RUA EXEMPLO, 1006, BAIRRO CENTRO - SP. FONE (11)',
            boundingBox: OcrBoundingBox(
              top: 30,
              left: 10,
              right: 380,
              bottom: 45,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: 'Docunento Auxiliar da Nota Fiscal de Consun idur Eietronica',
            boundingBox: OcrBoundingBox(
              top: 50,
              left: 10,
              right: 380,
              bottom: 65,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: '1/10/25 10:49:13 LJ 00001 PDU 012 p00 38522 0P OPERADOR 01',
            boundingBox: OcrBoundingBox(
              top: 70,
              left: 10,
              right: 380,
              bottom: 85,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: 'EMITIDA EN CONTINGENCIA Pendente de autorizacaO',
            boundingBox: OcrBoundingBox(
              top: 90,
              left: 10,
              right: 380,
              bottom: 105,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: '( OIGO DESCRICAO QTDE. UN V.UNII U.70TAL',
            boundingBox: OcrBoundingBox(
              top: 110,
              left: 10,
              right: 380,
              bottom: 125,
            ),
            confidence: 0.85,
          ),
          OcrTextLine(
            text: 'i 98005516373 AGUA MINER STERBOM SPORT S/G 510HL 1UN 2,99 2,99',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 10,
              right: 380,
              bottom: 145,
            ),
            confidence: 0.90,
          ),
          OcrTextLine(
            text: 'i 945455 PASTILHAS TIC TAC 14G LARANJA 1UN 3,59 3,59',
            boundingBox: OcrBoundingBox(
              top: 150,
              left: 10,
              right: 380,
              bottom: 165,
            ),
            confidence: 0.90,
          ),
          OcrTextLine(
            text: '( de. Total de Itens 4 { iur 8 Pasur 25,56',
            boundingBox: OcrBoundingBox(
              top: 180,
              left: 10,
              right: 380,
              bottom: 195,
            ),
            confidence: 0.50,
          ),
          OcrTextLine(
            text: 'F RHA PAGAMENTO URLOR PAGO BTAO CREDITO 25,56',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 215,
            ),
            confidence: 0.50,
          ),
          OcrTextLine(
            text: 'C iMPR: UALUR: 25,56cd 25,56',
            boundingBox: OcrBoundingBox(
              top: 220,
              left: 10,
              right: 380,
              bottom: 235,
            ),
            confidence: 0.50,
          ),
        ];

        final doc = OcrDocument(lines: lines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(2));
        expect(
          items[0].rawDescription,
          equals('AGUA MINER STERBOM SPORT S/G 510HL'),
        );
        expect(items[0].totalPrice, equals(const Money(299)));
        expect(
          items[1].rawDescription,
          equals('PASTILHAS TIC TAC 14G LARANJA'),
        );
        expect(items[1].totalPrice, equals(const Money(359)));
      });

      test('Receipt 3: removes tax in parentheses (11,04), 6-digit code (468435) and ignores E Commerce and footer Procon/Lei 12.741', () {
        const lines = [
          OcrTextLine(
            text: '# | COD | DESC | QTD | UN | VL UN R\$ | (VLTR R\$)* | VL ITEM R\$',
            boundingBox: OcrBoundingBox(
              top: 20,
              left: 10,
              right: 380,
              bottom: 35,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '001 5489176 COMB SALMAO 315GR 1 UN X 35,12 (11,04) 35,12',
            boundingBox: OcrBoundingBox(
              top: 40,
              left: 10,
              right: 380,
              bottom: 55,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '002 468435 SAL COZ CISNE OVO 1 UN X 9,59 (3,21) 9,59',
            boundingBox: OcrBoundingBox(
              top: 60,
              left: 10,
              right: 380,
              bottom: 75,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '004 1108328 LASAN CALAB SAD 600G',
            boundingBox: OcrBoundingBox(
              top: 80,
              left: 10,
              right: 300,
              bottom: 95,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '1 UN X 18,90 (6,32) 18,90',
            boundingBox: OcrBoundingBox(
              top: 100,
              left: 10,
              right: 380,
              bottom: 115,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'QTD. TOTAL DE ITENS 3',
            boundingBox: OcrBoundingBox(
              top: 130,
              left: 10,
              right: 380,
              bottom: 145,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'VALOR TOTAL R\$ 63,61',
            boundingBox: OcrBoundingBox(
              top: 150,
              left: 10,
              right: 380,
              bottom: 165,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: 'E Commerce 150,39',
            boundingBox: OcrBoundingBox(
              top: 170,
              left: 10,
              right: 380,
              bottom: 185,
            ),
            confidence: 0.95,
          ),
          OcrTextLine(
            text: '49 Protacolo de autorizacao: 000000000000000 Data de autorlzacao 24/09/2026',
            boundingBox: OcrBoundingBox(
              top: 200,
              left: 10,
              right: 380,
              bottom: 215,
            ),
            confidence: 0.90,
          ),
          OcrTextLine(
            text: 'NOTA Trib (11) Totais RUA LEGAL- 0000-0000- EXEMPLO Incid RECEITA (Lei EXEMPLO, CENTRO Fed CIDADA 12.741/2012): CENTRO- 693 SP Rs 49,24',
            boundingBox: OcrBoundingBox(
              top: 220,
              left: 10,
              right: 380,
              bottom: 235,
            ),
            confidence: 0.90,
          ),
        ];

        final doc = OcrDocument(lines: lines, imageWidth: 400);
        final items = parser.parseItems(doc);

        expect(items.length, equals(3));
        expect(items[0].rawDescription, equals('COMB SALMAO 315GR'));
        expect(items[0].ean, equals('5489176'));
        expect(items[0].totalPrice, equals(const Money(3512)));
        expect(items[1].rawDescription, equals('SAL COZ CISNE OVO'));
        expect(items[1].ean, equals('468435'));
        expect(items[1].totalPrice, equals(const Money(959)));
        expect(items[2].rawDescription, equals('LASAN CALAB SAD 600G'));
        expect(items[2].ean, equals('1108328'));
        expect(items[2].totalPrice, equals(const Money(1890)));
      });
    });
  });
}
