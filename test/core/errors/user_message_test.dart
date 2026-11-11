import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

void main() {
  group('CA-4.3 / RN-421: userMessageFor', () {
    final forbiddenInMessages = [
      '/',
      r'\',
      'Exception',
      'Error',
      'StorageFailure',
      'NetworkFailure',
      'ValidationFailure',
      'NotFoundFailure',
      'PermissionFailure',
      'CancelledFailure',
      'OcrFailure',
      'KeyStoreFailure',
      'HouseholdFailure',
      'PairingFailure',
      '1500',
      '150000',
      '1.500',
      'R\$',
    ];

    void assertSafeMessage(String msg) {
      expect(msg.trim().isNotEmpty, isTrue);
      for (final forbidden in forbiddenInMessages) {
        expect(
          msg.contains(forbidden),
          isFalse,
          reason: 'Message "$msg" contains prohibited term "$forbidden"',
        );
      }
    }

    test('StorageFailure with paths, exception, and monetary values produces clean message', () {
      const failure = StorageFailure(
        detail: 'Error in /data/user/0/app.db: SqliteException: failure with R\$ 1.500,00 (150000)',
        cause: 'Exception: /var/mobile/Containers/Data/Application/x/app.db',
      );
      final msg = userMessageFor(failure);
      assertSafeMessage(msg);
      expect(
        msg,
        equals(
          'Não foi possível salvar ou carregar os dados. Tente novamente.',
        ),
      );
    });

    test('NetworkFailure offline e online gera mensagens limpas', () {
      final offline = userMessageFor(const NetworkFailure(isOffline: true));
      assertSafeMessage(offline);
      expect(offline, equals('Sem conexão com a internet.'));

      final online = userMessageFor(const NetworkFailure(isOffline: false));
      assertSafeMessage(online);
      expect(
        online,
        equals('Não foi possível conectar ao serviço. Verifique sua conexão.'),
      );
    });

    test('ValidationFailure sanitizes and does not expose technical terms or paths', () {
      const failure = ValidationFailure(
        fields: {
          'db_path': '/data/user/0/invalid.db',
          'amount': 'R\$ 1.500,00 inv\u00E1lido Exception',
        },
      );
      final msg = userMessageFor(failure);
      assertSafeMessage(msg);
    });

    test('all known Failure subtypes produce safe messages', () {
      final failures = <Failure>[
        const NotFoundFailure(what: '/data/path/Expense(150000)'),
        const PermissionFailure(permission: 'android.permission.CAMERA'),
        const CancelledFailure(
          reason: 'Cancelled by /system/bin/abort Exception 1500',
        ),
        const OcrFailure(
          message: 'Failed to parse /sdcard/ocr.jpg Exception R\$ 1.500',
        ),
        const KeyStoreFailure('Keystore Exception /keystore/key.bin'),
        const HouseholdFailure(
          'Sync error: HouseholdException at /data/household',
        ),
        const InviteExpiredFailure(),
        const PairingFailure('Pairing failed: SocketException 1500'),
        const MaxMembersFailure(),
        const IntegrityFailure(
          detail: 'HMAC Exception invalid /payload 150000',
        ),
        const IncompatibleProtocolFailure(
          batchVersion: 99,
          supportedVersion: 1,
        ),
        const CalendarFailure('Calendar permission Exception /calendar/events'),
      ];

      for (final f in failures) {
        final msg = userMessageFor(f);
        assertSafeMessage(msg);
      }
    });
  });
}
