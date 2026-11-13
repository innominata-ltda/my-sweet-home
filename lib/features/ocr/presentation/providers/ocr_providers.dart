import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/features/ocr/data/ocr_data_providers.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_format_registry.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_item_matcher.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';

export 'package:my_sweet_home/features/ocr/domain/receipt_format_registry.dart'
    show scoreReceiptDraft;

final receiptFormatRegistryProvider = Provider<ReceiptFormatRegistry>((ref) {
  return const ReceiptFormatRegistry();
});

final receiptParserProvider = Provider<ReceiptParser>((ref) {
  final formatId = ref.watch(receiptFormatProvider);
  final registry = ref.watch(receiptFormatRegistryProvider);
  return registry.resolve(formatId);
});

final receiptItemMatcherProvider = Provider<ReceiptItemMatcher>((ref) {
  return const ReceiptItemMatcher();
});

final parseReceiptProvider = FutureProvider.family<ReceiptDraft, String>((
  ref,
  imagePath,
) async {
  final recognizer = ref.watch(textRecognizerProvider);
  final preprocessor = ref.watch(imagePreprocessorProvider);
  final parser = ref.watch(receiptParserProvider);
  final itemMatcher = ref.watch(receiptItemMatcherProvider);

  final file = File(imagePath);
  final origResult = await recognizer.recognizeFile(imagePath);

  ReceiptDraft? bestDraft;
  int bestScore = -10000;

  if (origResult.isOk) {
    final doc = origResult.valueOrNull!;
    final draft = parser.parse(doc);
    bestDraft = draft;
    bestScore = scoreReceiptDraft(draft, doc);
  }

  // If file exists and original draft still has discrepancy, empty items or failed,
  // also try preprocessed version and choose one producing best ReceiptDraft.
  final shouldTryPreprocessed =
      file.existsSync() &&
      (origResult.isErr ||
          bestDraft == null ||
          bestDraft.items.isEmpty ||
          bestDraft.isDivergent() ||
          !bestDraft.store.isCnpjValid);

  if (shouldTryPreprocessed) {
    try {
      final bytes = await file.readAsBytes();
      final prepResult = await preprocessor.prepare(bytes);
      if (prepResult.isOk) {
        final processedDocResult = await recognizer.recognize(
          prepResult.valueOrNull!,
        );
        if (processedDocResult.isOk) {
          final procDoc = processedDocResult.valueOrNull!;
          final procDraft = parser.parse(procDoc);
          final procScore = scoreReceiptDraft(procDraft, procDoc);
          if (bestDraft == null || procScore > bestScore) {
            bestDraft = procDraft;
            bestScore = procScore;
          }
        }
      }
    } catch (_) {
      // Fallback para o resultado da imagem original
    }
  }

  if (bestDraft == null) {
    throw Exception(
      origResult.failureOrNull?.message ?? 'Falha ao reconhecer nota fiscal.',
    );
  }

  var finalDraft = bestDraft;

  // Automatically link recognized items to user catalog (RN-197)
  if (finalDraft.items.isNotEmpty) {
    try {
      final productRepo = ref.read(productRepositoryProvider);
      final indexResult = await productRepo.buildIndex();
      if (indexResult.isOk && indexResult.valueOrNull != null) {
        finalDraft = itemMatcher.matchReceipt(
          finalDraft,
          indexResult.valueOrNull!,
        );
      }
    } catch (_) {
      // Continue with unlinked items if repository unavailable in test context
    }
  }

  return finalDraft;
});
