@Tags(['device'])
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/tasks/data/adapters/google_calendar_adapter.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

import '../../fakes/fake_settings_repository.dart';
import 'sync_executor_test.dart';

class MockCalendarApi extends Mock implements calendar.CalendarApi {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeClock extends Clock {
  final DateTime fixedNow;
  const FakeClock(this.fixedNow);

  @override
  DateTime nowUtc() => fixedNow.toUtc();

  @override
  DateTime nowLocal() => fixedNow.toLocal();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'T-10: Desconectar apaga tokens e preserva tarefas (RN-158, CA-5.1)',
    () {
      late MockCalendarApi mockCalendarApi;
      late MockGoogleSignIn mockGoogleSignIn;
      late MockFlutterSecureStorage mockSecureStorage;
      late Map<String, String> inMemoryStorage;
      late GoogleCalendarAdapter adapter;
      late TestTaskRepository repo;
      late FakeSettingsRepository settingsRepo;
      final now = DateTime.utc(2026, 10, 4, 12, 0, 0);

      setUp(() {
        mockCalendarApi = MockCalendarApi();
        mockGoogleSignIn = MockGoogleSignIn();
        mockSecureStorage = MockFlutterSecureStorage();
        inMemoryStorage = {
          GoogleCalendarAdapter.keyAccessToken: 'valid_access_token',
          GoogleCalendarAdapter.keyRefreshToken: 'valid_refresh_token',
          GoogleCalendarAdapter.keyTokenExpiry: '2026-10-05T12:00:00.000Z',
        };
        repo = TestTaskRepository();
        settingsRepo = FakeSettingsRepository(cloudBackupAllowed: true);

        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((invocation) async {
          final key = invocation.namedArguments[#key] as String;
          final value = invocation.namedArguments[#value] as String?;
          if (value != null) {
            inMemoryStorage[key] = value;
          } else {
            inMemoryStorage.remove(key);
          }
        });

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((invocation) async {
              final key = invocation.namedArguments[#key] as String;
              return inMemoryStorage[key];
            });

        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((invocation) async {
              final key = invocation.namedArguments[#key] as String;
              inMemoryStorage.remove(key);
            });

        when(() => mockGoogleSignIn.disconnect()).thenAnswer((_) async => null);
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        adapter = GoogleCalendarAdapter(
          googleSignIn: mockGoogleSignIn,
          secureStorage: mockSecureStorage,
          clock: FakeClock(now),
          calendarApi: mockCalendarApi,
          clientId: 'test-client-id.apps.googleusercontent.com',
        );
      });

      test(
        'disconnect apaga tokens do flutter_secure_storage (RN-158, CA-5.1)',
        () async {
          expect(await adapter.getStoredAccessToken(), isNotNull);
          expect(await adapter.getStoredRefreshToken(), isNotNull);

          final result = await adapter.disconnect();

          expect(result.isOk, isTrue);
          expect(await adapter.getStoredAccessToken(), isNull);
          expect(await adapter.getStoredRefreshToken(), isNull);
          expect(await adapter.getStoredTokenExpiry(), isNull);
          verify(() => mockGoogleSignIn.disconnect()).called(1);
        },
      );

      test(
        'disconnect chama signOut se googleSignIn.disconnect lançar exceção',
        () async {
          when(() => mockGoogleSignIn.disconnect())
              .thenThrow(Exception('Offline'));

          final result = await adapter.disconnect();

          expect(result.isOk, isTrue);
          expect(await adapter.getStoredAccessToken(), isNull);
          verify(() => mockGoogleSignIn.disconnect()).called(1);
          verify(() => mockGoogleSignIn.signOut()).called(1);
        },
      );

      test('disconnect preserves 100% of tasks in repository and unlinks remote metadata (RN-158, CA-5.1)', () async {
        final task1 = Task(
          id: 't1',
          title: 'Limpar a cozinha',
          notes: 'Com detergente neutro',
          allDay: false,
          isCompleted: false,
          remoteEventId: 'google_ev_1',
          remoteEtag: '"etag1"',
          syncState: SyncState.synced,
          createdAt: now,
          updatedAt: now,
        );

        final task2 = Task(
          id: 't2',
          title: 'Trocar lençol de cama',
          allDay: true,
          isCompleted: true,
          completedAt: now,
          remoteEventId: 'google_ev_2',
          remoteEtag: '"etag2"',
          syncState: SyncState.synced,
          createdAt: now,
          updatedAt: now,
        );

        final task3 = Task(
          id: 't3',
          title: 'Tarefa exclusivamente local',
          allDay: false,
          isCompleted: false,
          syncState: SyncState.dirty,
          createdAt: now,
          updatedAt: now,
        );

        await repo.saveSyncedTask(task1);
        await repo.saveSyncedTask(task2);
        await repo.saveSyncedTask(task3);

        final result = await adapter.disconnect(
          repository: repo,
          settingsRepository: settingsRepo,
        );

        expect(result.isOk, isTrue);

        // Ensure all 3 local tasks remain in repository
        final tasksRes = await repo.allTasksForSync();
        expect(tasksRes.isOk, isTrue);
        final tasks = tasksRes.valueOrNull!;
        expect(tasks.length, equals(3));

        // Verify task1 (preserves local data, unlinks remote IDs)
        final updatedT1 = repo.tasks['t1']!;
        expect(updatedT1.title, equals('Limpar a cozinha'));
        expect(updatedT1.notes, equals('Com detergente neutro'));
        expect(updatedT1.isCompleted, isFalse);
        expect(updatedT1.remoteEventId, isNull);
        expect(updatedT1.remoteEtag, isNull);

        // Verifica task2
        final updatedT2 = repo.tasks['t2']!;
        expect(updatedT2.title, equals('Trocar lençol de cama'));
        expect(updatedT2.isCompleted, isTrue);
        expect(updatedT2.remoteEventId, isNull);
        expect(updatedT2.remoteEtag, isNull);

        // Verifica task3 (permanece inalterada)
        final updatedT3 = repo.tasks['t3']!;
        expect(updatedT3.title, equals('Tarefa exclusivamente local'));
        expect(updatedT3.remoteEventId, isNull);

        // Ensure consent in settings was revoked
        expect(await settingsRepo.isCloudBackupAllowed(), isFalse);
      });

      test('signOut funciona como alias de disconnect (RN-158)', () async {
        final result = await adapter.signOut();

        expect(result.isOk, isTrue);
        expect(await adapter.getStoredAccessToken(), isNull);
        verify(() => mockGoogleSignIn.disconnect()).called(1);
      });
    },
  );
}
