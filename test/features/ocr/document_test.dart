// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

void main() {
  // ---------------------------------------------------------------------------
  // OcrBoundingBox
  // ---------------------------------------------------------------------------
  group('OcrBoundingBox', () {
    const box = OcrBoundingBox(top: 10, left: 20, right: 120, bottom: 40);

    test('width and height calculated correctly', () {
      expect(box.width, 100);
      expect(box.height, 30);
    });

    test('round-trip serialization (toJson -> fromJson)', () {
      final json = box.toJson();
      final restored = OcrBoundingBox.fromJson(json);
      expect(restored, equals(box));
    });

    test('fromJson accepts int and double (num)', () {
      final json = {'top': 1, 'left': 2, 'right': 3, 'bottom': 4};
      final b = OcrBoundingBox.fromJson(json);
      expect(b.top, 1.0);
      expect(b.left, 2.0);
      expect(b.right, 3.0);
      expect(b.bottom, 4.0);
    });

    test('equality and hashCode', () {
      const b2 = OcrBoundingBox(top: 10, left: 20, right: 120, bottom: 40);
      expect(box, equals(b2));
      expect(box.hashCode, equals(b2.hashCode));
    });

    test('distinct objects are not equal', () {
      const other = OcrBoundingBox(top: 0, left: 0, right: 10, bottom: 10);
      expect(box, isNot(equals(other)));
    });
  });

  // ---------------------------------------------------------------------------
  // OcrTextElement
  // ---------------------------------------------------------------------------
  group('OcrTextElement', () {
    const box = OcrBoundingBox(top: 0, left: 0, right: 50, bottom: 15);
    const element = OcrTextElement(
      text: 'LEITE',
      boundingBox: box,
      confidence: 0.98,
    );

    test('round-trip serialization', () {
      final json = element.toJson();
      final restored = OcrTextElement.fromJson(json);
      expect(restored, equals(element));
    });

    test('equality and hashCode', () {
      const e2 = OcrTextElement(
        text: 'LEITE',
        boundingBox: box,
        confidence: 0.98,
      );
      expect(element, equals(e2));
      expect(element.hashCode, equals(e2.hashCode));
    });

    test('different confidence -> not equal', () {
      const e3 = OcrTextElement(
        text: 'LEITE',
        boundingBox: box,
        confidence: 0.5,
      );
      expect(element, isNot(equals(e3)));
    });
  });

  // ---------------------------------------------------------------------------
  // OcrTextLine
  // ---------------------------------------------------------------------------
  group('OcrTextLine', () {
    const box = OcrBoundingBox(top: 10, left: 0, right: 200, bottom: 25);
    const elem = OcrTextElement(
      text: 'PORCAO',
      boundingBox: OcrBoundingBox(top: 10, left: 0, right: 80, bottom: 25),
      confidence: 0.9,
    );
    const line = OcrTextLine(
      text: 'PORCAO 100G',
      boundingBox: box,
      confidence: 0.88,
      elements: [elem],
    );

    test('round-trip serialization with elements', () {
      final json = line.toJson();
      final restored = OcrTextLine.fromJson(json);
      expect(restored, equals(line));
    });

    test('missing elements in JSON -> empty list', () {
      final json = {
        'text': 'ABC',
        'boundingBox': {'top': 0.0, 'left': 0.0, 'right': 10.0, 'bottom': 5.0},
        'confidence': 0.7,
      };
      final l = OcrTextLine.fromJson(json);
      expect(l.elements, isEmpty);
    });

    test('equality considers elements', () {
      const lineNoElem = OcrTextLine(
        text: 'PORCAO 100G',
        boundingBox: box,
        confidence: 0.88,
      );
      expect(line, isNot(equals(lineNoElem)));
    });
  });

  // ---------------------------------------------------------------------------
  // OcrTextBlock
  // ---------------------------------------------------------------------------
  group('OcrTextBlock', () {
    const box = OcrBoundingBox(top: 0, left: 0, right: 300, bottom: 100);
    const line = OcrTextLine(
      text: 'ARROZ 5KG',
      boundingBox: OcrBoundingBox(top: 5, left: 0, right: 200, bottom: 20),
      confidence: 0.95,
    );
    const block = OcrTextBlock(
      text: 'ARROZ 5KG',
      boundingBox: box,
      lines: [line],
    );

    test('round-trip serialization', () {
      final json = block.toJson();
      final restored = OcrTextBlock.fromJson(json);
      expect(restored, equals(block));
    });

    test('missing lines in JSON -> empty list', () {
      final json = {
        'text': 'X',
        'boundingBox': {'top': 0.0, 'left': 0.0, 'right': 1.0, 'bottom': 1.0},
      };
      final b = OcrTextBlock.fromJson(json);
      expect(b.lines, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // OcrDocument
  // ---------------------------------------------------------------------------
  group('OcrDocument', () {
    // helpers
    OcrBoundingBox box(double t, double l, double r, double b) =>
        OcrBoundingBox(top: t, left: l, right: r, bottom: b);

    OcrTextLine line(String text, double confidence) => OcrTextLine(
      text: text,
      boundingBox: box(0, 0, 100, 15),
      confidence: confidence,
    );

    OcrTextBlock block(List<OcrTextLine> lines) => OcrTextBlock(
      text: lines.map((l) => l.text).join(' '),
      boundingBox: box(0, 0, 300, 100),
      lines: lines,
    );

    // --- empty ---
    group('empty document', () {
      final empty = OcrDocument();

      test('empty blocks and lines', () {
        expect(empty.blocks, isEmpty);
        expect(empty.lines, isEmpty);
      });

      test('averageConfidence is 0.0 (no data = no confidence)', () {
        expect(empty.averageConfidence, 0.0);
      });

      test('round-trip serialization', () {
        final json = empty.toJson();
        final restored = OcrDocument.fromJson(json);
        expect(restored, equals(empty));
      });
    });

    // --- with data ---
    group('document with blocks', () {
      final doc = OcrDocument(
        blocks: [
          block([line('ITEM A', 0.9), line('ITEM B', 0.8)]),
          block([line('ITEM C', 0.7)]),
        ],
        imageWidth: 640,
        imageHeight: 480,
      );

      test('lines flattens all blocks in order', () {
        final ls = doc.lines;
        expect(ls, hasLength(3));
        expect(ls[0].text, 'ITEM A');
        expect(ls[1].text, 'ITEM B');
        expect(ls[2].text, 'ITEM C');
      });

      test('averageConfidence = average of lines across all blocks', () {
        // (0.9 + 0.8 + 0.7) / 3 = 0.8
        expect(doc.averageConfidence, closeTo(0.8, 1e-9));
      });

      test('imageWidth and imageHeight preserved', () {
        expect(doc.imageWidth, 640);
        expect(doc.imageHeight, 480);
      });

      test('round-trip serialization maintains dimensions and structure', () {
        final json = doc.toJson();
        final restored = OcrDocument.fromJson(json);
        expect(restored, equals(doc));
        expect(restored.imageWidth, 640);
        expect(restored.imageHeight, 480);
        expect(restored.lines, hasLength(3));
      });

      test('JSON without imageWidth/imageHeight -> defaults to 0', () {
        final json = {
          'blocks': <dynamic>[],
          // without imageWidth or imageHeight
        };
        final d = OcrDocument.fromJson(json);
        expect(d.imageWidth, 0);
        expect(d.imageHeight, 0);
      });

      test('equality considers blocks, imageWidth, and imageHeight', () {
        final same = OcrDocument(
          blocks: doc.blocks,
          imageWidth: 640,
          imageHeight: 480,
        );
        expect(doc, equals(same));

        final differentSize = OcrDocument(
          blocks: doc.blocks,
          imageWidth: 1280,
          imageHeight: 960,
        );
        expect(doc, isNot(equals(differentSize)));
      });

      test('hashCode consistent with equality', () {
        final same = OcrDocument(
          blocks: doc.blocks,
          imageWidth: 640,
          imageHeight: 480,
        );
        expect(doc.hashCode, equals(same.hashCode));
      });
    });

    // --- confidence with a single block/line ---
    group('averageConfidence - edge cases', () {
      test('single block with one line', () {
        final doc = OcrDocument(
          blocks: [
            block([line('X', 0.55)]),
          ],
        );
        expect(doc.averageConfidence, closeTo(0.55, 1e-9));
      });

      test('confidence 1.0 (all perfect)', () {
        final doc = OcrDocument(
          blocks: [
            block([line('A', 1.0), line('B', 1.0)]),
          ],
        );
        expect(doc.averageConfidence, 1.0);
      });

      test('confidence 0.0 (all zero)', () {
        final doc = OcrDocument(
          blocks: [
            block([line('A', 0.0), line('B', 0.0)]),
          ],
        );
        expect(doc.averageConfidence, 0.0);
      });
    });

    // --- direct lines support, JSON variations, and XOR cancellation prevention ---
    group('direct line construction and support for flexible JSON formats', () {
      test('direct construction with lines generates aggregating block', () {
        final l1 = line('LINHA 1', 0.9);
        final l2 = line('LINHA 2', 0.8);
        final doc = OcrDocument(
          lines: [l1, l2],
          imageWidth: 500,
          imageHeight: 800,
        );

        expect(doc.blocks, hasLength(1));
        expect(doc.lines, hasLength(2));
        expect(doc.lines[0].text, 'LINHA 1');
        expect(doc.lines[1].text, 'LINHA 2');
        expect(doc.averageConfidence, closeTo(0.85, 1e-9));
      });

      test('fromJson with lines at root level', () {
        final json = {
          'lines': [
            {
              'text': 'ARROZ 5KG',
              'boundingBox': {
                'top': 0.0,
                'left': 0.0,
                'right': 100.0,
                'bottom': 20.0,
              },
              'confidence': 0.95,
            },
          ],
          'imageWidth': 1000.0,
          'imageHeight': 2000.0,
        };
        final doc = OcrDocument.fromJson(json);
        expect(doc.lines, hasLength(1));
        expect(doc.lines.first.text, 'ARROZ 5KG');
        expect(doc.imageWidth, 1000.0);
      });

      test('fromJson accepts image size key variations (width/height and imageSize)', () {
        final jsonWidthHeight = {'width': 800, 'height': 600};
        final doc1 = OcrDocument.fromJson(jsonWidthHeight);
        expect(doc1.imageWidth, 800);
        expect(doc1.imageHeight, 600);

        final jsonImageSize = {
          'imageSize': {'width': 1024, 'height': 768},
        };
        final doc2 = OcrDocument.fromJson(jsonImageSize);
        expect(doc2.imageWidth, 1024);
        expect(doc2.imageHeight, 768);
      });

      test('prevention of XOR cancellation in hashCode with duplicate elements/lines', () {
        final l1 = line('DUP', 0.9);
        final b1 = OcrTextBlock(
          text: 'DUP DUP',
          boundingBox: box(0, 0, 100, 20),
          lines: [l1, l1],
        );
        final bEmpty = OcrTextBlock(
          text: 'DUP DUP',
          boundingBox: box(0, 0, 100, 20),
          lines: const [],
        );

        expect(b1.hashCode, isNot(equals(bEmpty.hashCode)));
      });
    });

    // --- CA-7.1: empty document produced by complete failure ---
    test('CA-7.1: empty OcrDocument represents total OCR failure', () {
      final failureDoc = OcrDocument();
      expect(failureDoc.lines, isEmpty);
      expect(failureDoc.averageConfidence, 0.0);
      // The review screen can check isEmpty to open manual entry:
      expect(failureDoc.blocks.isEmpty, isTrue);
    });
  });
}
