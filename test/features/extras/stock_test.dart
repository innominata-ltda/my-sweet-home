import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' hide StockItem;
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/extras/data/drift_stock_repository.dart';
import 'package:my_sweet_home/features/extras/data/stock_repository_provider.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';
import 'package:my_sweet_home/features/extras/domain/stock_consumption_estimate.dart';
import 'package:my_sweet_home/features/extras/domain/stock_item.dart';
import 'package:my_sweet_home/features/extras/presentation/stock_screen.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_stock_repository.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  group('T-03 — Household Stock FakeRepository (RF-101, RN-251, CA-2.2)', () {
    late FakeStockRepository repository;

    setUp(() {
      FakeStockRepository.clearAlertHistory();
      repository = FakeStockRepository();
    });

    test(
      'RF-101: Registrar quantidade aproximada por produto no estoque',
      () async {
        final quantity = const Quantity(4000, Unit.un);
        final result = await repository.upsertStockItem(
          productId: 'prod-papel',
          quantity: quantity,
        );

        expect(result.isOk, isTrue);
        final item = result.valueOrNull!;
        expect(item.productId, equals('prod-papel'));
        expect(item.quantity.valueMilli, equals(4000));
        expect(item.quantity.unit, equals(Unit.un));

        final fetchResult = await repository.getStockItemByProductId(
          'prod-papel',
        );
        expect(fetchResult.isOk, isTrue);
        expect(fetchResult.valueOrNull, equals(item));
      },
    );

    test(
      'CA-2.2: Given a product with only 2 purchases, no estimate is displayed',
      () async {
        final productId = 'prod-detergente';
        final now = DateTime.now();

        repository.setPurchaseHistory(productId, [
          now.subtract(const Duration(days: 30)),
          now.subtract(const Duration(days: 15)),
        ]);

        await repository.upsertStockItem(
          productId: productId,
          quantity: const Quantity(2000, Unit.un),
        );

        final estimateRes = await repository.getConsumptionEstimate(productId);
        expect(estimateRes.isOk, isTrue);

        final estimate = estimateRes.valueOrNull!;
        expect(estimate.purchaseCount, equals(2));
        expect(estimate.hasEnoughHistory, isFalse);
        expect(estimate.averageIntervalDays, isNull);
        expect(estimate.estimatedDaysRemaining, isNull);
      },
    );

    test(
      'RN-251: Com 3 ou mais compras, estimativa de consumo é calculada',
      () async {
        final productId = 'prod-arroz';
        final now = DateTime.now();

        repository.setPurchaseHistory(productId, [
          now.subtract(const Duration(days: 30)),
          now.subtract(const Duration(days: 20)),
          now.subtract(const Duration(days: 10)),
        ]);

        await repository.upsertStockItem(
          productId: productId,
          quantity: const Quantity(1000, Unit.un),
          lastRestockedAt: now.subtract(const Duration(days: 2)),
        );

        final estimateRes = await repository.getConsumptionEstimate(productId);
        expect(estimateRes.isOk, isTrue);

        final estimate = estimateRes.valueOrNull!;
        expect(estimate.purchaseCount, equals(3));
        expect(estimate.hasEnoughHistory, isTrue);
        expect(estimate.averageIntervalDays, closeTo(10.0, 0.1));
        expect(estimate.estimatedDaysRemaining, isNotNull);
      },
    );

    testWidgets(
      'StockScreen exibe aviso de histórico insuficiente para 2 compras (CA-2.2)',
      (tester) async {
        final productId = 'prod-sabao';
        final now = DateTime.now();

        repository.setPurchaseHistory(productId, [
          now.subtract(const Duration(days: 20)),
          now.subtract(const Duration(days: 10)),
        ]);

        await repository.upsertStockItem(
          productId: productId,
          quantity: const Quantity(3000, Unit.un),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [stockRepositoryProvider.overrideWithValue(repository)],
            child: const MaterialApp(home: StockScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Estoque Doméstico'), findsOneWidget);
        expect(find.text('Produto: prod-sabao'), findsOneWidget);
        expect(
          find.textContaining('Quantidade informada: 3.0 un'),
          findsOneWidget,
        );

        expect(
          find.textContaining('Sem estimativa de consumo'),
          findsOneWidget,
        );
      },
    );

    test('CA-2.1 / RN-251 / RN-252: Product bought 4 times with 21-day average interval and last purchase 19 days ago -> running low and alert emitted without duplicate', () async {
      final productId = 'prod-papel-4x';
      final clock = FakeClock(DateTime.utc(2026, 10, 1, 12, 0));
      final repo = FakeStockRepository(clock);

      final now = clock.nowUtc();
      // 4 purchases with 21-day interval (82d, 61d, 40d, 19d ago)
      repo.setPurchaseHistory(productId, [
        now.subtract(const Duration(days: 82)),
        now.subtract(const Duration(days: 61)),
        now.subtract(const Duration(days: 40)),
        now.subtract(const Duration(days: 19)),
      ]);

      await repo.upsertStockItem(
        productId: productId,
        quantity: const Quantity(4000, Unit.un),
        lastRestockedAt: now.subtract(const Duration(days: 19)),
      );

      // 1st query in period: estimate ok, running low = true, alert emitted = true
      final res1 = await repo.getConsumptionEstimate(productId);
      expect(res1.isOk, isTrue);
      final est1 = res1.valueOrNull!;
      expect(est1.purchaseCount, equals(4));
      expect(est1.hasEnoughHistory, isTrue);
      expect(est1.averageIntervalDays, closeTo(21.0, 0.1));
      expect(est1.estimatedDaysRemaining, equals(2));
      expect(est1.isLowStock, isTrue);
      expect(est1.isAlertIssued, isTrue);

      // 2nd query in same period: running low = true, alert emitted = false (does not repeat)
      final res2 = await repo.getConsumptionEstimate(productId);
      expect(res2.isOk, isTrue);
      final est2 = res2.valueOrNull!;
      expect(est2.isLowStock, isTrue);
      expect(est2.isAlertIssued, isFalse);
    });

    testWidgets(
      'StockScreen exibe indicador "Está acabando" para produto em estoque baixo (CA-2.1)',
      (tester) async {
        final productId = 'prod-cafe';
        final now = DateTime.now();

        repository.setPurchaseHistory(productId, [
          now.subtract(const Duration(days: 63)),
          now.subtract(const Duration(days: 42)),
          now.subtract(const Duration(days: 21)),
          now.subtract(const Duration(days: 19)),
        ]);

        await repository.upsertStockItem(
          productId: productId,
          quantity: const Quantity(1000, Unit.un),
          lastRestockedAt: now.subtract(const Duration(days: 19)),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [stockRepositoryProvider.overrideWithValue(repository)],
            child: const MaterialApp(home: StockScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Estoque Doméstico'), findsOneWidget);
        expect(find.text('Produto: prod-cafe'), findsOneWidget);
        expect(find.text('Está acabando'), findsOneWidget);
      },
    );
  });

  group('T-03 — DriftStockRepository with in-memory SQLite database', () {
    late AppDatabase db;
    late IdGenerator idGen;
    late Clock clock;
    late DriftStockRepository driftRepo;

    setUp(() {
      DriftStockRepository.clearAlertHistory();
      db = AppDatabase(NativeDatabase.memory());
      idGen = SequentialIdGenerator();
      clock = FakeClock(DateTime.utc(2026, 10, 1, 10, 0));
      driftRepo = DriftStockRepository(db, idGen, clock);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Registra, busca, atualiza e exclui item no banco Drift real',
      () async {
        // 1. Inserir produto base
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-1',
                canonicalName: 'Papel Higiênico',
                defaultUnit: 'un',
              ),
            );

        // 2. Upsert estoque
        final upsertRes = await driftRepo.upsertStockItem(
          productId: 'p-1',
          quantity: const Quantity(8000, Unit.un),
        );
        expect(upsertRes.isOk, isTrue);
        final item = upsertRes.valueOrNull!;
        expect(item.productId, equals('p-1'));
        expect(item.quantity.valueMilli, equals(8000));

        // 3. Buscar por productId
        final fetchRes = await driftRepo.getStockItemByProductId('p-1');
        expect(fetchRes.isOk, isTrue);
        expect(fetchRes.valueOrNull?.quantity.valueMilli, equals(8000));

        // 4. Listar
        final listRes = await driftRepo.getStockItems();
        expect(listRes.isOk, isTrue);
        expect(listRes.valueOrNull?.length, equals(1));

        // 5. Excluir
        final delRes = await driftRepo.deleteStockItem(item.id);
        expect(delRes.isOk, isTrue);

        final listAfterRes = await driftRepo.getStockItems();
        expect(listAfterRes.valueOrNull?.isEmpty, isTrue);
      },
    );

    test('CA-2.2 with Drift: Product with 2 purchases returns hasEnoughHistory == false', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p-2',
              canonicalName: 'Detergente',
              defaultUnit: 'un',
            ),
          );

      // Inserir 2 compras
      final nowIso = DateTime.utc(2026, 10, 1).toIso8601String();
      final prevIso = DateTime.utc(2026, 9, 15).toIso8601String();

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-1',
              purchasedAt: prevIso,
              totalCents: 500,
              source: 'manual',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-1',
              purchaseId: 'pur-1',
              productId: const Value('p-2'),
              rawDescription: 'Detergente',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 500,
              totalPriceCents: 500,
              position: 0,
            ),
          );

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-2',
              purchasedAt: nowIso,
              totalCents: 500,
              source: 'manual',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-2',
              purchaseId: 'pur-2',
              productId: const Value('p-2'),
              rawDescription: 'Detergente',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 500,
              totalPriceCents: 500,
              position: 0,
            ),
          );

      final estimateRes = await driftRepo.getConsumptionEstimate('p-2');
      expect(estimateRes.isOk, isTrue);

      final estimate = estimateRes.valueOrNull!;
      expect(estimate.purchaseCount, equals(2));
      expect(estimate.hasEnoughHistory, isFalse);
      expect(estimate.averageIntervalDays, isNull);
    });

    test('CA-2.1 with Drift: 4 purchases with 21-day average interval and last purchase 19 days ago -> running low', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p-3',
              canonicalName: 'Papel Higiênico Multi',
              defaultUnit: 'un',
            ),
          );

      // Purchases: 82d, 61d, 40d, 19d before FakeClock (2026-10-01)
      final purchaseDates = [
        DateTime.utc(2026, 7, 11).toIso8601String(), // 82d ago
        DateTime.utc(2026, 8, 1).toIso8601String(), // 61d ago
        DateTime.utc(2026, 8, 22).toIso8601String(), // 40d ago
        DateTime.utc(2026, 9, 12).toIso8601String(), // 19d ago
      ];

      for (int i = 0; i < purchaseDates.length; i++) {
        final purId = 'pur-p3-$i';
        await db
            .into(db.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: purId,
                purchasedAt: purchaseDates[i],
                totalCents: 1000,
                source: 'manual',
              ),
            );
        await db
            .into(db.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: 'pi-p3-$i',
                purchaseId: purId,
                productId: const Value('p-3'),
                rawDescription: 'Papel Higiênico Multi',
                quantityMilli: 4000,
                unit: 'un',
                unitPriceCents: 1000,
                totalPriceCents: 1000,
                position: 0,
              ),
            );
      }

      await driftRepo.upsertStockItem(
        productId: 'p-3',
        quantity: const Quantity(4000, Unit.un),
        lastRestockedAt: DateTime.utc(2026, 9, 12),
      );

      final res1 = await driftRepo.getConsumptionEstimate('p-3');
      expect(res1.isOk, isTrue);
      final est1 = res1.valueOrNull!;

      expect(est1.purchaseCount, equals(4));
      expect(est1.hasEnoughHistory, isTrue);
      expect(est1.averageIntervalDays, closeTo(21.0, 0.1));
      expect(est1.estimatedDaysRemaining, equals(2));
      expect(est1.isLowStock, isTrue);
      expect(est1.isAlertIssued, isTrue);

      final res2 = await driftRepo.getConsumptionEstimate('p-3');
      expect(res2.isOk, isTrue);
      final est2 = res2.valueOrNull!;
      expect(est2.isLowStock, isTrue);
      expect(est2.isAlertIssued, isFalse);
    });

    test('Drift: Multiple items of same product in same purchase are grouped as 1 purchase', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'p-multi',
              canonicalName: 'Sabão Líquido',
              defaultUnit: 'un',
            ),
          );

      final d1 = DateTime.utc(2026, 8, 1).toIso8601String();
      final d2 = DateTime.utc(2026, 8, 20).toIso8601String();
      final d3 = DateTime.utc(2026, 9, 10).toIso8601String();

      // Compra 1: tem 2 itens do mesmo produto 'p-multi'
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-m1',
              purchasedAt: d1,
              totalCents: 2000,
              source: 'manual',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-m1-a',
              purchaseId: 'pur-m1',
              productId: const Value('p-multi'),
              rawDescription: 'Sabão Líquido A',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 0,
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-m1-b',
              purchaseId: 'pur-m1',
              productId: const Value('p-multi'),
              rawDescription: 'Sabão Líquido B',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 1,
            ),
          );

      // Compra 2
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-m2',
              purchasedAt: d2,
              totalCents: 1000,
              source: 'manual',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-m2',
              purchaseId: 'pur-m2',
              productId: const Value('p-multi'),
              rawDescription: 'Sabão Líquido',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 0,
            ),
          );

      // Compra 3
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-m3',
              purchasedAt: d3,
              totalCents: 1000,
              source: 'manual',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-m3',
              purchaseId: 'pur-m3',
              productId: const Value('p-multi'),
              rawDescription: 'Sabão Líquido',
              quantityMilli: 1000,
              unit: 'un',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 0,
            ),
          );

      final res = await driftRepo.getConsumptionEstimate('p-multi');
      expect(res.isOk, isTrue);
      final est = res.valueOrNull!;
      // Must have exactly 3 purchases (not 4)
      expect(est.purchaseCount, equals(3));
      expect(est.hasEnoughHistory, isTrue);
      expect(est.averageIntervalDays, closeTo(20.0, 0.1));
    });

    test(
      'Reabastecer produto reseta ciclo de alerta para o novo período',
      () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-restock',
                canonicalName: 'Cereal',
                defaultUnit: 'un',
              ),
            );

        // 4 compras com 10 dias de intervalo
        final purchaseDates = [
          DateTime.utc(2026, 8, 20).toIso8601String(),
          DateTime.utc(2026, 8, 30).toIso8601String(),
          DateTime.utc(2026, 9, 9).toIso8601String(),
          DateTime.utc(2026, 9, 19).toIso8601String(),
        ];

        for (int i = 0; i < purchaseDates.length; i++) {
          await db
              .into(db.purchases)
              .insert(
                PurchasesCompanion.insert(
                  id: 'pur-rs-$i',
                  purchasedAt: purchaseDates[i],
                  totalCents: 500,
                  source: 'manual',
                ),
              );
          await db
              .into(db.purchaseItems)
              .insert(
                PurchaseItemsCompanion.insert(
                  id: 'pi-rs-$i',
                  purchaseId: 'pur-rs-$i',
                  productId: const Value('p-restock'),
                  rawDescription: 'Cereal',
                  quantityMilli: 1000,
                  unit: 'un',
                  unitPriceCents: 500,
                  totalPriceCents: 500,
                  position: 0,
                ),
              );
        }

        await driftRepo.upsertStockItem(
          productId: 'p-restock',
          quantity: const Quantity(1000, Unit.un),
          lastRestockedAt: DateTime.utc(2026, 9, 19),
        );

        // FakeClock at 2026-09-28 (9 days after restocking -> 1 day left -> isLowStock = true)
        final customClock = FakeClock(DateTime.utc(2026, 9, 28, 10, 0));
        final repo2 = DriftStockRepository(db, idGen, customClock);

        final res1 = await repo2.getConsumptionEstimate('p-restock');
        expect(res1.valueOrNull?.isLowStock, isTrue);
        expect(res1.valueOrNull?.isAlertIssued, isTrue);

        // Reabastecer hoje (2026-09-28)
        await repo2.upsertStockItem(
          productId: 'p-restock',
          quantity: const Quantity(1000, Unit.un),
          lastRestockedAt: DateTime.utc(2026, 9, 28),
        );

        final res2 = await repo2.getConsumptionEstimate('p-restock');
        expect(res2.valueOrNull?.isLowStock, isFalse);
        expect(res2.valueOrNull?.isAlertIssued, isFalse);
      },
    );
  });

  group('Stock Models e SavingsGoal', () {
    test('StockItem copyWith, operator == e hashCode', () {
      final now = DateTime(2026, 10, 1);
      final item = StockItem(
        id: 's1',
        productId: 'p1',
        quantity: const Quantity(5000, Unit.g),
        lowStockThreshold: const Quantity(1000, Unit.g),
        lastRestockedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final item2 = StockItem(
        id: 's1',
        productId: 'p1',
        quantity: const Quantity(5000, Unit.g),
        lowStockThreshold: const Quantity(1000, Unit.g),
        lastRestockedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(item, equals(item));
      expect(item, equals(item2));
      expect(item.hashCode, equals(item2.hashCode));
      expect(item, isNot(equals('other')));

      final updated = item.copyWith(
        quantity: const Quantity(2000, Unit.g),
        lowStockThreshold: const Quantity(500, Unit.g),
        lastRestockedAt: now.add(const Duration(days: 1)),
        updatedAt: now.add(const Duration(days: 1)),
      );

      expect(updated.quantity.valueMilli, 2000);
      expect(updated.lowStockThreshold?.valueMilli, 500);
      expect(item, isNot(equals(updated)));
    });

    test('StockConsumptionEstimate operator == e hashCode', () {
      const est1 = StockConsumptionEstimate(
        productId: 'p1',
        purchaseCount: 3,
        hasEnoughHistory: true,
        averageIntervalDays: 10.0,
        estimatedDaysRemaining: 5,
        isLowStock: true,
        isAlertIssued: false,
      );

      const est2 = StockConsumptionEstimate(
        productId: 'p1',
        purchaseCount: 3,
        hasEnoughHistory: true,
        averageIntervalDays: 10.0,
        estimatedDaysRemaining: 5,
        isLowStock: true,
        isAlertIssued: false,
      );

      const est3 = StockConsumptionEstimate(
        productId: 'p2',
        purchaseCount: 1,
        hasEnoughHistory: false,
      );

      expect(est1, equals(est1));
      expect(est1, equals(est2));
      expect(est1.hashCode, equals(est2.hashCode));
      expect(est1, isNot(equals(est3)));
      expect(est1, isNot(equals('estimate')));
    });

    test('SavingsGoal copyWith', () {
      final goal = SavingsGoal(
        month: const YearMonth('2026-10'),
        target: const Money(50000),
      );

      final updated = goal.copyWith(
        month: const YearMonth('2026-11'),
        target: const Money(60000),
      );

      expect(updated.month.iso, '2026-11');
      expect(updated.target, const Money(60000));
    });
  });
}
