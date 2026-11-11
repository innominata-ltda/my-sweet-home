@Tags(['device'])
library;

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/tasks/data/adapters/google_calendar_adapter.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

class MockCalendarApi extends Mock implements calendar.CalendarApi {}

class MockEventsResource extends Mock implements calendar.EventsResource {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeEvent extends Fake implements calendar.Event {}

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

  setUpAll(() {
    registerFallbackValue(FakeEvent());
  });

  group('GoogleCalendarAdapter', () {
    late MockCalendarApi mockCalendarApi;
    late MockEventsResource mockEventsResource;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockFlutterSecureStorage mockSecureStorage;
    late Map<String, String> inMemoryStorage;
    late GoogleCalendarAdapter adapter;
    final now = DateTime.utc(2026, 10, 4, 12, 0, 0);

    setUp(() {
      mockCalendarApi = MockCalendarApi();
      mockEventsResource = MockEventsResource();
      mockGoogleSignIn = MockGoogleSignIn();
      mockSecureStorage = MockFlutterSecureStorage();
      inMemoryStorage = {};

      when(() => mockCalendarApi.events).thenReturn(mockEventsResource);

      // Simulates in-memory SecureStorage
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

      adapter = GoogleCalendarAdapter(
        googleSignIn: mockGoogleSignIn,
        secureStorage: mockSecureStorage,
        clock: FakeClock(now),
        calendarApi: mockCalendarApi,
        clientId: 'test-client-id.apps.googleusercontent.com',
      );
    });

    test('reads Client ID from parameter or constructor', () {
      expect(
        adapter.clientId,
        equals('test-client-id.apps.googleusercontent.com'),
      );
    });

    test('gerencia armazenamento seguro de tokens (RN-160, RN-158)', () async {
      await adapter.storeTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        expiry: DateTime.utc(2026, 10, 5, 12, 0, 0),
      );

      final token = await adapter.getStoredAccessToken();
      final refresh = await adapter.getStoredRefreshToken();
      final expiry = await adapter.getStoredTokenExpiry();

      expect(token, equals('access_123'));
      expect(refresh, equals('refresh_456'));
      expect(expiry, equals(DateTime.utc(2026, 10, 5, 12, 0, 0)));

      await adapter.clearTokens();

      expect(await adapter.getStoredAccessToken(), null);
      expect(await adapter.getStoredRefreshToken(), null);
      expect(await adapter.getStoredTokenExpiry(), null);
    });

    group('pull', () {
      test(
        'mapeia eventos remotos retornados pelo Google Calendar API v3',
        () async {
          final window = DateTimeRange(
            start: DateTime.utc(2026, 10, 1),
            end: DateTime.utc(2026, 10, 31),
          );

          final mockEvents = calendar.Events(
            items: [
              calendar.Event(
                id: 'event_1',
                etag: '"etag1"',
                summary: 'Comprar pão',
                description: 'Padaria da esquina',
                status: 'confirmed',
                updated: DateTime.utc(2026, 10, 2, 10, 0),
                start: calendar.EventDateTime(
                  dateTime: DateTime.utc(2026, 10, 5, 9, 0),
                ),
              ),
              calendar.Event(
                id: 'event_2',
                etag: '"etag2"',
                summary: 'Dia de limpeza',
                status: 'confirmed',
                updated: DateTime.utc(2026, 10, 3, 10, 0),
                start: calendar.EventDateTime(date: DateTime.utc(2026, 10, 10)),
              ),
            ],
          );

          when(
            () => mockEventsResource.list(
              'primary',
              timeMin: any(named: 'timeMin'),
              timeMax: any(named: 'timeMax'),
              updatedMin: any(named: 'updatedMin'),
              singleEvents: any(named: 'singleEvents'),
              showDeleted: any(named: 'showDeleted'),
            ),
          ).thenAnswer((_) async => mockEvents);

          final result = await adapter.pull(window);

          expect(result.isOk, isTrue);
          final snapshot = result.valueOrNull!;
          expect(snapshot.events.length, equals(2));

          final ev1 = snapshot.events.firstWhere((e) => e.id == 'event_1');
          expect(ev1.summary, equals('Comprar pão'));
          expect(ev1.description, equals('Padaria da esquina'));
          expect(ev1.allDay, isFalse);
          expect(ev1.start, equals(DateTime.utc(2026, 10, 5, 9, 0)));
          expect(ev1.etag, equals('"etag1"'));

          final ev2 = snapshot.events.firstWhere((e) => e.id == 'event_2');
          expect(ev2.summary, equals('Dia de limpeza'));
          expect(ev2.allDay, isTrue);
          expect(ev2.start, equals(DateTime.utc(2026, 10, 10)));
        },
      );

      test('respects updatedMin parameter in incremental pull', () async {
        final window = DateTimeRange(
          start: DateTime.utc(2026, 10, 1),
          end: DateTime.utc(2026, 10, 31),
        );
        final updatedMin = DateTime.utc(2026, 10, 3, 8, 0);

        when(
          () => mockEventsResource.list(
            'primary',
            timeMin: any(named: 'timeMin'),
            timeMax: any(named: 'timeMax'),
            updatedMin: updatedMin,
            singleEvents: true,
            showDeleted: true,
          ),
        ).thenAnswer((_) async => calendar.Events(items: []));

        final result = await adapter.pull(window, updatedMin: updatedMin);

        expect(result.isOk, isTrue);
        verify(
          () => mockEventsResource.list(
            'primary',
            timeMin: window.start.toUtc(),
            timeMax: window.end.toUtc(),
            updatedMin: updatedMin,
            singleEvents: true,
            showDeleted: true,
          ),
        ).called(1);
      });
    });

    group('push', () {
      test(
        'insere evento novo no Google Calendar quando remoteEventId é nulo',
        () async {
          final taskEvent = TaskEvent(
            taskId: 'task_100',
            title: 'Trocar lâmpada',
            description: 'Lâmpada da cozinha',
            start: DateTime.utc(2026, 10, 15, 14, 0),
            allDay: false,
          );

          final returnedGoogleEvent = calendar.Event(
            id: 'google_ev_100',
            etag: '"etag_new"',
            summary: 'Trocar lâmpada',
            description: 'Lâmpada da cozinha',
            status: 'confirmed',
            updated: DateTime.utc(2026, 10, 4, 12, 0),
            start: calendar.EventDateTime(
              dateTime: DateTime.utc(2026, 10, 15, 14, 0),
            ),
          );

          when(() => mockEventsResource.insert(any(), 'primary'))
              .thenAnswer((_) async => returnedGoogleEvent);

          final result = await adapter.push(taskEvent);

          expect(result.isOk, isTrue);
          final remote = result.valueOrNull!;
          expect(remote.id, equals('google_ev_100'));
          expect(remote.etag, equals('"etag_new"'));
          expect(remote.summary, equals('Trocar lâmpada'));
          verify(() => mockEventsResource.insert(any(), 'primary')).called(1);
        },
      );

      test('updates existing event in Google Calendar when remoteEventId is populated', () async {
        final taskEvent = TaskEvent(
          taskId: 'task_100',
          remoteEventId: 'google_ev_100',
          remoteEtag: '"etag_old"',
          title: 'Trocar lâmpada LED',
          start: DateTime.utc(2026, 10, 15),
          allDay: true,
        );

        final returnedGoogleEvent = calendar.Event(
          id: 'google_ev_100',
          etag: '"etag_updated"',
          summary: 'Trocar lâmpada LED',
          status: 'confirmed',
          updated: DateTime.utc(2026, 10, 4, 12, 1),
          start: calendar.EventDateTime(date: DateTime.utc(2026, 10, 15)),
        );

        when(() => mockEventsResource.update(any(), 'primary', 'google_ev_100'))
            .thenAnswer((_) async => returnedGoogleEvent);

        final result = await adapter.push(taskEvent);

        expect(result.isOk, isTrue);
        final remote = result.valueOrNull!;
        expect(remote.id, equals('google_ev_100'));
        expect(remote.etag, equals('"etag_updated"'));
        expect(remote.summary, equals('Trocar lâmpada LED'));
        verify(
          () => mockEventsResource.update(any(), 'primary', 'google_ev_100'),
        ).called(1);
      });
    });

    group('deleteRemote', () {
      test('remove evento remoto chamando delete', () async {
        when(() => mockEventsResource.delete('primary', 'google_ev_100'))
            .thenAnswer((_) async {});

        final result = await adapter.deleteRemote('google_ev_100', '"etag_1"');

        expect(result.isOk, isTrue);
        verify(() => mockEventsResource.delete('primary', 'google_ev_100'))
            .called(1);
      });
    });

    group('tratamento de erros (CalendarFailure)', () {
      test(
        'converte SocketException em CalendarFailure com isNetworkError: true',
        () async {
          final window = DateTimeRange(
            start: DateTime.utc(2026, 10, 1),
            end: DateTime.utc(2026, 10, 31),
          );

          when(
            () => mockEventsResource.list(
              any(),
              timeMin: any(named: 'timeMin'),
              timeMax: any(named: 'timeMax'),
              updatedMin: any(named: 'updatedMin'),
              singleEvents: any(named: 'singleEvents'),
              showDeleted: any(named: 'showDeleted'),
            ),
          ).thenThrow(const SocketException('Sem conexão com a internet'));

          final result = await adapter.pull(window);

          expect(result.isErr, isTrue);
          final failure = result.failureOrNull as CalendarFailure;
          expect(failure.isNetworkError, isTrue);
          expect(failure.message, contains('Sem conexão'));
        },
      );

      test('converte http.ClientException em CalendarFailure com isNetworkError: true', () async {
        final taskEvent = TaskEvent(
          taskId: 't1',
          title: 'Teste',
          allDay: false,
        );

        when(() => mockEventsResource.insert(any(), any()))
            .thenThrow(http.ClientException('Falha HTTP de transporte'));

        final result = await adapter.push(taskEvent);

        expect(result.isErr, isTrue);
        final failure = result.failureOrNull as CalendarFailure;
        expect(failure.isNetworkError, isTrue);
        expect(failure.message, contains('Falha HTTP de transporte'));
      });

      test('converts DetailedApiRequestError 401 to auth CalendarFailure (isNetworkError: false)', () async {
        final window = DateTimeRange(
          start: DateTime.utc(2026, 10, 1),
          end: DateTime.utc(2026, 10, 31),
        );

        final apiError = calendar.DetailedApiRequestError(
          401,
          'Token expirado ou inválido',
        );

        when(
          () => mockEventsResource.list(
            any(),
            timeMin: any(named: 'timeMin'),
            timeMax: any(named: 'timeMax'),
            updatedMin: any(named: 'updatedMin'),
            singleEvents: any(named: 'singleEvents'),
            showDeleted: any(named: 'showDeleted'),
          ),
        ).thenThrow(apiError);

        final result = await adapter.pull(window);

        expect(result.isErr, isTrue);
        final failure = result.failureOrNull as CalendarFailure;
        expect(failure.isNetworkError, isFalse);
        expect(failure.message, contains('401'));
        expect(failure.message, contains('Token expirado'));
      });

      test(
        'trata cancelamento ou indisponibilidade de login do Google',
        () async {
          final adapterWithoutMockApi = GoogleCalendarAdapter(
            googleSignIn: mockGoogleSignIn,
            secureStorage: mockSecureStorage,
            clock: FakeClock(now),
          );

          when(() => mockGoogleSignIn.currentUser).thenReturn(null);
          when(() => mockGoogleSignIn.signInSilently())
              .thenAnswer((_) async => null);
          when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

          final result = await adapterWithoutMockApi.deleteRemote(
            'ev1',
            'etag1',
          );

          expect(result.isErr, isTrue);
          final failure = result.failureOrNull as CalendarFailure;
          expect(failure.isNetworkError, isFalse);
          expect(failure.message, contains('cancelada ou indisponível'));
        },
      );
    });
  });
}
