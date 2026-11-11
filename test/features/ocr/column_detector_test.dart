import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

void main() {
  group('ColumnDetector - Geometry Grouping (T-03 / RN-193)', () {
    const detector = ColumnDetector();

    test('empty document returns empty visual rows list', () {
      final doc = OcrDocument();
      final rows = detector.detectRows(doc);
      expect(rows, isEmpty);
    });

    test('empty lines list returns empty visual rows list', () {
      final rows = detector.groupLinesIntoRows([]);
      expect(rows, isEmpty);
    });

    test('single isolated line generates 1 OcrRow with 1 segment', () {
      const line = OcrTextLine(
        text: '001 ARROZ BRANCO 5KG',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 20,
          right: 220,
          bottom: 120,
        ),
        confidence: 0.95,
      );
      final doc = OcrDocument(lines: [line], imageWidth: 400, imageHeight: 800);

      final rows = detector.detectRows(doc);

      expect(rows.length, equals(1));
      expect(rows.first.rowIndex, equals(0));
      expect(rows.first.text, equals('001 ARROZ BRANCO 5KG'));
      expect(rows.first.averageConfidence, closeTo(0.95, 0.001));
      expect(rows.first.segments.length, equals(1));
      expect(rows.first.leftSegment?.text, equals('001 ARROZ BRANCO 5KG'));
    });

    test('lines with vertical overlap are grouped in the same OcrRow', () {
      // Two lines separated by OCR (one on left, other on right) at the same Y coordinate
      const leftLine = OcrTextLine(
        text: '001 CAFE PILAO 500G',
        boundingBox: OcrBoundingBox(
          top: 150,
          left: 20,
          right: 200,
          bottom: 170,
        ),
        confidence: 0.9,
      );
      const rightLine = OcrTextLine(
        text: '18,90',
        boundingBox: OcrBoundingBox(
          top: 152,
          left: 300,
          right: 360,
          bottom: 168,
        ),
        confidence: 0.98,
      );

      final doc = OcrDocument(
        lines: [leftLine, rightLine],
        imageWidth: 400,
        imageHeight: 800,
      );

      final rows = detector.detectRows(doc);

      expect(
        rows.length,
        equals(1),
        reason: 'Lines at the same Y must become a single OcrRow',
      );
      final row = rows.first;
      expect(row.lines.length, equals(2));
      expect(row.text, equals('001 CAFE PILAO 500G 18,90'));
      expect(row.leftSegment?.text, equals('001 CAFE PILAO 500G'));
      expect(row.rightSegment?.text, equals('18,90'));
      expect(row.averageConfidence, closeTo(0.94, 0.01));
    });

    test('elements are ordered from left to right (left ascending)', () {
      // Right line comes BEFORE left line in input list
      const rightLine = OcrTextLine(
        text: '28,90',
        boundingBox: OcrBoundingBox(
          top: 200,
          left: 320,
          right: 380,
          bottom: 220,
        ),
        confidence: 0.95,
      );
      const leftLine = OcrTextLine(
        text: '002 FEIJAO CARIOCA 1KG',
        boundingBox: OcrBoundingBox(
          top: 201,
          left: 10,
          right: 210,
          bottom: 219,
        ),
        confidence: 0.92,
      );

      final rows = detector.groupLinesIntoRows([
        rightLine,
        leftLine,
      ], imageWidth: 400);

      expect(rows.length, equals(1));
      expect(rows.first.text, equals('002 FEIJAO CARIOCA 1KG 28,90'));
      expect(rows.first.leftSegment?.text, equals('002 FEIJAO CARIOCA 1KG'));
      expect(rows.first.rightSegment?.text, equals('28,90'));
    });

    test(
      'linhas em alturas Y distintas geram OcrRows separadas ordenadas por Y',
      () {
        const line1 = OcrTextLine(
          text: 'CARREFOUR COMERCIO LTDA',
          boundingBox: OcrBoundingBox(
            top: 50,
            left: 50,
            right: 350,
            bottom: 70,
          ),
          confidence: 0.99,
        );
        const line2 = OcrTextLine(
          text: '001 ARROZ 5KG',
          boundingBox: OcrBoundingBox(
            top: 150,
            left: 20,
            right: 200,
            bottom: 170,
          ),
          confidence: 0.90,
        );
        const line3 = OcrTextLine(
          text: 'TOTAL R\$ 25,00',
          boundingBox: OcrBoundingBox(
            top: 300,
            left: 20,
            right: 380,
            bottom: 320,
          ),
          confidence: 0.96,
        );

        // Ordem misturada propositalmente
        final doc = OcrDocument(lines: [line3, line1, line2], imageWidth: 400);

        final rows = detector.detectRows(doc);

        expect(rows.length, equals(3));
        expect(rows[0].text, equals('CARREFOUR COMERCIO LTDA'));
        expect(rows[0].rowIndex, equals(0));
        expect(rows[1].text, equals('001 ARROZ 5KG'));
        expect(rows[1].rowIndex, equals(1));
        expect(rows[2].text, equals('TOTAL R\$ 25,00'));
        expect(rows[2].rowIndex, equals(2));
      },
    );

    test('column zone classification (left, middle, right)', () {
      const leftElem = OcrTextElement(
        text: '001 BISC RECH',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 150,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      const midElem = OcrTextElement(
        text: '1 UN X 4,50',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 180,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.9,
      );
      const rightElem = OcrTextElement(
        text: '4,50',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 320,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.95,
      );

      const line = OcrTextLine(
        text: '001 BISC RECH 1 UN X 4,50 4,50',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.9,
        elements: [leftElem, midElem, rightElem],
      );

      final rows = detector.groupLinesIntoRows([line], imageWidth: 400);

      expect(rows.length, equals(1));
      final row = rows.first;
      expect(row.segments.length, equals(3));
      expect(row.leftSegment?.text, equals('001 BISC RECH'));
      expect(row.leftSegment?.zone, equals(OcrColumnZone.left));
      expect(row.middleSegment?.text, equals('1 UN X 4,50'));
      expect(row.middleSegment?.zone, equals(OcrColumnZone.middle));
      expect(row.rightSegment?.text, equals('4,50'));
      expect(row.rightSegment?.zone, equals(OcrColumnZone.right));
    });

    test('long product description exceeding page midpoint is classified as left zone', () {
      const descElem = OcrTextElement(
        text: '001 CAFE PILAO EXTRA FORTE TORRADO E MOIDO 500G',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 250,
          bottom: 120,
        ),
        confidence: 0.95,
      );
      const priceElem = OcrTextElement(
        text: '18,90',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 320,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.98,
      );
      const line = OcrTextLine(
        text: '001 CAFE PILAO EXTRA FORTE TORRADO E MOIDO 500G 18,90',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 380,
          bottom: 120,
        ),
        confidence: 0.96,
        elements: [descElem, priceElem],
      );

      final rows = detector.groupLinesIntoRows([line], imageWidth: 400);

      expect(rows.length, equals(1));
      final row = rows.first;
      expect(
        row.leftSegment?.text,
        equals('001 CAFE PILAO EXTRA FORTE TORRADO E MOIDO 500G'),
      );
      expect(row.rightSegment?.text, equals('18,90'));
    });

    test('single header line occupying almost full width is classified as left zone', () {
      const line = OcrTextLine(
        text: 'CARREFOUR COMERCIO E INDUSTRIA LTDA S/A',
        boundingBox: OcrBoundingBox(top: 50, left: 15, right: 385, bottom: 70),
        confidence: 0.99,
      );

      final rows = detector.groupLinesIntoRows([line], imageWidth: 400);

      expect(rows.length, equals(1));
      expect(
        rows.first.leftSegment?.text,
        equals('CARREFOUR COMERCIO E INDUSTRIA LTDA S/A'),
      );
    });

    test('isolated total line right-aligned is classified as right zone', () {
      const line = OcrTextLine(
        text: 'TOTAL R\$ 150,00',
        boundingBox: OcrBoundingBox(
          top: 500,
          left: 270,
          right: 380,
          bottom: 520,
        ),
        confidence: 0.97,
      );

      final rows = detector.groupLinesIntoRows([line], imageWidth: 400);

      expect(rows.length, equals(1));
      expect(rows.first.rightSegment?.text, equals('TOTAL R\$ 150,00'));
      expect(rows.first.leftSegment, isNull);
    });

    test('horizontal gap smaller than minGapPixels keeps elements in the same segment', () {
      const customDetector = ColumnDetector(minGapPixels: 50.0);

      const elem1 = OcrTextElement(
        text: 'CAFE',
        boundingBox: OcrBoundingBox(top: 100, left: 10, right: 50, bottom: 120),
        confidence: 0.9,
      );
      const elem2 = OcrTextElement(
        text: 'PILAO',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 60,
          right: 110,
          bottom: 120,
        ),
        confidence: 0.9,
      );

      const line = OcrTextLine(
        text: 'CAFE PILAO',
        boundingBox: OcrBoundingBox(
          top: 100,
          left: 10,
          right: 110,
          bottom: 120,
        ),
        confidence: 0.9,
        elements: [elem1, elem2],
      );

      final rows = customDetector.groupLinesIntoRows([line], imageWidth: 400);

      expect(
        rows.first.segments.length,
        equals(1),
        reason: '10px gap < 50px minGapPixels',
      );
      expect(rows.first.segments.first.text, equals('CAFE PILAO'));
    });

    test(
      'zero imageWidth computes effective width based on maxRight coordinates',
      () {
        const line = OcrTextLine(
          text: 'ITEM PRECO 15,00',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 500,
            bottom: 120,
          ),
          confidence: 0.9,
        );

        final rows = detector.groupLinesIntoRows([line], imageWidth: 0);

        expect(rows.length, equals(1));
        expect(rows.first.boundingBox.right, equals(500));
      },
    );

    test(
      'lines without bounding box (0,0,0,0 coordinates) handled without error',
      () {
        const line1 = OcrTextLine(
          text: 'Linha 1',
          boundingBox: OcrBoundingBox(top: 0, left: 0, right: 100, bottom: 20),
          confidence: 0.8,
        );
        const line2 = OcrTextLine(
          text: 'Linha 2',
          boundingBox: OcrBoundingBox(top: 30, left: 0, right: 100, bottom: 50),
          confidence: 0.8,
        );

        final doc = OcrDocument(lines: [line1, line2]);
        final rows = detector.detectRows(doc);

        expect(rows.length, equals(2));
        expect(rows[0].text, equals('Linha 1'));
        expect(rows[1].text, equals('Linha 2'));
      },
    );

    test(
      'round-trip serialization of OcrColumnSegment (toJson -> fromJson)',
      () {
        const seg = OcrColumnSegment(
          text: '18,90',
          boundingBox: OcrBoundingBox(
            top: 10,
            left: 300,
            right: 360,
            bottom: 30,
          ),
          zone: OcrColumnZone.right,
          confidence: 0.95,
        );

        final json = seg.toJson();
        final restored = OcrColumnSegment.fromJson(json);

        expect(restored, equals(seg));
        expect(restored.zone, equals(OcrColumnZone.right));
        expect(restored.confidence, equals(0.95));
      },
    );

    test('round-trip serialization of OcrRow (toJson -> fromJson)', () {
      const seg = OcrColumnSegment(
        text: 'CAFE PILAO',
        boundingBox: OcrBoundingBox(top: 10, left: 10, right: 150, bottom: 30),
        zone: OcrColumnZone.left,
        confidence: 0.9,
      );
      const line = OcrTextLine(
        text: 'CAFE PILAO',
        boundingBox: OcrBoundingBox(top: 10, left: 10, right: 150, bottom: 30),
        confidence: 0.9,
      );
      const row = OcrRow(
        rowIndex: 0,
        boundingBox: OcrBoundingBox(top: 10, left: 10, right: 150, bottom: 30),
        lines: [line],
        elements: [],
        segments: [seg],
        text: 'CAFE PILAO',
        averageConfidence: 0.9,
      );

      final json = row.toJson();
      final restored = OcrRow.fromJson(json);

      expect(restored, equals(row));
      expect(restored.text, equals('CAFE PILAO'));
      expect(restored.lines.length, equals(1));
    });

    test(
      'equality operator == and hashCode for OcrRow and OcrColumnSegment',
      () {
        const seg1 = OcrColumnSegment(
          text: '45,00',
          boundingBox: OcrBoundingBox(top: 0, left: 0, right: 10, bottom: 10),
          zone: OcrColumnZone.right,
          confidence: 1.0,
        );
        const seg2 = OcrColumnSegment(
          text: '45,00',
          boundingBox: OcrBoundingBox(top: 0, left: 0, right: 10, bottom: 10),
          zone: OcrColumnZone.right,
          confidence: 1.0,
        );

        expect(seg1, equals(seg2));
        expect(seg1.hashCode, equals(seg2.hashCode));
      },
    );
  });
}
