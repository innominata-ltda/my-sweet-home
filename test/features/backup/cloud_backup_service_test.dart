import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/cloud_backup_service.dart';

import '../../fakes/fake_cloud_storage_port.dart';
import '../../fakes/fake_settings_repository.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Airplane mode active (RNF-005, CA-4.1): no network request allowed without consent.',
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('T-05 — CloudBackupService (RF-007, RN-235, CA-4.1)', () {
    late AppDatabase db;
    late DriftBackupService backupService;
    late FakeCloudStoragePort cloudStoragePort;
    late FakeSettingsRepository settingsRepository;
    late CloudBackupService cloudBackupService;

    setUp(() {
      db = AppDatabase.memory();
      backupService = DriftBackupService(db);
      cloudStoragePort = FakeCloudStoragePort();
      settingsRepository = FakeSettingsRepository();
      cloudBackupService = CloudBackupService(
        backupService: backupService,
        cloudStoragePort: cloudStoragePort,
        settingsRepository: settingsRepository,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> populateTestData() async {
      await db.customStatement('PRAGMA foreign_keys = OFF;');
      try {
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat_cloud',
                name: 'Nuvem e Sync',
                kind: 'expense',
                iconKey: 'cloud',
              ),
            );
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'exp_cloud',
                amountCents: 12000,
                occurredOn: '2026-09-25',
                description: const Value('Assinatura de teste'),
                categoryId: const Value('cat_cloud'),
              ),
            );
      } finally {
        await db.customStatement('PRAGMA foreign_keys = ON;');
      }
    }

    test('CA-4.1 & RN-235 — Consent cloud_backup denied (default): no request or upload is made', () async {
      expect(await settingsRepository.isCloudBackupAllowed(), isFalse);

      await populateTestData();

      final uploadRes = await cloudBackupService.uploadCloudBackup(
        password: 'senha123',
      );
      expect(uploadRes.isErr, isTrue);
      expect(uploadRes.failureOrNull, isA<PermissionFailure>());
      expect(cloudStoragePort.uploadCallCount, equals(0));

      final restoreRes = await cloudBackupService.restoreCloudBackup(
        password: 'senha123',
      );
      expect(restoreRes.isErr, isTrue);
      expect(restoreRes.failureOrNull, isA<PermissionFailure>());
      expect(cloudStoragePort.downloadCallCount, equals(0));

      final listRes = await cloudBackupService.listCloudBackups();
      expect(listRes.isErr, isTrue);
      expect(listRes.failureOrNull, isA<PermissionFailure>());
      expect(cloudStoragePort.listCallCount, equals(0));
    });

    test('RN-234 & RN-235 — With cloud_backup consent enabled: backup is encrypted on client and sent to user cloud', () async {
      await settingsRepository.setCloudBackupAllowed(true);
      expect(await settingsRepository.isCloudBackupAllowed(), isTrue);

      await populateTestData();

      final uploadRes = await cloudBackupService.uploadCloudBackup(
        password: 'senha_forte_cloud',
      );
      expect(uploadRes.isOk, isTrue);
      expect(cloudStoragePort.uploadCallCount, equals(1));

      final storedEncryptedContent =
          cloudStoragePort.remoteFiles['my_sweet_home_backup.enc'];
      expect(storedEncryptedContent, isNotNull);
      expect(
        storedEncryptedContent,
        contains('my_sweet_home_encrypted_backup'),
      );
      expect(storedEncryptedContent, contains('AES-256-GCM'));
      expect(storedEncryptedContent, isNot(contains('Assinatura de teste')));

      // Restaura em um banco novo limpo
      final cleanDb = AppDatabase.memory();
      final cleanBackupService = DriftBackupService(cleanDb);
      final cleanCloudBackupService = CloudBackupService(
        backupService: cleanBackupService,
        cloudStoragePort: cloudStoragePort,
        settingsRepository: settingsRepository,
      );

      try {
        final restoreRes = await cleanCloudBackupService.restoreCloudBackup(
          password: 'senha_forte_cloud',
        );
        expect(restoreRes.isOk, isTrue);
        expect(await cleanDb.categories.count().getSingle(), equals(1));
        expect(await cleanDb.expenses.count().getSingle(), equals(1));
      } finally {
        await cleanDb.close();
      }
    });

    test('CA-3.1 & RN-234 — Cloud restore attempt with incorrect password fails without corrupting local data', () async {
      await settingsRepository.setCloudBackupAllowed(true);
      await populateTestData();

      await cloudBackupService.uploadCloudBackup(password: 'senha_correta');

      final targetDb = AppDatabase.memory();
      final targetBackupService = DriftBackupService(targetDb);
      final targetCloudBackupService = CloudBackupService(
        backupService: targetBackupService,
        cloudStoragePort: cloudStoragePort,
        settingsRepository: settingsRepository,
      );

      try {
        final restoreRes = await targetCloudBackupService.restoreCloudBackup(
          password: 'senha_errada',
        );

        expect(restoreRes.isErr, isTrue);
        expect(restoreRes.failureOrNull, isA<ValidationFailure>());
        expect(await targetDb.categories.count().getSingle(), equals(0));
      } finally {
        await targetDb.close();
      }
    });

    test(
      'Cloud failure propagates network or storage error on upload and restore',
      () async {
        await settingsRepository.setCloudBackupAllowed(true);
        await populateTestData();

        cloudStoragePort.shouldFail = true;

        final uploadRes = await cloudBackupService.uploadCloudBackup(
          password: 'senha123',
        );
        expect(uploadRes.isErr, isTrue);
        expect(uploadRes.failureOrNull, isA<NetworkFailure>());

        final restoreRes = await cloudBackupService.restoreCloudBackup(
          password: 'senha123',
        );
        expect(restoreRes.isErr, isTrue);
        expect(restoreRes.failureOrNull, isA<NetworkFailure>());

        final listRes = await cloudBackupService.listCloudBackups();
        expect(listRes.isErr, isTrue);
        expect(listRes.failureOrNull, isA<NetworkFailure>());
      },
    );

    test('Empty password on upload fails during local encryption stage before any request', () async {
      await settingsRepository.setCloudBackupAllowed(true);
      final uploadRes = await cloudBackupService.uploadCloudBackup(
        password: '',
      );
      expect(uploadRes.isErr, isTrue);
      expect(cloudStoragePort.uploadCallCount, equals(0));
    });

    test(
      'CA-1.5: Backup file over 200 MB is rejected before downloadBackup',
      () async {
        await settingsRepository.setCloudBackupAllowed(true);

        const fileName = 'backup_grande.enc';
        // 250 MB em bytes
        cloudStoragePort.fileSizes[fileName] = 250 * 1024 * 1024;
        cloudStoragePort.remoteFiles[fileName] = 'conteudo';

        final res = await cloudBackupService.restoreCloudBackup(
          password: 'senha',
          fileName: fileName,
        );

        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<ValidationFailure>());
        expect(
          (res.failureOrNull as ValidationFailure).fields['size'],
          contains('excede o tamanho m\u00E1ximo'),
        );
        // CA-1.5: downloadBackup was NOT called
        expect(cloudStoragePort.downloadCallCount, equals(0));
      },
    );

    test(
      'CA-4.6: SecurityLimits customizado (300 MB) aceita arquivo de 250 MB',
      () async {
        await settingsRepository.setCloudBackupAllowed(true);

        const fileName = 'backup_300mb.enc';
        // Encrypts valid data for test
        final encRes = await backupService.exportEncryptedBackup('senha');
        cloudStoragePort.remoteFiles[fileName] = encRes.valueOrNull!;
        cloudStoragePort.fileSizes[fileName] = 250 * 1024 * 1024;

        const customLimits = SecurityLimits(maxBackupBytes: 300 * 1024 * 1024);
        final customService = CloudBackupService(
          backupService: backupService,
          cloudStoragePort: cloudStoragePort,
          settingsRepository: settingsRepository,
          limits: customLimits,
        );

        final res = await customService.restoreCloudBackup(
          password: 'senha',
          fileName: fileName,
        );

        expect(res.isOk, isTrue);
        // downloadBackup FOI chamado pois o arquivo de 250 MB cabe em 300 MB
        expect(cloudStoragePort.downloadCallCount, equals(1));
      },
    );
  });
}
