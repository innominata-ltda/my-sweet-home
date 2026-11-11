// ---------------------------------------------------------------------------
// Private helpers (no external dependencies)
// ---------------------------------------------------------------------------

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Caixa delimitadora de um elemento reconhecido pelo OCR.
///
/// Coordinates in pixels of original (preprocessed) image.
/// Independent of Flutter SDK to keep domain 100% pure Dart.
final class OcrBoundingBox {
  final double top;
  final double left;
  final double right;
  final double bottom;

  const OcrBoundingBox({
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  factory OcrBoundingBox.fromJson(Map<String, dynamic> json) {
    return OcrBoundingBox(
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'top': top,
    'left': left,
    'right': right,
    'bottom': bottom,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrBoundingBox &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          left == other.left &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(top, left, right, bottom);

  @override
  String toString() =>
      'OcrBoundingBox(top: $top, left: $left, right: $right, bottom: $bottom)';
}

/// Smallest unit recognized by OCR engine (a word or symbol).
final class OcrTextElement {
  final String text;
  final OcrBoundingBox boundingBox;
  final double confidence;

  const OcrTextElement({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });

  factory OcrTextElement.fromJson(Map<String, dynamic> json) {
    return OcrTextElement(
      text: json['text'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'boundingBox': boundingBox.toJson(),
    'confidence': confidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrTextElement &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(text, boundingBox, confidence);

  @override
  String toString() => 'OcrTextElement(text: $text, confidence: $confidence)';
}

/// A single text line recognized by OCR engine.
///
/// Contains bounding box, confidence level and individual
/// elements (words/symbols) comprising the line.
final class OcrTextLine {
  final String text;
  final OcrBoundingBox boundingBox;
  final double confidence;
  final List<OcrTextElement> elements;

  const OcrTextLine({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.elements = const [],
  });

  factory OcrTextLine.fromJson(Map<String, dynamic> json) {
    return OcrTextLine(
      text: json['text'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      elements:
          (json['elements'] as List<dynamic>?)
              ?.map((e) => OcrTextElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'boundingBox': boundingBox.toJson(),
    'confidence': confidence,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrTextLine &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence &&
          _listEquals(elements, other.elements);

  @override
  int get hashCode =>
      Object.hash(text, boundingBox, confidence, Object.hashAll(elements));

  @override
  String toString() =>
      'OcrTextLine(text: $text, confidence: $confidence, '
      'elements: ${elements.length})';
}

/// Um bloco de texto agrupado espacialmente pelo motor de OCR.
///
/// A block generally corresponds to a paragraph or visual section of receipt.
final class OcrTextBlock {
  final String text;
  final OcrBoundingBox boundingBox;
  final List<OcrTextLine> lines;

  const OcrTextBlock({
    required this.text,
    required this.boundingBox,
    this.lines = const [],
  });

  factory OcrTextBlock.fromJson(Map<String, dynamic> json) {
    return OcrTextBlock(
      text: json['text'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0),
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => OcrTextLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'boundingBox': boundingBox.toJson(),
    'lines': lines.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrTextBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          _listEquals(lines, other.lines);

  @override
  int get hashCode => Object.hash(text, boundingBox, Object.hashAll(lines));

  @override
  String toString() => 'OcrTextBlock(text: $text, lines: ${lines.length})';
}

/// Output document from OCR engine.
///
/// Contains all recognized text blocks with their bounding boxes
/// and confidence levels, plus processed image dimensions.
///
/// It is **serializable** via [fromJson]/[toJson] for test fixture usage:
/// o motor real (ML Kit) produz um [OcrDocument]; os testes do parser usam
/// JSON files — no device required.
///
/// Average confidence ([averageConfidence]) is mean of lines across all
/// blocks. Empty document returns 0.0 (no data = zero confidence).
final class OcrDocument {
  final List<OcrTextBlock> blocks;

  /// Largura da imagem processada em pixels.
  final double imageWidth;

  /// Altura da imagem processada em pixels.
  final double imageHeight;

  /// Mean confidence calculated over all lines in all blocks.
  ///
  /// Returns 0.0 when there are no lines (empty document).
  double get averageConfidence {
    final allLines = lines;
    if (allLines.isEmpty) return 0.0;
    final sum = allLines.fold(0.0, (acc, l) => acc + l.confidence);
    return sum / allLines.length;
  }

  /// Todas as linhas do documento, na ordem em que aparecem nos blocos.
  ///
  /// Atalho para o [ColumnDetector] e o [ReceiptParser]: evita ter que
  /// navegar pela hierarquia bloco → linha em todo lugar.
  List<OcrTextLine> get lines =>
      blocks.expand((b) => b.lines).toList(growable: false);

  OcrDocument({
    List<OcrTextBlock>? blocks,
    List<OcrTextLine>? lines,
    this.imageWidth = 0,
    this.imageHeight = 0,
  }) : blocks =
           blocks ??
           (lines != null && lines.isNotEmpty
               ? [
                   OcrTextBlock(
                     text: lines.map((l) => l.text).join('\n'),
                     boundingBox: _computeEnclosingBox(lines),
                     lines: lines,
                   ),
                 ]
               : const []);

  static OcrBoundingBox _computeEnclosingBox(List<OcrTextLine> lines) {
    if (lines.isEmpty) {
      return const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0);
    }
    var top = lines.first.boundingBox.top;
    var left = lines.first.boundingBox.left;
    var right = lines.first.boundingBox.right;
    var bottom = lines.first.boundingBox.bottom;

    for (var i = 1; i < lines.length; i++) {
      final box = lines[i].boundingBox;
      if (box.top < top) top = box.top;
      if (box.left < left) left = box.left;
      if (box.right > right) right = box.right;
      if (box.bottom > bottom) bottom = box.bottom;
    }
    return OcrBoundingBox(top: top, left: left, right: right, bottom: bottom);
  }

  factory OcrDocument.fromJson(Map<String, dynamic> json) {
    final blocksJson = json['blocks'] as List<dynamic>?;
    final linesJson = json['lines'] as List<dynamic>?;

    final blocks = blocksJson
        ?.map((e) => OcrTextBlock.fromJson(e as Map<String, dynamic>))
        .toList();

    final lines = linesJson
        ?.map((e) => OcrTextLine.fromJson(e as Map<String, dynamic>))
        .toList();

    final width =
        (json['imageWidth'] as num?)?.toDouble() ??
        (json['width'] as num?)?.toDouble() ??
        ((json['imageSize'] as Map<String, dynamic>?)?['width'] as num?)
            ?.toDouble() ??
        0.0;

    final height =
        (json['imageHeight'] as num?)?.toDouble() ??
        (json['height'] as num?)?.toDouble() ??
        ((json['imageSize'] as Map<String, dynamic>?)?['height'] as num?)
            ?.toDouble() ??
        0.0;

    return OcrDocument(
      blocks: blocks,
      lines: lines,
      imageWidth: width,
      imageHeight: height,
    );
  }

  Map<String, dynamic> toJson() => {
    'blocks': blocks.map((e) => e.toJson()).toList(),
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrDocument &&
          runtimeType == other.runtimeType &&
          _listEquals(blocks, other.blocks) &&
          imageWidth == other.imageWidth &&
          imageHeight == other.imageHeight;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(blocks), imageWidth, imageHeight);

  @override
  String toString() =>
      'OcrDocument(blocks: ${blocks.length}, '
      'imageSize: ${imageWidth}x$imageHeight, '
      'averageConfidence: ${averageConfidence.toStringAsFixed(2)})';
}
