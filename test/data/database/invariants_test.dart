import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';

void main() {
  group('Invariantes de Banco de Dados (INV-1, INV-2, INV-3)', () {
    late AppDatabase db;

    setUp(() async {
      final fixtureFile = File('test/fixtures/db/v1.sqlite');
      if (fixtureFile.existsSync()) {
        final tempDir = Directory.systemTemp.createTempSync('drift_inv_test');
        final dbFile = File('${tempDir.path}/app.db');
        fixtureFile.copySync(dbFile.path);
        db = AppDatabase(LazyDatabase(() async => NativeDatabase(dbFile)));
      } else {
        db = AppDatabase.memory();
      }
    });

    tearDown(() async {
      await db.close();
    });

    test('INV-1: total_price_cents = round(quantity_milli * unit_price_cents / 1000)', () async {
      // Cria registros adicionais para ter certeza
      final pId = 'pur_1';
      final piId = 'pi_1';

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: pId,
              purchasedAt: '2026-09-25T10:00:00Z',
              totalCents: 1000,
              source: 'manual',
            ),
          );

      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: piId,
              purchaseId: pId,
              rawDescription: 'Teste',
              quantityMilli: 1234, // 1.234 kg
              unit: 'kg',
              unitPriceCents: 4567, // 45.67
              totalPriceCents:
                  5636, // round(1234 * 4567 / 1000) = 5635.678 -> 5636
              position: 1,
            ),
          );

      final items = await db.select(db.purchaseItems).get();
      for (final item in items) {
        final expected = (item.quantityMilli * item.unitPriceCents / 1000)
            .round();
        final diff = (item.totalPriceCents - expected).abs();
        expect(
          diff,
          lessThanOrEqualTo(1),
          reason: 'Item ${item.id} violou INV-1',
        );
      }
    });

    test(
      'INV-2: SUM(total_price_cents) - discount_cents = purchases.total_cents',
      () async {
        final pId = 'pur_2';

        await db
            .into(db.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: pId,
                purchasedAt: '2026-09-25T10:00:00Z',
                totalCents: 900,
                discountCents: const Value(100),
                source: 'manual',
              ),
            );

        await db
            .into(db.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: 'pi_2_1',
                purchaseId: pId,
                rawDescription: 'Item 1',
                quantityMilli: 1000,
                unit: 'un',
                unitPriceCents: 500,
                totalPriceCents: 500,
                position: 1,
              ),
            );

        await db
            .into(db.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: 'pi_2_2',
                purchaseId: pId,
                rawDescription: 'Item 2',
                quantityMilli: 1000,
                unit: 'un',
                unitPriceCents: 500,
                totalPriceCents: 500,
                position: 2,
              ),
            );

        final purchases = await db.select(db.purchases).get();
        for (final purchase in purchases) {
          final itemsQuery = db.select(db.purchaseItems)
            ..where((t) => t.purchaseId.equals(purchase.id));
          final items = await itemsQuery.get();
          if (items.isEmpty) continue; // Skip if no items

          final sum = items.fold<int>(
            0,
            (prev, element) => prev + element.totalPriceCents,
          );
          final expectedTotal = sum - purchase.discountCents;

          expect(
            purchase.totalCents,
            equals(expectedTotal),
            reason: 'Compra ${purchase.id} violou INV-2',
          );
        }
      },
    );

    test('INV-3: Todo price_point aponta para um purchase_item existente ou tem source = manual', () async {
      final pId = 'pur_3';
      final piId = 'pi_3';

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: pId,
              purchasedAt: '2026-09-25T10:00:00Z',
              totalCents: 1000,
              source: 'manual',
            ),
          );

      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: piId,
              purchaseId: pId,
              rawDescription: 'Teste',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 1,
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp_1',
              observedAt: '2026-09-25T10:00:00Z',
              unitPriceCents: 1000,
              normalizedPriceCents: 1000,
              quantityMilli: 1000,
              unit: 'un',
              purchaseItemId: Value(piId),
              source: 'ocr',
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp_2',
              observedAt: '2026-09-25T10:00:00Z',
              unitPriceCents: 2000,
              normalizedPriceCents: 2000,
              quantityMilli: 1000,
              unit: 'un',
              source: 'manual', // sem purchase_item
            ),
          );

      final points = await db.select(db.pricePoints).get();
      for (final point in points) {
        if (point.source != 'manual') {
          expect(
            point.purchaseItemId != null,
            isTrue,
            reason:
                'Price point ${point.id} tem source = ${point.source} mas sem purchaseItemId (violou INV-3)',
          );

          final item =
              await (db.select(db.purchaseItems)
                    ..where((t) => t.id.equals(point.purchaseItemId!)))
                  .getSingleOrNull();
          expect(
            item != null,
            isTrue,
            reason:
                'Price point ${point.id} aponta para item inexistente (violou INV-3)',
          );
        }
      }
    });
  });
}
