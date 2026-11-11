import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

import '../test/fakes/fake_household_key_store.dart';
import '../test/fakes/fake_household_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Integração de Sincronização LAN entre dois nós TCP locais (CA-3.1, T-11)',
    (tester) async {
      final dbA = AppDatabase.memory();
      final dbB = AppDatabase.memory();

      const householdId = 'integration-house-1';
      final key = HouseholdKey(
        Uint8List.fromList(List.generate(32, (i) => 99)),
      );
      final now = DateTime.utc(2026, 10, 23, 12);

      // Ativa casa nos dois bancos
      await dbA
          .into(dbA.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa Integração',
              localSiteId: 'site-alpha',
              sharedAreas: 'home,finance,catalog',
              createdAt: now.toIso8601String(),
              joinedAt: now.toIso8601String(),
              active: const drift.Value(true),
            ),
          );
      await dbB
          .into(dbB.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Casa Integração',
              localSiteId: 'site-beta',
              sharedAreas: 'home,finance,catalog',
              createdAt: now.toIso8601String(),
              joinedAt: now.toIso8601String(),
              active: const drift.Value(true),
            ),
          );

      final registry = SyncTableRegistryImpl();

      final transportA = LanSyncTransport(
        householdRepository: FakeHouseholdRepository(
          initialHousehold: Household(
            id: householdId,
            name: 'Casa Integração',
            localSiteId: 'site-alpha',
            sharedAreas: const {SyncArea.home},
            createdAt: now,
            joinedAt: now,
          ),
        ),
        keyStore: FakeHouseholdKeyStore(key),
        changeSource: DriftChangeSource(db: dbA, registry: registry),
        tombstoneStore: TombstoneStore(db: dbA),
        codec: SyncBatchCodecImpl(),
        batchApplier: DriftBatchApplier(
          db: dbA,
          registry: registry,
          changeCapture: ChangeCapture(db: dbA),
        ),
      );

      final transportB = LanSyncTransport(
        householdRepository: FakeHouseholdRepository(
          initialHousehold: Household(
            id: householdId,
            name: 'Casa Integração',
            localSiteId: 'site-beta',
            sharedAreas: const {SyncArea.home},
            createdAt: now,
            joinedAt: now,
          ),
        ),
        keyStore: FakeHouseholdKeyStore(key),
        changeSource: DriftChangeSource(db: dbB, registry: registry),
        tombstoneStore: TombstoneStore(db: dbB),
        codec: SyncBatchCodecImpl(),
        batchApplier: DriftBatchApplier(
          db: dbB,
          registry: registry,
          changeCapture: ChangeCapture(db: dbB),
        ),
      );

      addTearDown(() async {
        transportA.dispose();
        transportB.dispose();
        await dbA.close();
        await dbB.close();
      });

      // Inicia receptor B
      await transportB.start();
      final portB = transportB.listeningPort!;
      expect(portB, greaterThan(0));

      // Conecta A em B
      transportA.registerPeer(
        DiscoveredPeer(siteId: 'site-beta', address: '127.0.0.1', port: portB),
      );

      // Insere tarefa em A
      await dbA
          .into(dbA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-lan-integration',
              title: 'Verificar conexão LAN',
              isCompleted: const drift.Value(false),
              createdAt: drift.Value(now.toIso8601String()),
              updatedAt: drift.Value(now.toIso8601String()),
            ),
          );

      // Trigger sync
      final syncRes = await transportA.syncNow();
      expect(syncRes.isOk, isTrue);

      // Wait for batch application
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Confirm B received the task
      final taskInB = await (dbB.select(
        dbB.tasks,
      )..where((t) => t.id.equals('task-lan-integration'))).getSingleOrNull();
      expect(taskInB, isNotNull);
      expect(taskInB!.title, 'Verificar conexão LAN');
    },
  );
}
