import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/features/bills/data/sync/bills_derived_data_rebuilder.dart';
import 'package:my_sweet_home/features/prices/data/sync/prices_derived_data_rebuilder.dart';
import 'package:my_sweet_home/features/tasks/data/sync/tasks_derived_data_rebuilder.dart';

class _MockNotificationScheduler implements NotificationSchedulerPort {
  final List<ScheduledNotification> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<Result<void, Failure>> schedule(ScheduledNotification n) async {
    scheduled.add(n);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> cancel(String id) async {
    cancelled.add(id);
    return const Ok(null);
  }

  @override
  Future<List<ScheduledNotification>> pending() async => scheduled;

  @override
  Future<PermissionState> permission() async => PermissionState.granted;

  @override
  Future<Result<void, Failure>> rescheduleAllAfterBoot() async =>
      const Ok(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _MockNotificationScheduler scheduler;

  setUp(() async {
    db = AppDatabase.memory();
    scheduler = _MockNotificationScheduler();
  });

  tearDown(() async {
    await db.close();
  });

  group('PricesDerivedDataRebuilder (RN-327, CA-5.6)', () {
    test(
      'recalcula price_points a partir de compras e itens recebidos',
      () async {
        const now = '2026-10-22T10:00:00.000Z';

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-leite',
                canonicalName: 'Leite Integral 1L',
                defaultUnit: 'l',
              ),
            );

        await db
            .into(db.stores)
            .insert(
              StoresCompanion.insert(
                id: 'store-1',
                name: 'Supermercado Central',
              ),
            );

        await db
            .into(db.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: 'purch-1',
                storeId: const Value('store-1'),
                purchasedAt: now,
                totalCents: 900,
                source: 'manual',
              ),
            );

        await db
            .into(db.purchaseItems)
            .insert(
              PurchaseItemsCompanion.insert(
                id: 'pi-1',
                purchaseId: 'purch-1',
                productId: const Value('prod-leite'),
                rawDescription: 'Leite 1L',
                quantityMilli: 1000,
                unit: 'l',
                unitPriceCents: 450,
                totalPriceCents: 900,
                position: 1,
              ),
            );

        // Antes do rebuilder: nenhum price_point
        expect(await db.pricePoints.count().getSingle(), equals(0));

        final rebuilder = PricesDerivedDataRebuilder(db);
        final result = await rebuilder.rebuild({'pi-1'});
        expect(result.isOk, isTrue);

        // After rebuilder: price_point generated with calculated normalized price!
        final points = await db.select(db.pricePoints).get();
        expect(points, hasLength(1));
        final pp = points.first;
        expect(pp.productId, equals('prod-leite'));
        expect(pp.storeId, equals('store-1'));
        expect(pp.purchaseItemId, equals('pi-1'));
        expect(pp.normalizedPriceCents, equals(900));
        expect(pp.unit, equals('l'));
      },
    );

    test('removes corresponding price_point if purchase is deleted', () async {
      const now = '2026-10-22T10:00:00.000Z';

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-1',
              canonicalName: 'Arroz',
              defaultUnit: 'kg',
            ),
          );

      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'purch-del',
              purchasedAt: now,
              totalCents: 1000,
              source: 'manual',
              deletedAt: const Value(now), // Compra na lixeira
            ),
          );

      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'pi-del',
              purchaseId: 'purch-del',
              productId: const Value('prod-1'),
              rawDescription: 'Arroz 1kg',
              quantityMilli: 1000,
              unit: 'kg',
              unitPriceCents: 1000,
              totalPriceCents: 1000,
              position: 1,
            ),
          );

      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp_purch-del_pi-del',
              productId: const Value('prod-1'),
              purchaseItemId: const Value('pi-del'),
              observedAt: now,
              unitPriceCents: 1000,
              normalizedPriceCents: 1000,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'purchase',
            ),
          );

      expect(await db.pricePoints.count().getSingle(), equals(1));

      final rebuilder = PricesDerivedDataRebuilder(db);
      await rebuilder.rebuild({'pi-del'});

      // Price point was removed because purchase was deleted
      expect(await db.pricePoints.count().getSingle(), equals(0));
    });
  });

  group('BillsDerivedDataRebuilder (RN-327, CA-5.4)', () {
    test('schedules notifications for pending payment of active bill', () async {
      final futureDue = DateTime.now().add(const Duration(days: 5));
      final dueIso =
          '${futureDue.year}-${futureDue.month.toString().padLeft(2, '0')}-${futureDue.day.toString().padLeft(2, '0')}';

      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill-luz',
              title: 'Conta de Energia',
              amountCents: const Value(15000),
              isAmountVariable: false,
              dueDay: futureDue.day,
              reminderDaysBefore: const Value(2),
              isActive: const Value(true),
            ),
          );

      await db
          .into(db.billPayments)
          .insert(
            BillPaymentsCompanion.insert(
              id: 'pay-luz-01',
              billId: const Value('bill-luz'),
              dueOn: dueIso,
              amountCents: const Value(15000),
              status: 'pending',
            ),
          );

      final rebuilder = BillsDerivedDataRebuilder(db: db, scheduler: scheduler);

      final result = await rebuilder.rebuild({'pay-luz-01'});
      expect(result.isOk, isTrue);

      // Scheduled notifications
      expect(scheduler.scheduled, isNotEmpty);
      expect(
        scheduler.scheduled.any((n) => n.id.startsWith('pay-luz-01')),
        isTrue,
      );
    });

    test('cancels notifications if payment is marked as paid', () async {
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill-net',
              title: 'Internet',
              amountCents: const Value(12000),
              isAmountVariable: false,
              dueDay: 15,
            ),
          );

      await db
          .into(db.billPayments)
          .insert(
            BillPaymentsCompanion.insert(
              id: 'pay-net-paid',
              billId: const Value('bill-net'),
              dueOn: '2026-10-15',
              amountCents: const Value(12000),
              status: 'paid',
              paidOn: const Value('2026-10-14T12:00:00.000Z'),
            ),
          );

      final rebuilder = BillsDerivedDataRebuilder(db: db, scheduler: scheduler);

      await rebuilder.rebuild({'pay-net-paid'});

      expect(scheduler.cancelled, contains('pay-net-paid_advance'));
      expect(scheduler.cancelled, contains('pay-net-paid_due'));
    });
  });

  group('TasksDerivedDataRebuilder (RN-327)', () {
    test('schedules notification for pending task with due_at', () async {
      final due = DateTime.now().add(const Duration(days: 2)).toUtc();

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-clean',
              title: 'Limpar a casa',
              dueAt: Value(due.toIso8601String()),
              allDay: const Value(false),
            ),
          );

      final rebuilder = TasksDerivedDataRebuilder(db: db, scheduler: scheduler);

      final result = await rebuilder.rebuild({'task-clean'});
      expect(result.isOk, isTrue);

      expect(scheduler.scheduled, isNotEmpty);
      expect(scheduler.scheduled.first.id, equals('task_task-clean'));
    });

    test('cancels notification if task is completed', () async {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-done',
              title: 'Lavar roupas',
              dueAt: const Value('2026-10-25T14:00:00.000Z'),
              isCompleted: const Value(true),
            ),
          );

      final rebuilder = TasksDerivedDataRebuilder(db: db, scheduler: scheduler);

      await rebuilder.rebuild({'task-done'});

      expect(scheduler.cancelled, contains('task_task-done'));
    });
  });

  group('Integration with BatchApplier and rebuilders (RN-327, CA-5.6)', () {
    test(
      'applying sync batch automatically recalculates derived data',
      () async {
        const now = '2026-10-22T10:00:00.000Z';

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-sync',
                canonicalName: 'Caf\u00E9 Torrado 500g',
                defaultUnit: 'g',
              ),
            );

        final pricesRebuilder = PricesDerivedDataRebuilder(db);
        final tasksRebuilder = TasksDerivedDataRebuilder(
          db: db,
          scheduler: scheduler,
        );

        final applier = DriftBatchApplier(
          db: db,
          rebuilders: [pricesRebuilder, tasksRebuilder],
        );

        final hlc1 = Hlc.parse('2026-10-22T10:00:00.000Z:00001:site-b');
        final hlc2 = Hlc.parse('2026-10-22T10:00:00.000Z:00002:site-b');

        final taskDue = DateTime.now().add(const Duration(days: 3)).toUtc();

        final batch = SyncBatch(
          householdId: 'hh-1',
          fromSiteId: 'site-b',
          senderVector: VersionVector({'site-b': hlc2}),
          changes: [
            // 1. Compra remota com item
            ColumnVersion(
              table: 'stores',
              rowId: 'store-sync',
              column: 'name',
              value: 'Mercado Remoto',
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'purchases',
              rowId: 'purch-sync',
              column: 'store_id',
              value: 'store-sync',
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'purchases',
              rowId: 'purch-sync',
              column: 'purchased_at',
              value: now,
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'purchases',
              rowId: 'purch-sync',
              column: 'total_cents',
              value: 1500,
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'purchases',
              rowId: 'purch-sync',
              column: 'source',
              value: 'manual',
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'purchase_id',
              value: 'purch-sync',
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'product_id',
              value: 'prod-sync',
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'raw_description',
              value: 'Cafe 500g',
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'quantity_milli',
              value: 500,
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'unit',
              value: 'g',
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'unit_price_cents',
              value: 1500,
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'total_price_cents',
              value: 1500,
              hlc: hlc2,
            ),
            ColumnVersion(
              table: 'purchase_items',
              rowId: 'pi-sync',
              column: 'position',
              value: 1,
              hlc: hlc2,
            ),
            // 2. Tarefa remota com vencimento
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-sync',
              column: 'title',
              value: 'Trocar filtro de \u00E1gua',
              hlc: hlc1,
            ),
            ColumnVersion(
              table: 'tasks',
              rowId: 'task-sync',
              column: 'due_at',
              value: taskDue.toIso8601String(),
              hlc: hlc1,
            ),
          ],
        );

        final applyRes = await applier.apply(batch);
        expect(applyRes.isOk, isTrue);

        // 1. Derived price point was generated automatically!
        final pricePoints = await db.select(db.pricePoints).get();
        expect(pricePoints, hasLength(1));
        expect(pricePoints.first.purchaseItemId, equals('pi-sync'));
        expect(pricePoints.first.productId, equals('prod-sync'));

        // 2. Task notification was scheduled automatically!
        expect(scheduler.scheduled, isNotEmpty);
        expect(
          scheduler.scheduled.any((n) => n.id == 'task_task-sync'),
          isTrue,
        );
      },
    );
  });
}
