import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_category_repository.dart';

class SeedLoader {
  const SeedLoader(
    this._db,
    IdGenerator _,
    this._clock, {
    this.deterministicIdGen = const UuidV5DeterministicIdGenerator(),
  });

  final AppDatabase _db;
  final Clock _clock;
  final DeterministicIdGenerator deterministicIdGen;

  static const String currentCatalogVersion = '6';

  Future<Result<void, Failure>> loadIfNeeded() async {
    try {
      await DriftCategoryRepository(_db, _clock).ensureDefaults();

      final setting = await (_db.select(
        _db.settings,
      )..where((tbl) => tbl.key.equals('seed_version'))).getSingleOrNull();
      final catalogSetting =
          await (_db.select(_db.settings)
                ..where((tbl) => tbl.key.equals('seed_catalog_version')))
              .getSingleOrNull();
      if (setting != null &&
          setting.value == '1' &&
          catalogSetting != null &&
          catalogSetting.value == currentCatalogVersion) {
        return const Ok(null);
      }

      final jsonString = await rootBundle.loadString(
        'assets/seed/synonyms.json',
      );
      final data = await _parseSeedJsonInIsolate(jsonString);

      final categories =
          (data['categories'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final products =
          (data['products'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          [];

      // Fix 3: Ensure SeedLoader seeds required Expense default categories
      categories.addAll([
        {
          'id': 'cat_housing',
          'name': 'Housing',
          'kind': 'expense',
          'iconKey': 'home',
        },
        {
          'id': 'cat-moradia',
          'name': 'Moradia',
          'kind': 'expense',
          'iconKey': 'home',
        },
      ]);

      await _db.transaction(() async {
        final now = _clock.nowUtc().toIso8601String();

        // Fix 5: Seed default shopping list
        final existingList = await (_db.select(
          _db.shoppingLists,
        )..where((tbl) => tbl.id.equals('default'))).getSingleOrNull();
        if (existingList == null) {
          await _db
              .into(_db.shoppingLists)
              .insert(
                ShoppingListsCompanion(
                  id: const Value('default'),
                  name: const Value('Lista de Compras'),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }

        final existingCatRows = await _db.select(_db.categories).get();
        final existingCatIds = existingCatRows.map((c) => c.id).toSet();
        final categoriesToInsert = <CategoriesCompanion>[];

        for (final cat in categories) {
          final id = cat['id'] as String;
          if (!existingCatIds.contains(id)) {
            existingCatIds.add(id);
            categoriesToInsert.add(
              CategoriesCompanion(
                id: Value(id),
                name: Value(cat['name'] as String),
                kind: Value(cat['kind'] as String? ?? 'product'),
                iconKey: Value(cat['iconKey'] as String? ?? 'category'),
                isSystem: const Value(true),
              ),
            );
          }
        }

        if (categoriesToInsert.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(_db.categories, categoriesToInsert);
          });
        }

        final existingProductRows = await _db.select(_db.products).get();
        final existingAliasRows = await _db.select(_db.productAliases).get();
        final existingDenialRows = await _db.select(_db.productDenials).get();
        final deniedByProduct = <String, Set<String>>{};
        for (final d in existingDenialRows) {
          deniedByProduct
              .putIfAbsent(d.productId, () => <String>{})
              .add(d.normalizedText);
        }

        final canonicalNormalizedToProductId = <String, String>{
          for (final p in existingProductRows)
            normalizeProductName(p.canonicalName): p.id,
        };
        final aliasByNormalized = <String, ProductAliase>{
          for (final a in existingAliasRows) a.normalizedAlias: a,
        };
        final normalizedToProductId = <String, String>{
          ...canonicalNormalizedToProductId,
          for (final a in existingAliasRows) a.normalizedAlias: a.productId,
        };
        final seenNormalized = normalizedToProductId.keys.toSet();
        final aliasIdsToDelete = <String>[];

        final productsToInsert = <ProductsCompanion>[];
        final aliasesToInsert = <ProductAliasesCompanion>[];

        for (final prod in products) {
          final canonicalName = prod['canonicalName'] as String;
          final categoryId = prod['categoryId'] as String;
          final defaultUnit = prod['defaultUnit'] as String;
          final packageSizeMilli = prod['packageSizeMilli'] as int?;
          final aliases = List<String>.from(
            (prod['aliases'] as List<dynamic>?) ?? [],
          );

          final normalized = normalizeProductName(canonicalName);
          if (normalized.isEmpty) continue;

          String? existingProductId =
              canonicalNormalizedToProductId[normalized];
          if (existingProductId == null) {
            final existingAlias = aliasByNormalized[normalized];
            if (existingAlias != null) {
              if (existingAlias.source != 'seed') {
                existingProductId = existingAlias.productId;
              } else {
                // Previously a 'seed' alias of another canonical product, now promoted to its own product
                aliasIdsToDelete.add(existingAlias.id);
                seenNormalized.remove(normalized);
                normalizedToProductId.remove(normalized);
              }
            }
          }

          final String productId;
          if (existingProductId != null) {
            productId = existingProductId;
            final deniedSet = deniedByProduct[productId] ?? const <String>{};
            if (!seenNormalized.contains(normalized) &&
                !deniedSet.contains(normalized)) {
              seenNormalized.add(normalized);
              normalizedToProductId[normalized] = productId;
              aliasesToInsert.add(
                ProductAliasesCompanion(
                  id: Value(
                    deterministicIdGen.forSeed(
                      'product_alias',
                      '$productId:$normalized',
                    ),
                  ),
                  productId: Value(productId),
                  alias: Value(canonicalName),
                  normalizedAlias: Value(normalized),
                  source: const Value('seed'),
                  createdAt: Value(now),
                ),
              );
            }
          } else {
            productId = deterministicIdGen.forSeed('product', normalized);
            seenNormalized.add(normalized);
            normalizedToProductId[normalized] = productId;
            canonicalNormalizedToProductId[normalized] = productId;

            productsToInsert.add(
              ProductsCompanion(
                id: Value(productId),
                canonicalName: Value(canonicalName),
                categoryId: Value(categoryId),
                defaultUnit: Value(defaultUnit),
                packageSizeMilli: Value(packageSizeMilli),
                isArchived: const Value(false),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

            aliasesToInsert.add(
              ProductAliasesCompanion(
                id: Value(
                  deterministicIdGen.forSeed(
                    'product_alias',
                    '$productId:$normalized',
                  ),
                ),
                productId: Value(productId),
                alias: Value(canonicalName),
                normalizedAlias: Value(normalized),
                source: const Value('seed'),
                createdAt: Value(now),
              ),
            );
          }

          final deniedSet = deniedByProduct[productId] ?? const <String>{};
          for (final alias in aliases) {
            final aliasNorm = normalizeProductName(alias);
            if (aliasNorm.isEmpty || deniedSet.contains(aliasNorm)) continue;
            final existingAlias = aliasByNormalized[aliasNorm];
            if (existingAlias != null &&
                existingAlias.source == 'seed' &&
                existingAlias.productId != productId &&
                !canonicalNormalizedToProductId.containsKey(aliasNorm)) {
              aliasIdsToDelete.add(existingAlias.id);
              seenNormalized.remove(aliasNorm);
            }
            if (!seenNormalized.contains(aliasNorm)) {
              seenNormalized.add(aliasNorm);
              normalizedToProductId[aliasNorm] = productId;
              aliasesToInsert.add(
                ProductAliasesCompanion(
                  id: Value(
                    deterministicIdGen.forSeed(
                      'product_alias',
                      '$productId:$aliasNorm',
                    ),
                  ),
                  productId: Value(productId),
                  alias: Value(alias),
                  normalizedAlias: Value(aliasNorm),
                  source: const Value('seed'),
                  createdAt: Value(now),
                ),
              );
            }
          }
        }

        if (aliasIdsToDelete.isNotEmpty) {
          await (_db.delete(
            _db.productAliases,
          )..where((tbl) => tbl.id.isIn(aliasIdsToDelete))).go();
        }

        if (productsToInsert.isNotEmpty || aliasesToInsert.isNotEmpty) {
          await _db.batch((batch) {
            if (productsToInsert.isNotEmpty) {
              batch.insertAll(_db.products, productsToInsert);
            }
            if (aliasesToInsert.isNotEmpty) {
              batch.insertAll(_db.productAliases, aliasesToInsert);
            }
          });
        }

        if (setting == null) {
          await _db
              .into(_db.settings)
              .insert(
                SettingsCompanion(
                  key: const Value('seed_version'),
                  value: const Value('1'),
                  updatedAt: Value(now),
                ),
              );
        } else {
          await (_db.update(
            _db.settings,
          )..where((tbl) => tbl.key.equals('seed_version'))).write(
            SettingsCompanion(value: const Value('1'), updatedAt: Value(now)),
          );
        }

        if (catalogSetting == null) {
          await _db
              .into(_db.settings)
              .insert(
                SettingsCompanion(
                  key: const Value('seed_catalog_version'),
                  value: const Value(currentCatalogVersion),
                  updatedAt: Value(now),
                ),
              );
        } else {
          await (_db.update(
            _db.settings,
          )..where((tbl) => tbl.key.equals('seed_catalog_version'))).write(
            SettingsCompanion(
              value: const Value(currentCatalogVersion),
              updatedAt: Value(now),
            ),
          );
        }
      });

      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Failed to load seed data', cause: e));
    }
  }
}

Map<String, dynamic> _decodeSeedJson(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _parseSeedJsonInIsolate(String jsonString) {
  return Isolate.run(() => _decodeSeedJson(jsonString));
}

/// Seed database identity remapping migration (T-P01).
///
/// Remaps product IDs and aliases with `source = 'seed'` to deterministic
/// UUID v5, rewriting foreign keys across all dependent tables:
/// - purchase_items
/// - price_points
/// - shopping_items
/// - recipe_ingredients
/// - stock_items
/// - product_denials
/// - product_aliases
/// atomically within a single transaction with `PRAGMA defer_foreign_keys = ON;` (RN-325, CA-5.5).
class SeedIdentityMigration {
  const SeedIdentityMigration(
    this._db, {
    this.deterministicIdGen = const UuidV5DeterministicIdGenerator(),
  });

  final AppDatabase _db;
  final DeterministicIdGenerator deterministicIdGen;

  /// Executes the remapping. Returns the number of remapped products.
  Future<int> remap() async {
    // 1. Get all seed aliases
    final seedAliases = await (_db.select(
      _db.productAliases,
    )..where((tbl) => tbl.source.equals('seed'))).get();

    if (seedAliases.isEmpty) {
      return 0;
    }

    // 2. Map products with seed aliases
    final seedProductIds = seedAliases.map((a) => a.productId).toSet();
    final products = await (_db.select(
      _db.products,
    )..where((tbl) => tbl.id.isIn(seedProductIds))).get();

    final productRemap = <String, String>{}; // oldId -> newId
    for (final p in products) {
      final norm = normalizeProductName(p.canonicalName);
      final newId = deterministicIdGen.forSeed('product', norm);
      if (p.id != newId) {
        productRemap[p.id] = newId;
      }
    }

    // 3. Map seed aliases
    final aliasRemap = <String, String>{}; // oldAliasId -> newAliasId
    for (final a in seedAliases) {
      final targetProductId = productRemap[a.productId] ?? a.productId;
      final newAliasId = deterministicIdGen.forSeed(
        'product_alias',
        '$targetProductId:${a.normalizedAlias}',
      );
      if (a.id != newAliasId) {
        aliasRemap[a.id] = newAliasId;
      }
    }

    if (productRemap.isEmpty && aliasRemap.isEmpty) {
      return 0;
    }

    // 4. Execute remapping transaction
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON;');

      final targetProductIds = productRemap.values.toSet();
      final existingTargetProducts = await (_db.select(
        _db.products,
      )..where((tbl) => tbl.id.isIn(targetProductIds))).get();
      final existingTargetIds = existingTargetProducts.map((p) => p.id).toSet();

      for (final entry in productRemap.entries) {
        final oldId = entry.key;
        final newId = entry.value;

        await _db.customUpdate(
          'UPDATE purchase_items SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.purchaseItems},
        );

        await _db.customUpdate(
          'UPDATE price_points SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.pricePoints},
        );

        await _db.customUpdate(
          'UPDATE shopping_items SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.shoppingItems},
        );

        await _db.customUpdate(
          'UPDATE recipe_ingredients SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.recipeIngredients},
        );

        await _db.customUpdate(
          'UPDATE stock_items SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.stockItems},
        );

        // If newId already exists or has denials, remove duplicates before remapping
        await _db.customUpdate(
          'DELETE FROM product_denials WHERE product_id = ? AND normalized_text IN (SELECT normalized_text FROM product_denials WHERE product_id = ?)',
          variables: [Variable.withString(oldId), Variable.withString(newId)],
          updates: {_db.productDenials},
        );

        await _db.customUpdate(
          'UPDATE product_denials SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.productDenials},
        );

        // If newId already exists or has aliases, remove alias duplicates before remapping
        await _db.customUpdate(
          'DELETE FROM product_aliases WHERE product_id = ? AND normalized_alias IN (SELECT normalized_alias FROM product_aliases WHERE product_id = ?)',
          variables: [Variable.withString(oldId), Variable.withString(newId)],
          updates: {_db.productAliases},
        );

        await _db.customUpdate(
          'UPDATE product_aliases SET product_id = ? WHERE product_id = ?',
          variables: [Variable.withString(newId), Variable.withString(oldId)],
          updates: {_db.productAliases},
        );

        if (existingTargetIds.contains(newId)) {
          // newId already exists in products, so delete the legacy obsolete row
          await _db.customUpdate(
            'DELETE FROM products WHERE id = ?',
            variables: [Variable.withString(oldId)],
            updates: {_db.products},
          );
        } else {
          await _db.customUpdate(
            'UPDATE products SET id = ? WHERE id = ?',
            variables: [Variable.withString(newId), Variable.withString(oldId)],
            updates: {_db.products},
          );
          existingTargetIds.add(newId);
        }
      }

      for (final entry in aliasRemap.entries) {
        final oldAliasId = entry.key;
        final newAliasId = entry.value;

        // If oldAliasId was already deleted (in deduplication above), skip
        final oldRow = await (_db.select(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(oldAliasId))).getSingleOrNull();
        if (oldRow == null) continue;

        // If newAliasId already exists in aliases table, delete duplicated oldAliasId
        final existingAliasWithNewId = await (_db.select(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(newAliasId))).getSingleOrNull();

        if (existingAliasWithNewId != null) {
          await (_db.delete(
            _db.productAliases,
          )..where((tbl) => tbl.id.equals(oldAliasId))).go();
        } else {
          await _db.customUpdate(
            'UPDATE product_aliases SET id = ? WHERE id = ?',
            variables: [
              Variable.withString(newAliasId),
              Variable.withString(oldAliasId),
            ],
            updates: {_db.productAliases},
          );
        }
      }
    });

    return productRemap.length;
  }
}
