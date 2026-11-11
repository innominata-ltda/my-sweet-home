library;

import 'package:my_sweet_home/core/quantity/quantity.dart';

typedef ProductId = String;
typedef CategoryId = String;
typedef MergeReceiptId = String;

class Product {
  const Product({
    required this.id,
    required this.canonicalName,
    required this.categoryId,
    required this.defaultUnit,
    this.packageSizeMilli,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final ProductId id;
  final String canonicalName;
  final CategoryId categoryId;
  final Unit defaultUnit;
  final int? packageSizeMilli;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class NewProduct {
  const NewProduct({
    required this.canonicalName,
    required this.categoryId,
    required this.defaultUnit,
    this.packageSizeMilli,
  });

  final String canonicalName;
  final CategoryId categoryId;
  final Unit defaultUnit;
  final int? packageSizeMilli;
}

enum AliasSource { seed, user, ocr }

class ProductAlias {
  const ProductAlias({
    required this.id,
    required this.productId,
    required this.alias,
    required this.normalizedAlias,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final ProductId productId;
  final String alias;
  final String normalizedAlias;
  final AliasSource source;
  final DateTime createdAt;
}

class AliasConflict {
  const AliasConflict({required this.alias, required this.existingProductId});

  final String alias;
  final ProductId existingProductId;
}

class MergeReceipt {
  const MergeReceipt({
    required this.id,
    required this.mergedProductId,
    required this.archivedProductId,
  });

  final MergeReceiptId id;
  final ProductId mergedProductId;
  final ProductId archivedProductId;
}
