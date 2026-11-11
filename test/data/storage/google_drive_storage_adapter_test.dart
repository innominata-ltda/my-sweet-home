import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/storage/google_drive_storage_adapter.dart';

class MockDriveApi extends Mock implements drive.DriveApi {}

class MockFilesResource extends Mock implements drive.FilesResource {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeDriveFile extends Fake implements drive.File {}

class FakeMedia extends Fake implements drive.Media {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDriveFile());
    registerFallbackValue(FakeMedia());
    registerFallbackValue(drive.DownloadOptions.fullMedia);
  });

  group('GoogleDriveStorageAdapter (ADR-0011, RF-127, RN-235)', () {
    late MockDriveApi mockDriveApi;
    late MockFilesResource mockFiles;
    late GoogleDriveStorageAdapter adapter;

    setUp(() {
      mockDriveApi = MockDriveApi();
      mockFiles = MockFilesResource();
      when(() => mockDriveApi.files).thenReturn(mockFiles);

      adapter = GoogleDriveStorageAdapter(driveApi: mockDriveApi);
    });

    test(
      'listBackups returns list of non-deleted backup file names from drive',
      () async {
        final fileList = drive.FileList(
          files: [
            drive.File(id: '1', name: 'sync_house1_site1_100.syncbatch'),
            drive.File(id: '2', name: 'sync_house1_site2_200.syncbatch'),
          ],
        );

        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(named: 'q'),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer((_) async => fileList);

        final result = await adapter.listBackups();

        expect(result.isOk, isTrue);
        expect(result.valueOrNull, [
          'sync_house1_site1_100.syncbatch',
          'sync_house1_site2_200.syncbatch',
        ]);
      },
    );

    test('uploadBackup creates new remote file when it does not exist yet in cloud', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(named: 'q'),
          $fields: any(named: r'$fields'),
        ),
      ).thenAnswer((_) async => drive.FileList(files: []));

      when(
        () => mockFiles.create(any(), uploadMedia: any(named: 'uploadMedia')),
      ).thenAnswer((_) async => drive.File(id: 'new_id'));

      final result = await adapter.uploadBackup(
        fileName: 'sync_house1_site1_100.syncbatch',
        encryptedContent: 'base64_encrypted_payload',
      );

      expect(result.isOk, isTrue);
      verify(
        () => mockFiles.create(
          any(
            that: isA<drive.File>().having(
              (f) => f.name,
              'name',
              'sync_house1_site1_100.syncbatch',
            ),
          ),
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).called(1);
    });

    test('uploadBackup updates file when it already exists', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(named: 'q'),
          $fields: any(named: r'$fields'),
        ),
      ).thenAnswer(
        (_) async => drive.FileList(
          files: [drive.File(id: 'existing_id', name: 'backup.json')],
        ),
      );

      when(
        () => mockFiles.update(
          any(),
          any(),
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).thenAnswer((_) async => drive.File(id: 'existing_id'));

      final result = await adapter.uploadBackup(
        fileName: 'backup.json',
        encryptedContent: 'updated_payload',
      );

      expect(result.isOk, isTrue);
      verify(
        () => mockFiles.update(
          any(),
          'existing_id',
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).called(1);
    });

    test('downloadBackup downloads decoded content successfully', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(named: 'q'),
          $fields: any(named: r'$fields'),
        ),
      ).thenAnswer(
        (_) async => drive.FileList(
          files: [drive.File(id: 'file_123', name: 'test.syncbatch')],
        ),
      );

      final payloadBytes = utf8.encode('meu_conteudo_cifrado');
      final media = drive.Media(
        Stream.value(payloadBytes),
        payloadBytes.length,
      );

      when(
        () => mockFiles.get(
          'file_123',
          downloadOptions: any(named: 'downloadOptions'),
        ),
      ).thenAnswer((_) async => media);

      final result = await adapter.downloadBackup(fileName: 'test.syncbatch');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 'meu_conteudo_cifrado');
    });

    test(
      'downloadBackup returns StorageFailure when file does not exist',
      () async {
        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(named: 'q'),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer((_) async => drive.FileList(files: []));

        final result = await adapter.downloadBackup(
          fileName: 'inexistente.syncbatch',
        );

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      },
    );

    test('uploadBackup trata SocketException retornando NetworkFailure(isOffline: true)', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(named: 'q'),
          $fields: any(named: r'$fields'),
        ),
      ).thenThrow(const SocketException('Sem internet'));

      final result = await adapter.uploadBackup(
        fileName: 'teste.syncbatch',
        encryptedContent: 'content',
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect((result.failureOrNull! as NetworkFailure).isOffline, isTrue);
    });

    test(
      'persists and retrieves auth tokens via FlutterSecureStorage (T-B01)',
      () async {
        final mockStorage = MockFlutterSecureStorage();
        final inMemory = <String, String>{};

        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((inv) async {
          final k = inv.namedArguments[#key] as String;
          final v = inv.namedArguments[#value] as String;
          inMemory[k] = v;
        });

        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer(
          (inv) async => inMemory[inv.namedArguments[#key] as String],
        );

        when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer(
          (inv) async => inMemory.remove(inv.namedArguments[#key] as String),
        );

        final secureAdapter = GoogleDriveStorageAdapter(
          driveApi: mockDriveApi,
          secureStorage: mockStorage,
        );

        final expiry = DateTime.utc(2026, 12, 31, 23, 59);
        await secureAdapter.storeTokens(
          accessToken: 'oauth_access_token_123',
          refreshToken: 'oauth_refresh_token_456',
          expiry: expiry,
        );

        expect(
          await secureAdapter.getStoredAccessToken(),
          'oauth_access_token_123',
        );
        expect(
          await secureAdapter.getStoredRefreshToken(),
          'oauth_refresh_token_456',
        );
        expect(await secureAdapter.getStoredTokenExpiry(), expiry);

        await secureAdapter.clearTokens();
        expect(await secureAdapter.getStoredAccessToken(), isNull);
        expect(await secureAdapter.getStoredRefreshToken(), isNull);
        expect(await secureAdapter.getStoredTokenExpiry(), isNull);
      },
    );

    test(
      'creates dedicated visible folder if not existing yet and caches it',
      () async {
        final mockStorage = MockFlutterSecureStorage();
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        // Simula busca por pasta retornando vazia
        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(
              named: 'q',
              that: contains(GoogleDriveStorageAdapter.syncFolderName),
            ),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer((_) async => drive.FileList(files: []));

        // Simulates folder creation
        when(
          () => mockFiles.create(
            any(
              that: isA<drive.File>().having(
                (f) => f.name,
                'name',
                GoogleDriveStorageAdapter.syncFolderName,
              ),
            ),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer(
          (_) async => drive.File(
            id: 'created_folder_id',
            name: GoogleDriveStorageAdapter.syncFolderName,
          ),
        );

        // Simula listagem dentro da pasta
        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(
              named: 'q',
              that: contains("'created_folder_id' in parents"),
            ),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer(
          (_) async =>
              drive.FileList(files: [drive.File(name: 'sync_1.syncbatch')]),
        );

        final folderAdapter = GoogleDriveStorageAdapter(
          driveApi: mockDriveApi,
          secureStorage: mockStorage,
        );

        final res = await folderAdapter.listBackups();
        expect(res.isOk, isTrue);
        expect(res.valueOrNull, ['sync_1.syncbatch']);
        expect(folderAdapter.cachedFolderId, 'created_folder_id');
      },
    );

    test(
      'DetailedApiRequestError 401 limpa tokens e cache do DriveApi',
      () async {
        final mockStorage = MockFlutterSecureStorage();
        final inMemory = <String, String>{
          GoogleDriveStorageAdapter.keyAccessToken: 'expired_token',
        };

        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer(
          (inv) async => inMemory[inv.namedArguments[#key] as String],
        );
        when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer(
          (inv) async => inMemory.remove(inv.namedArguments[#key] as String),
        );

        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(named: 'q'),
            $fields: any(named: r'$fields'),
          ),
        ).thenThrow(drive.DetailedApiRequestError(401, 'Unauthorized'));

        final testAdapter = GoogleDriveStorageAdapter(
          driveApi: mockDriveApi,
          secureStorage: mockStorage,
        );

        final res = await testAdapter.listBackups();
        expect(res.isErr, isTrue);
        expect(testAdapter.cachedDriveApi, isNull);
        expect(inMemory[GoogleDriveStorageAdapter.keyAccessToken], isNull);
      },
    );

    test('listBackups filtra subpastas na query do Google Drive', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(
            named: 'q',
            that: contains("mimeType != 'application/vnd.google-apps.folder'"),
          ),
          $fields: any(named: r'$fields'),
        ),
      ).thenAnswer(
        (_) async => drive.FileList(files: [drive.File(name: 'backup1.json')]),
      );

      final res = await adapter.listBackups();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull, ['backup1.json']);
    });

    test('backupSizeBytes returns file size in sync folder', () async {
      when(
        () => mockFiles.list(
          spaces: any(named: 'spaces'),
          q: any(named: 'q', that: contains("name = 'backup.enc'")),
          $fields: any(named: r'$fields'),
        ),
      ).thenAnswer(
        (_) async => drive.FileList(
          files: [drive.File(id: 'f-1', name: 'backup.enc', size: '1048576')],
        ),
      );

      final res = await adapter.backupSizeBytes(fileName: 'backup.enc');
      expect(res.isOk, isTrue);
      expect(res.valueOrNull, 1048576);
    });

    test(
      'backupSizeBytes returns StorageFailure when file does not exist',
      () async {
        when(
          () => mockFiles.list(
            spaces: any(named: 'spaces'),
            q: any(named: 'q'),
            $fields: any(named: r'$fields'),
          ),
        ).thenAnswer((_) async => drive.FileList(files: []));

        final res = await adapter.backupSizeBytes(fileName: 'missing.enc');
        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<StorageFailure>());
      },
    );
  });
}
