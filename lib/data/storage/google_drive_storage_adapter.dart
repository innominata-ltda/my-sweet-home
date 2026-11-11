library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/storage/cloud_storage_port.dart';
import 'package:my_sweet_home/core/time/clock.dart';

/// HTTP client to attach OAuth authentication headers (Bearer Token).
class GoogleDriveAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleDriveAuthClient(this._headers, [http.Client? client])
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

/// Implementation of [CloudStoragePort] via Google Drive (ADR-0011, RF-127, RN-235, T-B01).
///
/// Uses a dedicated visible folder in Google Drive ([syncFolderName])
/// with scope `drive.file` to store encrypted backups and sync batches,
/// and securely persists credentials with [FlutterSecureStorage].
class GoogleDriveStorageAdapter implements CloudStoragePort {
  static const String syncFolderName = 'My Sweet Home - Sincronização';
  static const String keyAccessToken = 'google_drive_access_token';
  static const String keyRefreshToken = 'google_drive_refresh_token';
  static const String keyTokenExpiry = 'google_drive_token_expiry';

  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final drive.DriveApi? _injectedDriveApi;
  final Clock clock;
  final String? _clientId;
  drive.DriveApi? _cachedDriveApi;
  String? _cachedFolderId;

  GoogleDriveStorageAdapter({
    GoogleSignIn? googleSignIn,
    drive.DriveApi? driveApi,
    FlutterSecureStorage? secureStorage,
    this.clock = const SystemClock(),
    String? clientId,
    String? initialFolderId,
  }) : _injectedDriveApi = driveApi,
       _clientId = clientId ?? _resolveClientId(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(resetOnError: false),
           ),
       _cachedFolderId = initialFolderId,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             serverClientId: clientId ?? _resolveClientId(),
             scopes: [drive.DriveApi.driveFileScope],
           );

  static String? _resolveClientId() {
    if (Platform.environment.containsKey('GOOGLE_OAUTH_CLIENT_ID_ANDROID')) {
      final val = Platform.environment['GOOGLE_OAUTH_CLIENT_ID_ANDROID'];
      if (val != null && val.isNotEmpty) return val;
    }
    const fromEnv = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_ANDROID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return null;
  }

  /// Returns the configured OAuth Client ID.
  String? get clientId => _clientId;

  /// Stores tokens in [FlutterSecureStorage] without plain text (RN-160, T-B01).
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

  /// Reads the securely stored access token.
  Future<String?> getStoredAccessToken() async {
    return _secureStorage.read(key: keyAccessToken);
  }

  /// Reads the securely stored refresh token.
  Future<String?> getStoredRefreshToken() async {
    return _secureStorage.read(key: keyRefreshToken);
  }

  /// Reads the stored token expiration date.
  Future<DateTime?> getStoredTokenExpiry() async {
    final raw = await _secureStorage.read(key: keyTokenExpiry);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  /// Clears all tokens from secure storage and memory caches (RN-158).
  Future<void> clearTokens() async {
    _cachedDriveApi = null;
    _cachedFolderId = null;
    await _secureStorage.delete(key: keyAccessToken);
    await _secureStorage.delete(key: keyRefreshToken);
    await _secureStorage.delete(key: keyTokenExpiry);
  }

  /// Returns the cached [drive.DriveApi] instance, if authenticated.
  drive.DriveApi? get cachedDriveApi => _cachedDriveApi;

  /// Returns the cached visible folder ID, if resolved.
  String? get cachedFolderId => _cachedFolderId;

  Future<drive.DriveApi> _getDriveApi({bool forceRefresh = false}) async {
    if (_injectedDriveApi != null) {
      return _injectedDriveApi;
    }
    if (!forceRefresh && _cachedDriveApi != null) {
      return _cachedDriveApi!;
    }

    if (!forceRefresh) {
      // Tries to reuse persisted secure token to avoid repeated prompt
      final storedToken = await getStoredAccessToken();
      final expiry = await getStoredTokenExpiry();
      final isExpired = expiry != null && !expiry.isAfter(clock.nowUtc());
      if (storedToken != null && storedToken.isNotEmpty && !isExpired) {
        final authClient = GoogleDriveAuthClient({
          'Authorization': 'Bearer $storedToken',
        });
        _cachedDriveApi = drive.DriveApi(authClient);
        return _cachedDriveApi!;
      }
    }

    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();

    if (account == null) {
      throw const FormatException(
        'Google authentication canceled or unavailable',
      );
    }

    final authHeaders = await account.authHeaders;
    final token = authHeaders['Authorization']?.replaceAll('Bearer ', '');
    if (token != null && token.isNotEmpty) {
      await storeTokens(accessToken: token);
    }

    final authClient = GoogleDriveAuthClient(authHeaders);
    _cachedDriveApi = drive.DriveApi(authClient);
    return _cachedDriveApi!;
  }

  Future<String> _getOrCreateSyncFolder(drive.DriveApi api) async {
    if (_cachedFolderId != null) {
      return _cachedFolderId!;
    }

    try {
      final folderList = await api.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$syncFolderName' and trashed = false",
        $fields: 'files(id, name)',
      );

      final files = folderList.files ?? [];
      if (files.isNotEmpty && files.first.id != null) {
        _cachedFolderId = files.first.id;
        return _cachedFolderId!;
      }

      final folderMetadata = drive.File()
        ..name = syncFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await api.files.create(
        folderMetadata,
        $fields: 'id',
      );
      _cachedFolderId = createdFolder.id;
      return _cachedFolderId ?? 'root';
    } catch (_) {
      return 'root';
    }
  }

  Future<Result<T, Failure>> _runWithRetry<T>(
    Future<T> Function(drive.DriveApi api) action, {
    required String failurePrefix,
  }) async {
    try {
      final api = await _getDriveApi();
      final result = await action(api);
      return Ok(result);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        await clearTokens();
        // If failed with expired/invalid token and not an injected mock, try to refresh silently
        if (_injectedDriveApi == null) {
          try {
            final refreshedApi = await _getDriveApi(forceRefresh: true);
            final result = await action(refreshedApi);
            return Ok(result);
          } catch (_) {}
        }
      }
      return Err(
        StorageFailure(
          detail: 'Google Drive API error (${e.status}): ${e.message}',
          cause: e,
        ),
      );
    } on SocketException {
      return const Err(NetworkFailure(isOffline: true));
    } catch (e) {
      if (e is Failure) {
        return Err(e);
      }
      return Err(StorageFailure(detail: '$failurePrefix: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> uploadBackup({
    required String fileName,
    required String encryptedContent,
  }) async {
    return _runWithRetry((api) async {
      final folderId = await _getOrCreateSyncFolder(api);
      final bytes = utf8.encode(encryptedContent);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'text/plain',
      );

      final query = folderId == 'root'
          ? "name = '$fileName' and trashed = false"
          : "'$folderId' in parents and name = '$fileName' and trashed = false";

      final existingList = await api.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      final existingFiles = existingList.files ?? [];
      if (existingFiles.isNotEmpty && existingFiles.first.id != null) {
        final fileId = existingFiles.first.id!;
        await api.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        final newFile = drive.File()
          ..name = fileName
          ..parents = folderId == 'root' ? null : [folderId];
        await api.files.create(newFile, uploadMedia: media);
      }
    }, failurePrefix: 'Failed to upload to Google Drive');
  }

  @override
  Future<Result<String, Failure>> downloadBackup({
    required String fileName,
  }) async {
    return _runWithRetry((api) async {
      final folderId = await _getOrCreateSyncFolder(api);

      final query = folderId == 'root'
          ? "name = '$fileName' and trashed = false"
          : "'$folderId' in parents and name = '$fileName' and trashed = false";

      final existingList = await api.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      final existingFiles = existingList.files ?? [];
      if (existingFiles.isEmpty || existingFiles.first.id == null) {
        throw StorageFailure(
          detail: 'File not found on Google Drive: $fileName',
        );
      }

      final fileId = existingFiles.first.id!;
      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is! drive.Media) {
        throw const StorageFailure(
          detail: 'Invalid response from Google Drive when downloading file',
        );
      }

      final media = response;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      return utf8.decode(bytes);
    }, failurePrefix: 'Failed to download from Google Drive');
  }

  @override
  Future<Result<int, Failure>> backupSizeBytes({
    required String fileName,
  }) async {
    return _runWithRetry((api) async {
      final folderId = await _getOrCreateSyncFolder(api);

      final query = folderId == 'root'
          ? "name = '$fileName' and trashed = false"
          : "'$folderId' in parents and name = '$fileName' and trashed = false";

      final fileList = await api.files.list(
        q: query,
        $fields: 'files(id, name, size)',
      );

      final files = fileList.files;
      if (files == null || files.isEmpty) {
        throw StorageFailure(
          detail: 'File not found on Google Drive: $fileName',
        );
      }

      final sizeStr = files.first.size;
      return sizeStr != null ? int.tryParse(sizeStr) ?? 0 : 0;
    }, failurePrefix: 'Failed to query size on Google Drive');
  }

  @override
  Future<Result<List<String>, Failure>> listBackups() async {
    return _runWithRetry((api) async {
      final folderId = await _getOrCreateSyncFolder(api);

      final query = folderId == 'root'
          ? "mimeType != 'application/vnd.google-apps.folder' and trashed = false"
          : "'$folderId' in parents and mimeType != 'application/vnd.google-apps.folder' and trashed = false";

      final fileList = await api.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      final names = (fileList.files ?? [])
          .map((f) => f.name)
          .whereType<String>()
          .toList();

      return names;
    }, failurePrefix: 'Failed to list files on Google Drive');
  }
}
