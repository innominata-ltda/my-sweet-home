import 'package:my_sweet_home/core/regionalization/regionalization_models.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';

/// Calculates structural quality score to choose the best [ReceiptDraft]
/// across OCR preprocessing attempts or regional receipt parsers.
int scoreReceiptDraft(ReceiptDraft draft, OcrDocument doc) {
  if (doc.lines.isEmpty) return -1000;

  var score = 0;

  if (draft.store.isCnpjValid) {
    score += 40;
  } else if (draft.store.cnpj != null) {
    score += 10;
  }

  if (draft.store.name != null && draft.store.name!.trim().isNotEmpty) {
    score += 15;
  }

  if (draft.purchasedAt != null) {
    score += 15;
  }

  if (draft.total != null && draft.total!.cents > 0) {
    score += 30;
  }

  final selectedItems = draft.items.where((i) => i.selected).toList();
  score += (selectedItems.length * 10).clamp(0, 80);

  // Penalize very low confidence items (likely preprocessing noise)
  final lowConfCount = draft.items.where((i) => i.confidence < 0.6).length;
  score -= (lowConfCount * 15);

  // Big bonus when item sum matches receipt total exactly (RN-196)
  if (draft.items.isNotEmpty &&
      draft.total != null &&
      draft.total!.cents > 0 &&
      !draft.isDivergent()) {
    score += 120;
  }

  score += (draft.confidence * 50).round();
  return score;
}

/// Evaluates one or more regional [ReceiptParser]s and picks the best draft.
final class CompositeReceiptParser implements ReceiptParser {
  final List<ReceiptParser> parsers;

  const CompositeReceiptParser(this.parsers);

  @override
  ReceiptDraft parse(OcrDocument doc) {
    if (parsers.isEmpty) {
      return ReceiptDraft(
        store: const StoreDraft(),
        items: const [],
        confidence: 0.0,
      );
    }

    if (parsers.length == 1) {
      return parsers.first.parse(doc);
    }

    ReceiptDraft? bestDraft;
    var bestScore = -100000;

    for (final parser in parsers) {
      final candidate = parser.parse(doc);
      final candidateScore = scoreReceiptDraft(candidate, doc);
      if (bestDraft == null || candidateScore > bestScore) {
        bestDraft = candidate;
        bestScore = candidateScore;
      }
    }

    return bestDraft!;
  }
}

/// Registry mapping regional receipt format IDs to [ReceiptParser]s.
///
/// Contributors adding a new regional receipt parser register its descriptor in
/// [ReceiptFormatCatalog.descriptors] and its parser instance in [parsers].
final class ReceiptFormatRegistry {
  final Map<String, ReceiptParser> parsers;

  const ReceiptFormatRegistry({
    this.parsers = const {
      ReceiptFormatCatalog.brNfceFormatId: DefaultReceiptParser(),
    },
  });

  /// Resolves a [ReceiptParser] for [formatId], falling back to `auto` mode.
  ReceiptParser resolve(String formatId) {
    if (formatId != ReceiptFormatCatalog.autoFormatId) {
      final explicit = parsers[formatId];
      if (explicit != null) return explicit;
    }
    return CompositeReceiptParser(parsers.values.toList(growable: false));
  }
}
