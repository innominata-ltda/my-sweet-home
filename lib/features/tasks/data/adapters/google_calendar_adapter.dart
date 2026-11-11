import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/tasks/domain/calendar_gateway_port.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

/// Custom HTTP client to attach OAuth headers (Access Token).
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleAuthClient(this._headers, [http.Client? client])
    : _client = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Adapter real que implementa [CalendarGatewayPort] utilizando `googleapis` (Google Calendar API v3)
/// e `google_sign_in`, armazenando tokens de forma segura no `flutter_secure_storage` (RN-160).
class GoogleCalendarAdapter implements CalendarGatewayPort {
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final Clock clock;
  final calendar.CalendarApi? _injectedCalendarApi;
  final String? _clientId;

  static const String keyAccessToken = 'google_calendar_access_token';
  static const String keyRefreshToken = 'google_calendar_refresh_token';
  static const String keyTokenExpiry = 'google_calendar_token_expiry';

  // ignore: prefer_initializing_formals
  GoogleCalendarAdapter({
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
    this.clock = const SystemClock(),
    calendar.CalendarApi? calendarApi,
    String? clientId,
  }) : _injectedCalendarApi = calendarApi,
       _clientId = clientId ?? _resolveClientId(),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             serverClientId: clientId ?? _resolveClientId(),
             scopes: [calendar.CalendarApi.calendarEventsScope],
           ),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Tries to resolve Google OAuth Client ID from environment variable.
  static String? _resolveClientId() {
    if (Platform.environment.containsKey('GOOGLE_OAUTH_CLIENT_ID_ANDROID')) {
      final val = Platform.environment['GOOGLE_OAUTH_CLIENT_ID_ANDROID'];
      if (val != null && val.isNotEmpty) return val;
    }
    const fromEnv = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_ANDROID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return null;
  }

  /// Retorna o Client ID OAuth configurado.
  String? get clientId => _clientId;

  /// Armazena tokens em `FlutterSecureStorage` sem plain text (RN-160).
  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    await _secureStorage.write(key: keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: keyRefreshToken, value: refreshToken);
    }
    if (expiry != null) {
      await _secureStorage.write(
        key: keyTokenExpiry,
        value: expiry.toUtc().toIso8601String(),
      );
    }
  }

  /// Reads securely stored access token.
  Future<String?> getStoredAccessToken() async {
    return _secureStorage.read(key: keyAccessToken);
  }

  /// Reads securely stored refresh token.
  Future<String?> getStoredRefreshToken() async {
    return _secureStorage.read(key: keyRefreshToken);
  }

  /// Reads stored token expiration.
  Future<DateTime?> getStoredTokenExpiry() async {
    final raw = await _secureStorage.read(key: keyTokenExpiry);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  /// Limpa todos os tokens do armazenamento seguro (RN-158).
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: keyAccessToken);
    await _secureStorage.delete(key: keyRefreshToken);
    await _secureStorage.delete(key: keyTokenExpiry);
  }

  /// Returns a functional instance of Google Calendar API.
  Future<calendar.CalendarApi> _getCalendarApi() async {
    if (_injectedCalendarApi != null) {
      return _injectedCalendarApi;
    }

    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();

    if (account == null) {
      throw const FormatException(
        'Autenticação com Google cancelada ou indisponível',
      );
    }

    final authHeaders = await account.authHeaders;
    final token = authHeaders['Authorization']?.replaceAll('Bearer ', '');
    if (token != null && token.isNotEmpty) {
      await storeTokens(accessToken: token);
    }

    final authClient = GoogleAuthClient(authHeaders);
    return calendar.CalendarApi(authClient);
  }

  /// Executes an API action handling authentication, expiration and network errors.
  Future<Result<T, CalendarFailure>> _execute<T>(
    Future<T> Function(calendar.CalendarApi api) action,
  ) async {
    try {
      final api = await _getCalendarApi();
      final result = await action(api);
      return Ok(result);
    } on calendar.DetailedApiRequestError catch (e) {
      final isAuth = e.status == 401 || e.status == 403;
      return Err(
        CalendarFailure(
          isAuth
              ? 'Erro de autenticação no Google Calendar (${e.status}): ${e.message}'
              : 'Erro na API do Google Calendar (${e.status}): ${e.message}',
        ),
      );
    } on SocketException catch (e) {
      return Err(
        CalendarFailure(
          'Erro de rede ao comunicar com Google Calendar: ${e.message}',
          isNetworkError: true,
        ),
      );
    } on http.ClientException catch (e) {
      return Err(
        CalendarFailure(
          'Erro de rede na requisição HTTP: ${e.message}',
          isNetworkError: true,
        ),
      );
    } on TimeoutException catch (e) {
      return Err(
        CalendarFailure(
          'Tempo limite excedido na comunicação com Google Calendar: ${e.message}',
          isNetworkError: true,
        ),
      );
    } catch (e) {
      final msg = e.toString();
      final isNetwork =
          msg.contains('SocketException') ||
          msg.contains('ClientException') ||
          msg.contains('Network') ||
          msg.contains('Failed host lookup');
      return Err(
        CalendarFailure(
          'Falha no Google Calendar: $e',
          isNetworkError: isNetwork,
        ),
      );
    }
  }

  @override
  Future<Result<RemoteSnapshot, CalendarFailure>> pull(
    DateTimeRange window, {
    DateTime? updatedMin,
  }) async {
    return _execute((api) async {
      final response = await api.events.list(
        'primary',
        timeMin: window.start.toUtc(),
        timeMax: window.end.toUtc(),
        updatedMin: updatedMin?.toUtc(),
        singleEvents: true,
        showDeleted: true,
      );

      final items = response.items ?? [];
      final remoteEvents = items.map((e) {
        final isCancelled = e.status == 'cancelled';
        DateTime? startDt;
        bool isAllDay = false;

        if (e.start != null) {
          if (e.start!.dateTime != null) {
            startDt = e.start!.dateTime!.toUtc();
            isAllDay = false;
          } else if (e.start!.date != null) {
            startDt = e.start!.date!;
            isAllDay = true;
          }
        }

        final updated = e.updated?.toUtc() ?? clock.nowUtc();

        return RemoteEvent(
          id: e.id ?? '',
          etag: e.etag ?? '',
          updatedAt: updated,
          summary: e.summary,
          description: e.description,
          start: startDt,
          allDay: isAllDay,
          status: isCancelled ? 'cancelled' : (e.status ?? 'confirmed'),
        );
      }).toList();

      return RemoteSnapshot(events: remoteEvents, snapshotAt: clock.nowUtc());
    });
  }

  @override
  Future<Result<RemoteEvent, CalendarFailure>> push(TaskEvent e) async {
    return _execute((api) async {
      final googleEvent = calendar.Event(
        summary: e.title,
        description: e.description,
        status: e.isDeleted ? 'cancelled' : 'confirmed',
      );

      if (e.start != null) {
        if (e.allDay) {
          final dateOnly = DateTime.utc(
            e.start!.year,
            e.start!.month,
            e.start!.day,
          );
          googleEvent.start = calendar.EventDateTime(date: dateOnly);
          googleEvent.end = calendar.EventDateTime(date: dateOnly);
        } else {
          final startUtc = e.start!.toUtc();
          final endUtc = startUtc.add(const Duration(hours: 1));
          googleEvent.start = calendar.EventDateTime(dateTime: startUtc);
          googleEvent.end = calendar.EventDateTime(dateTime: endUtc);
        }
      }

      calendar.Event resultEvent;
      if (e.remoteEventId != null && e.remoteEventId!.isNotEmpty) {
        resultEvent = await api.events.update(
          googleEvent,
          'primary',
          e.remoteEventId!,
        );
      } else {
        resultEvent = await api.events.insert(googleEvent, 'primary');
      }

      DateTime? startDt;
      bool isAllDay = false;

      if (resultEvent.start != null) {
        if (resultEvent.start!.dateTime != null) {
          startDt = resultEvent.start!.dateTime!.toUtc();
          isAllDay = false;
        } else if (resultEvent.start!.date != null) {
          startDt = resultEvent.start!.date!;
          isAllDay = true;
        }
      }

      return RemoteEvent(
        id: resultEvent.id ?? e.remoteEventId ?? '',
        etag: resultEvent.etag ?? '',
        updatedAt: resultEvent.updated?.toUtc() ?? clock.nowUtc(),
        summary: resultEvent.summary,
        description: resultEvent.description,
        start: startDt,
        allDay: isAllDay,
        status: resultEvent.status ?? 'confirmed',
      );
    });
  }

  @override
  Future<Result<void, CalendarFailure>> deleteRemote(
    String eventId,
    String etag,
  ) async {
    return _execute((api) async {
      await api.events.delete('primary', eventId);
    });
  }

  /// Desconecta a conta do Google, revogando acesso, removendo tokens salvos do
  /// `flutter_secure_storage` and clears authentication state in `google_sign_in` (RN-158, CA-5.1).
  ///
  /// Opcionalmente recebe [repository] para desvincular metadados remotos (`remoteEventId`, `remoteEtag`)
  /// of tasks saved in repository keeping 100% of data and local task states intact.
  /// Optionally accepts [settingsRepository] to revoke cloud backup authorization.
  @override
  Future<Result<void, CalendarFailure>> disconnect({
    TaskRepository? repository,
    SettingsRepository? settingsRepository,
    bool clearRemoteLinks = true,
  }) async {
    try {
      // 1. Apaga tokens salvos em FlutterSecureStorage (RN-158, CA-5.1)
      await clearTokens();

      // 2. Clears authentication state in GoogleSignIn
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }

      // 3. Preserves all local tasks in repository unlinking remoteEventId/remoteEtag
      if (repository != null && clearRemoteLinks) {
        final tasksRes = await repository.allTasksForSync();
        if (tasksRes.isOk) {
          final tasks = tasksRes.valueOrNull!;
          for (final task in tasks) {
            if (task.remoteEventId != null || task.remoteEtag != null) {
              final unlinked = Task(
                id: task.id,
                title: task.title,
                notes: task.notes,
                category: task.category,
                dueAt: task.dueAt,
                allDay: task.allDay,
                isCompleted: task.isCompleted,
                completedAt: task.completedAt,
                recurringRuleId: task.recurringRuleId,
                syncState: SyncState.synced,
                createdAt: task.createdAt,
                updatedAt: task.updatedAt,
                deletedAt: task.deletedAt,
              );
              await repository.saveSyncedTask(unlinked);
            }
          }
        }
      }

      // 4. Revokes consent in settings if provided
      if (settingsRepository != null) {
        await settingsRepository.setCloudBackupAllowed(false);
      }

      return const Ok(null);
    } catch (e) {
      return Err(CalendarFailure('Falha ao desconectar conta do Google: $e'));
    }
  }

  /// Alias para [disconnect] (RN-158).
  Future<Result<void, CalendarFailure>> signOut({
    TaskRepository? repository,
    SettingsRepository? settingsRepository,
    bool clearRemoteLinks = true,
  }) => disconnect(
    repository: repository,
    settingsRepository: settingsRepository,
    clearRemoteLinks: clearRemoteLinks,
  );
}
