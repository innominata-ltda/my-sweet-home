import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

/// Use case to confirm product link read by OCR and save alias (RN-199, CA-3.3).
///
/// Saves text read from receipt ([rawDescription]) as canonical product alias in
/// [ProductRepository] com a origem [AliasSource.ocr].
class ConfirmReceiptMatchUseCase {
  final ProductRepository _productRepository;

  const ConfirmReceiptMatchUseCase(this._productRepository);

  /// Saves alias of individual item when link is confirmed (RN-199).
  ///
  /// The [rawText] read by OCR becomes an alias for [productId] with [AliasSource.ocr].
  Future<Result<Product, Failure>> confirmSingleMatch({
    required ProductId productId,
    required String rawText,
  }) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'rawText': 'Texto do OCR não pode ser vazio.'},
        ),
      );
    }
    return _productRepository.addAlias(productId, trimmed, AliasSource.ocr);
  }

  /// Confirms and persists aliases with [AliasSource.ocr] for all selected items
  /// having product link ([ProductMatch]) in a [ReceiptDraft] (RN-199, CA-3.3).
  Future<Result<List<Product>, Failure>> confirmDraftMatches(
    ReceiptDraft draft,
  ) async {
    final updatedProducts = <Product>[];

    for (final item in draft.items) {
      if (item.selected && item.match != null) {
        final res = await confirmSingleMatch(
          productId: item.match!.product.id,
          rawText: item.rawDescription,
        );
        if (res.isErr) {
          return Err(res.failureOrNull!);
        }
        updatedProducts.add(res.valueOrNull!);
      }
    }

    return Ok(updatedProducts);
  }
}
