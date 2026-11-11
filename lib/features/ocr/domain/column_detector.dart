import 'dart:math' as math;

import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Zona de alinhamento horizontal de um segmento no documento de OCR.
enum OcrColumnZone {
  /// Left column (code, product description, store name).
  left,

  /// Center column (quantity, unit, unit price, e.g. "1 UN X 10.00").
  middle,

  /// Right column (total value, right-aligned prices).
  right,
}

/// Um segmento horizontal de texto dentro de uma [OcrRow] pertencente a uma zona de coluna.
final class OcrColumnSegment {
  final String text;
  final OcrBoundingBox boundingBox;
  final OcrColumnZone zone;
  final double confidence;
  final List<OcrTextElement> elements;

  const OcrColumnSegment({
    required this.text,
    required this.boundingBox,
    required this.zone,
    required this.confidence,
    this.elements = const [],
  });

  factory OcrColumnSegment.fromJson(Map<String, dynamic> json) {
    return OcrColumnSegment(
      text: json['text'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0),
      zone: OcrColumnZone.values.firstWhere(
        (z) => z.name == (json['zone'] as String?),
        orElse: () => OcrColumnZone.left,
      ),
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
    'zone': zone.name,
    'confidence': confidence,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrColumnSegment &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          zone == other.zone &&
          confidence == other.confidence &&
          _listEquals(elements, other.elements);

  @override
  int get hashCode => Object.hash(
    text,
    boundingBox,
    zone,
    confidence,
    Object.hashAll(elements),
  );

  @override
  String toString() =>
      'OcrColumnSegment(text: "$text", zone: ${zone.name}, confidence: ${confidence.toStringAsFixed(2)})';
}

/// Visual text line in a receipt, formed by geometric grouping
/// de linhas ([OcrTextLine]) e elementos ([OcrTextElement]) que compartilham alinhamento vertical.
final class OcrRow {
  /// Visual line index in document (0-indexed top to bottom).
  final int rowIndex;

  /// Caixa delimitadora que envolve todos os elementos da linha visual.
  final OcrBoundingBox boundingBox;

  /// OCR lines composing this visual line, ordered from left to right.
  final List<OcrTextLine> lines;

  /// Elementos de texto ([OcrTextElement]) ordenados da esquerda para a direita.
  final List<OcrTextElement> elements;

  /// Segmentos de coluna identificados nesta linha visual.
  final List<OcrColumnSegment> segments;

  /// Complete visual line text reconstituted with proper spacing.
  final String text;

  /// Mean confidence of elements/lines belonging to this visual line.
  final double averageConfidence;

  const OcrRow({
    required this.rowIndex,
    required this.boundingBox,
    required this.lines,
    required this.elements,
    required this.segments,
    required this.text,
    required this.averageConfidence,
  });

  /// Returns right segment (price/total column), if present.
  OcrColumnSegment? get rightSegment {
    for (final seg in segments.reversed) {
      if (seg.zone == OcrColumnZone.right) return seg;
    }
    return null;
  }

  /// Returns left segment (description/code), if present.
  OcrColumnSegment? get leftSegment {
    for (final seg in segments) {
      if (seg.zone == OcrColumnZone.left) return seg;
    }
    return null;
  }

  /// Returns center segment (quantity/unit), if present.
  OcrColumnSegment? get middleSegment {
    for (final seg in segments) {
      if (seg.zone == OcrColumnZone.middle) return seg;
    }
    return null;
  }

  factory OcrRow.fromJson(Map<String, dynamic> json) {
    return OcrRow(
      rowIndex: (json['rowIndex'] as num?)?.toInt() ?? 0,
      boundingBox: json['boundingBox'] != null
          ? OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0),
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => OcrTextLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elements:
          (json['elements'] as List<dynamic>?)
              ?.map((e) => OcrTextElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => OcrColumnSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      text: json['text'] as String? ?? '',
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'rowIndex': rowIndex,
    'boundingBox': boundingBox.toJson(),
    'lines': lines.map((e) => e.toJson()).toList(),
    'elements': elements.map((e) => e.toJson()).toList(),
    'segments': segments.map((e) => e.toJson()).toList(),
    'text': text,
    'averageConfidence': averageConfidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrRow &&
          runtimeType == other.runtimeType &&
          rowIndex == other.rowIndex &&
          boundingBox == other.boundingBox &&
          _listEquals(lines, other.lines) &&
          _listEquals(elements, other.elements) &&
          _listEquals(segments, other.segments) &&
          text == other.text &&
          averageConfidence == other.averageConfidence;

  @override
  int get hashCode => Object.hash(
    rowIndex,
    boundingBox,
    Object.hashAll(lines),
    Object.hashAll(elements),
    Object.hashAll(segments),
    text,
    averageConfidence,
  );

  @override
  String toString() =>
      'OcrRow(#$rowIndex, text: "$text", segments: ${segments.length})';
}

/// Geometric column and row detector for receipts.
///
/// Agrupa elementos/linhas de um [OcrDocument] por geometria vertical (mesma linha/row)
/// e horizontal (colunas da esquerda, centro e direita).
final class ColumnDetector {
  /// Vertical overlap threshold (0.0 to 1.0) to group lines in same visual row.
  final double verticalOverlapThreshold;

  /// Right column boundary ratio (0.0 to 1.0) relative to total document width.
  final double rightColumnRatio;

  /// Left column boundary ratio (0.0 to 1.0) relative to total document width.
  final double leftColumnRatio;

  /// Minimum horizontal distance (in pixels) to separate elements into distinct columns.
  final double minGapPixels;

  const ColumnDetector({
    this.verticalOverlapThreshold = 0.4,
    this.rightColumnRatio = 0.65,
    this.leftColumnRatio = 0.55,
    this.minGapPixels = 20.0,
  });

  /// Processa um [OcrDocument] e retorna as linhas visuais ([OcrRow]) agrupadas por geometria.
  List<OcrRow> detectRows(OcrDocument doc) {
    if (doc.lines.isEmpty) return const [];
    return groupLinesIntoRows(doc.lines, imageWidth: doc.imageWidth);
  }

  /// Groups a list of [OcrTextLine] into visual rows ([OcrRow]) based on geometry.
  List<OcrRow> groupLinesIntoRows(
    List<OcrTextLine> inputLines, {
    double imageWidth = 0,
  }) {
    if (inputLines.isEmpty) return const [];

    final orientedLines = _deskewAndOrientLines(inputLines);
    final effectiveWidth = _calculateEffectiveWidth(
      orientedLines,
      orientedLines == inputLines ? imageWidth : 0,
    );

    // Ordenar linhas pela coordenada Y central
    final sortedLines = List<OcrTextLine>.from(orientedLines)
      ..sort((a, b) {
        final cyA = (a.boundingBox.top + a.boundingBox.bottom) / 2;
        final cyB = (b.boundingBox.top + b.boundingBox.bottom) / 2;
        return cyA.compareTo(cyB);
      });

    // Group lines into best visual row (avoiding snowball effect and horizontal overlap)
    final lineGroups = <List<OcrTextLine>>[];
    for (final line in sortedLines) {
      int bestGroupIdx = -1;
      double bestScore = -1.0;

      for (var gIdx = 0; gIdx < lineGroups.length; gIdx++) {
        final group = lineGroups[gIdx];
        final score = _groupMatchScore(line, group);
        if (score > bestScore) {
          bestScore = score;
          bestGroupIdx = gIdx;
        }
      }

      if (bestGroupIdx >= 0 && bestScore > 0) {
        lineGroups[bestGroupIdx].add(line);
      } else {
        lineGroups.add([line]);
      }
    }

    // Order groups by average vertical position
    lineGroups.sort((a, b) {
      final topA = _averageTop(a);
      final topB = _averageTop(b);
      return topA.compareTo(topB);
    });

    final rows = <OcrRow>[];
    for (var i = 0; i < lineGroups.length; i++) {
      final group = lineGroups[i];

      // Ordenar linhas dentro do grupo da esquerda para a direita (left)
      group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      // Extrair e ordenar elementos
      final elements = _extractAndSortElements(group);

      final enclosingBox = _computeEnclosingBoxForLines(group);

      final segments = _detectSegments(
        elements: elements,
        lines: group,
        documentWidth: effectiveWidth,
      );

      final reconstructedText = _reconstructText(elements, segments);

      final avgConf = _computeAverageConfidence(elements, group);

      rows.add(
        OcrRow(
          rowIndex: i,
          boundingBox: enclosingBox,
          lines: group,
          elements: elements,
          segments: segments,
          text: reconstructedText,
          averageConfidence: avgConf,
        ),
      );
    }

    // Additional semantic check for upside-down photos when elements lack individual rotation
    if (_isSemanticsUpsideDown(rows)) {
      final reversed = rows.reversed.toList();
      return [
        for (var i = 0; i < reversed.length; i++)
          OcrRow(
            rowIndex: i,
            boundingBox: reversed[i].boundingBox,
            lines: reversed[i].lines,
            elements: reversed[i].elements,
            segments: reversed[i].segments,
            text: reversed[i].text,
            averageConfidence: reversed[i].averageConfidence,
          ),
      ];
    }

    return rows;
  }

  /// Corrects tilt/skew and rotation (e.g. 180 deg) estimating dominant text reading angle.
  List<OcrTextLine> _deskewAndOrientLines(List<OcrTextLine> inputLines) {
    final angles = <(double dx, double dy, double angle)>[];
    var sumDx = 0.0;
    var sumDy = 0.0;

    for (final line in inputLines) {
      if (line.elements.length < 2) continue;
      final first = line.elements.first.boundingBox;
      final last = line.elements.last.boundingBox;
      final cx0 = (first.left + first.right) / 2;
      final cy0 = (first.top + first.bottom) / 2;
      final cx1 = (last.left + last.right) / 2;
      final cy1 = (last.top + last.bottom) / 2;
      final dx = cx1 - cx0;
      final dy = cy1 - cy0;
      if (dx * dx + dy * dy < 100.0) continue;
      final ang = math.atan2(dy, dx);
      angles.add((dx, dy, ang));
      sumDx += dx;
      sumDy += dy;
    }

    if (angles.isEmpty) return inputLines;

    final initialTheta = math.atan2(sumDy, sumDx);
    var inlierDx = 0.0;
    var inlierDy = 0.0;
    for (final (dx, dy, ang) in angles) {
      final diff = math.atan2(
        math.sin(ang - initialTheta),
        math.cos(ang - initialTheta),
      );
      if (diff.abs() <= 0.35) {
        inlierDx += dx;
        inlierDy += dy;
      }
    }

    final theta = (inlierDx == 0 && inlierDy == 0)
        ? initialTheta
        : math.atan2(inlierDy, inlierDx);

    if (theta.abs() < 0.003) {
      return inputLines;
    }

    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    final swapWH = sinT.abs() > cosT.abs();

    OcrBoundingBox rotateBox(OcrBoundingBox b) {
      final cx = (b.left + b.right) / 2;
      final cy = (b.top + b.bottom) / 2;
      final w = swapWH ? b.height : b.width;
      final h = swapWH ? b.width : b.height;
      final rcx = cx * cosT + cy * sinT;
      final rcy = -cx * sinT + cy * cosT;
      return OcrBoundingBox(
        top: rcy - h / 2,
        left: rcx - w / 2,
        right: rcx + w / 2,
        bottom: rcy + h / 2,
      );
    }

    final rotatedTemp = <OcrTextLine>[];
    var minX = double.infinity;
    var minY = double.infinity;

    for (final line in inputLines) {
      final rotElements = <OcrTextElement>[];
      for (final el in line.elements) {
        final rb = rotateBox(el.boundingBox);
        if (rb.left < minX) minX = rb.left;
        if (rb.top < minY) minY = rb.top;
        rotElements.add(
          OcrTextElement(
            text: el.text,
            boundingBox: rb,
            confidence: el.confidence,
          ),
        );
      }

      final lineBox = rotElements.isNotEmpty
          ? _computeEnclosingBoxForElements(rotElements)
          : rotateBox(line.boundingBox);
      if (lineBox.left < minX) minX = lineBox.left;
      if (lineBox.top < minY) minY = lineBox.top;

      rotatedTemp.add(
        OcrTextLine(
          text: line.text,
          boundingBox: lineBox,
          confidence: line.confidence,
          elements: rotElements,
        ),
      );
    }

    final shiftX = (minX.isFinite && minX < 0) ? -minX : 0.0;
    final shiftY = (minY.isFinite && minY < 0) ? -minY : 0.0;
    if (shiftX == 0.0 && shiftY == 0.0) {
      return rotatedTemp;
    }

    OcrBoundingBox shiftBox(OcrBoundingBox b) => OcrBoundingBox(
      top: b.top + shiftY,
      left: b.left + shiftX,
      right: b.right + shiftX,
      bottom: b.bottom + shiftY,
    );

    return [
      for (final line in rotatedTemp)
        OcrTextLine(
          text: line.text,
          boundingBox: shiftBox(line.boundingBox),
          confidence: line.confidence,
          elements: [
            for (final el in line.elements)
              OcrTextElement(
                text: el.text,
                boundingBox: shiftBox(el.boundingBox),
                confidence: el.confidence,
              ),
          ],
        ),
    ];
  }

  bool _isSemanticsUpsideDown(List<OcrRow> rows) {
    if (rows.length < 6) return false;
    int firstHeaderIdx = -1;
    int lastFooterIdx = -1;

    for (var i = 0; i < rows.length; i++) {
      final u = rows[i].text.toUpperCase();
      if (firstHeaderIdx < 0 &&
          (u.contains('DOCUMENTO AUXILIAR') ||
              u.contains('DANFE') ||
              (u.contains('CNPJ') && !u.contains('CONSUMIDOR')))) {
        firstHeaderIdx = i;
      }
      if (u.contains('PROTOCOLO DE AUTORIZ') ||
          u.contains('CHAVE DE ACESSO') ||
          u.contains('TRIBUTOS TOTAIS INCIDENTES')) {
        if (lastFooterIdx < 0) {
          lastFooterIdx = i;
        }
      }
    }

    return firstHeaderIdx > rows.length * 0.6 &&
        lastFooterIdx >= 0 &&
        lastFooterIdx < rows.length * 0.4;
  }

  double _calculateEffectiveWidth(List<OcrTextLine> lines, double imageWidth) {
    if (imageWidth > 0) return imageWidth;
    double maxRight = 0;
    for (final line in lines) {
      if (line.boundingBox.right > maxRight) {
        maxRight = line.boundingBox.right;
      }
    }
    return maxRight;
  }

  /// Returns score > 0 if [line] belongs to [group], or -1.0 otherwise.
  double _groupMatchScore(OcrTextLine line, List<OcrTextLine> group) {
    final lineBox = line.boundingBox;

    // 1. Two lines that significantly overlap horizontally are stacked vertically
    for (final existing in group) {
      final exBox = existing.boundingBox;
      final overlapLeft = math.max(lineBox.left, exBox.left);
      final overlapRight = math.min(lineBox.right, exBox.right);
      final overlapWidth = math.max(0.0, overlapRight - overlapLeft);
      final minWidth = math.min(lineBox.width, exBox.width);
      if (minWidth > 0 && overlapWidth / minWidth > 0.25) {
        return -1.0;
      }
    }

    // 2. Compare vertically with nearest horizontal neighbor in group (avoids union box snowball)
    OcrTextLine refLine = group.first;
    double bestHorizDist = double.infinity;
    for (final existing in group) {
      final exBox = existing.boundingBox;
      final dist = lineBox.left >= exBox.right
          ? lineBox.left - exBox.right
          : (exBox.left >= lineBox.right ? exBox.left - lineBox.right : 0.0);
      if (dist < bestHorizDist) {
        bestHorizDist = dist;
        refLine = existing;
      }
    }

    final refBox = refLine.boundingBox;
    final refHeight = refBox.height;
    final lineHeight = lineBox.height;

    if (refHeight <= 0 && lineHeight <= 0) {
      return refBox.top == lineBox.top ? 1.0 : -1.0;
    }

    final overlapTop = math.max(refBox.top, lineBox.top);
    final overlapBottom = math.min(refBox.bottom, lineBox.bottom);
    final overlapHeight = math.max(0.0, overlapBottom - overlapTop);

    final minHeight = math.min(
      lineHeight > 0 ? lineHeight : refHeight,
      refHeight > 0 ? refHeight : lineHeight,
    );
    if (minHeight <= 0) return -1.0;

    final overlapRatio = overlapHeight / minHeight;
    final refCenterY = (refBox.top + refBox.bottom) / 2;
    final lineCenterY = (lineBox.top + lineBox.bottom) / 2;
    final centerDiff = (refCenterY - lineCenterY).abs();

    if (overlapRatio < verticalOverlapThreshold &&
        centerDiff > (minHeight * 0.45)) {
      return -1.0;
    }

    return 1.0 / (1.0 + centerDiff / minHeight);
  }

  double _averageTop(List<OcrTextLine> lines) {
    if (lines.isEmpty) return 0.0;
    final sum = lines.fold(0.0, (acc, l) => acc + l.boundingBox.top);
    return sum / lines.length;
  }

  List<OcrTextElement> _extractAndSortElements(List<OcrTextLine> group) {
    final elements = <OcrTextElement>[];
    for (final line in group) {
      if (line.elements.isNotEmpty) {
        elements.addAll(line.elements);
      } else {
        elements.add(
          OcrTextElement(
            text: line.text,
            boundingBox: line.boundingBox,
            confidence: line.confidence,
          ),
        );
      }
    }
    elements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    return elements;
  }

  OcrBoundingBox _computeEnclosingBoxForLines(List<OcrTextLine> lines) {
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

  List<OcrColumnSegment> _detectSegments({
    required List<OcrTextElement> elements,
    required List<OcrTextLine> lines,
    required double documentWidth,
  }) {
    if (elements.isEmpty) return const [];

    final clusters = <List<OcrTextElement>>[];
    var currentCluster = <OcrTextElement>[elements.first];

    for (var i = 1; i < elements.length; i++) {
      final prev = elements[i - 1];
      final curr = elements[i];

      final gap = curr.boundingBox.left - prev.boundingBox.right;
      final isSignificantGap = gap >= minGapPixels;

      if (isSignificantGap) {
        clusters.add(currentCluster);
        currentCluster = [curr];
      } else {
        currentCluster.add(curr);
      }
    }
    clusters.add(currentCluster);

    final segments = <OcrColumnSegment>[];
    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final text = cluster.map((e) => e.text).join(' ').trim();
      final box = _computeEnclosingBoxForElements(cluster);
      final zone = _classifyZone(box, documentWidth, clusters.length, i);
      final avgConf =
          cluster.fold(0.0, (s, e) => s + e.confidence) / cluster.length;

      segments.add(
        OcrColumnSegment(
          text: text,
          boundingBox: box,
          zone: zone,
          confidence: avgConf,
          elements: cluster,
        ),
      );
    }

    return segments;
  }

  OcrColumnZone _classifyZone(
    OcrBoundingBox box,
    double documentWidth,
    int totalClusters,
    int clusterIndex,
  ) {
    if (documentWidth > 0) {
      if (box.left >= documentWidth * rightColumnRatio) {
        return OcrColumnZone.right;
      }
      if (clusterIndex == 0) {
        if (totalClusters == 1 && box.left >= documentWidth * leftColumnRatio) {
          return OcrColumnZone.right;
        }
        return OcrColumnZone.left;
      }
      if (clusterIndex == totalClusters - 1) {
        if (box.left >= documentWidth * leftColumnRatio) {
          return OcrColumnZone.right;
        }
        return OcrColumnZone.middle;
      }
      return OcrColumnZone.middle;
    }

    if (totalClusters == 1) return OcrColumnZone.left;
    if (clusterIndex == 0) return OcrColumnZone.left;
    if (clusterIndex == totalClusters - 1) return OcrColumnZone.right;
    return OcrColumnZone.middle;
  }

  OcrBoundingBox _computeEnclosingBoxForElements(
    List<OcrTextElement> elements,
  ) {
    if (elements.isEmpty) {
      return const OcrBoundingBox(top: 0, left: 0, right: 0, bottom: 0);
    }
    var top = elements.first.boundingBox.top;
    var left = elements.first.boundingBox.left;
    var right = elements.first.boundingBox.right;
    var bottom = elements.first.boundingBox.bottom;

    for (var i = 1; i < elements.length; i++) {
      final box = elements[i].boundingBox;
      if (box.top < top) top = box.top;
      if (box.left < left) left = box.left;
      if (box.right > right) right = box.right;
      if (box.bottom > bottom) bottom = box.bottom;
    }
    return OcrBoundingBox(top: top, left: left, right: right, bottom: bottom);
  }

  String _reconstructText(
    List<OcrTextElement> elements,
    List<OcrColumnSegment> segments,
  ) {
    if (segments.isNotEmpty) {
      return segments.map((s) => s.text).join(' ');
    }
    return elements.map((e) => e.text).join(' ');
  }

  double _computeAverageConfidence(
    List<OcrTextElement> elements,
    List<OcrTextLine> lines,
  ) {
    if (elements.isNotEmpty) {
      return elements.fold(0.0, (acc, e) => acc + e.confidence) /
          elements.length;
    }
    if (lines.isNotEmpty) {
      return lines.fold(0.0, (acc, l) => acc + l.confidence) / lines.length;
    }
    return 1.0;
  }
}
