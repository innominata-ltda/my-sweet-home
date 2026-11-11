import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/data/backup_encryption_service.dart';

void main() {
  group('T-04 — BackupEncryptionService Unit Tests', () {
    late BackupEncryptionService encryptionService;

    setUp(() {
      encryptionService = BackupEncryptionService();
    });

    test(
      'Encrypts and decrypts data successfully with correct password',
      () async {
        const plainText =
            '{"schema_version": 1, "exported_at": "2026-10-01", "tables": {}}';
        const password = 'minha_senha_segura_123';

        final encryptRes = await encryptionService.encrypt(
          plainText: plainText,
          password: password,
        );

        expect(encryptRes.isOk, isTrue);
        final encryptedContent = encryptRes.valueOrNull!;

        expect(encryptedContent, contains('my_sweet_home_encrypted_backup'));
        expect(encryptedContent, contains('AES-256-GCM'));
        expect(encryptedContent, contains('Argon2id'));
        expect(encryptedContent, isNot(contains(plainText)));

        final decryptRes = await encryptionService.decrypt(
          encryptedContent: encryptedContent,
          password: password,
        );

        expect(decryptRes.isOk, isTrue);
        expect(decryptRes.valueOrNull, equals(plainText));
      },
    );

    test(
      'CA-3.1 — Falha na descriptografia quando a senha é incorreta',
      () async {
        const plainText = '{"schema_version": 1, "data": "secreto"}';
        const correctPassword = 'senha_certa_123';
        const wrongPassword = 'senha_errada_999';

        final encryptRes = await encryptionService.encrypt(
          plainText: plainText,
          password: correctPassword,
        );
        expect(encryptRes.isOk, isTrue);

        final decryptRes = await encryptionService.decrypt(
          encryptedContent: encryptRes.valueOrNull!,
          password: wrongPassword,
        );

        expect(decryptRes.isErr, isTrue);
        final failure = decryptRes.failureOrNull!;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fields['password'],
          contains('Senha incorreta ou arquivo de backup corrompido'),
        );
      },
    );

    test('Rejeita senha vazia na criptografia e na descriptografia', () async {
      final encryptRes = await encryptionService.encrypt(
        plainText: 'dados',
        password: '   ',
      );
      expect(encryptRes.isErr, isTrue);
      expect(encryptRes.failureOrNull, isA<ValidationFailure>());

      final decryptRes = await encryptionService.decrypt(
        encryptedContent: '{}',
        password: '',
      );
      expect(decryptRes.isErr, isTrue);
      expect(decryptRes.failureOrNull, isA<ValidationFailure>());
    });

    test(
      'Rejeita formato de arquivo de backup não reconhecido ou corrompido',
      () async {
        final badFormatRes = await encryptionService.decrypt(
          encryptedContent: '{"format": "invalid_format", "salt": "abc", "nonce": "def", "mac": "ghi", "ciphertext": "jkl"}',
          password: 'senha',
        );
        expect(badFormatRes.isErr, isTrue);
        expect(
          (badFormatRes.failureOrNull as ValidationFailure).fields['format'],
          contains('Formato de arquivo de backup não reconhecido'),
        );

        final malformedJsonRes = await encryptionService.decrypt(
          encryptedContent: '{ json malformado',
          password: 'senha',
        );
        expect(malformedJsonRes.isErr, isTrue);
        expect(
          (malformedJsonRes.failureOrNull as ValidationFailure)
              .fields['encryptedContent'],
          contains('inválido ou malformado'),
        );
      },
    );

    test('CA-1.1 / CA-1.2 / CA-1.3: Rejects out-of-range parameters or unknown version before derivation', () async {
      // CA-1.1: Excessive memory (4 GB)
      final badMemoryEnvelope = '''
{
  "format": "my_sweet_home_encrypted_backup",
  "version": 1,
  "algorithm": "AES-256-GCM",
  "kdf": "Argon2id",
  "kdf_params": {
    "memory": 4194304,
    "iterations": 3,
    "parallelism": 1,
    "hash_length": 32
  },
  "salt": "c2FsdA==",
  "nonce": "bm9uY2U=",
  "mac": "bWFj",
  "ciphertext": "Y2lwaGVydGV4dA=="
}''';
      final badMemoryRes = await encryptionService.decrypt(
        encryptedContent: badMemoryEnvelope,
        password: 'senha',
      );
      expect(badMemoryRes.isErr, isTrue);
      expect(
        (badMemoryRes.failureOrNull as ValidationFailure).fields['format'],
        equals(
          'Este backup usa um formato não suportado por esta versão do app',
        ),
      );

      // CA-1.2: Insufficient iterations (1 iteration)
      final badIterationsEnvelope = '''
{
  "format": "my_sweet_home_encrypted_backup",
  "version": 1,
  "algorithm": "AES-256-GCM",
  "kdf": "Argon2id",
  "kdf_params": {
    "memory": 19456,
    "iterations": 1,
    "parallelism": 1,
    "hash_length": 32
  },
  "salt": "c2FsdA==",
  "nonce": "bm9uY2U=",
  "mac": "bWFj",
  "ciphertext": "Y2lwaGVydGV4dA=="
}''';
      final badIterRes = await encryptionService.decrypt(
        encryptedContent: badIterationsEnvelope,
        password: 'senha',
      );
      expect(badIterRes.isErr, isTrue);
      expect(
        (badIterRes.failureOrNull as ValidationFailure).fields['format'],
        equals(
          'Este backup usa um formato não suportado por esta versão do app',
        ),
      );

      // CA-1.3: Unknown version (version = 99)
      final badVersionEnvelope = '''
{
  "format": "my_sweet_home_encrypted_backup",
  "version": 99,
  "algorithm": "AES-256-GCM",
  "kdf": "Argon2id",
  "kdf_params": {
    "memory": 19456,
    "iterations": 3,
    "parallelism": 1,
    "hash_length": 32
  },
  "salt": "c2FsdA==",
  "nonce": "bm9uY2U=",
  "mac": "bWFj",
  "ciphertext": "Y2lwaGVydGV4dA=="
}''';
      final badVersionRes = await encryptionService.decrypt(
        encryptedContent: badVersionEnvelope,
        password: 'senha',
      );
      expect(badVersionRes.isErr, isTrue);
      expect(
        (badVersionRes.failureOrNull as ValidationFailure).fields['format'],
        equals(
          'Este backup usa um formato não suportado por esta versão do app',
        ),
      );
    });

    test(
      'Encrypts deterministically when customSalt and customNonce are provided',
      () async {
        final customSalt = Uint8List.fromList(List.generate(16, (i) => i));
        final customNonce = Uint8List.fromList(
          List.generate(12, (i) => i + 10),
        );

        final res1 = await encryptionService.encrypt(
          plainText: 'test content',
          password: 'deterministic_password',
          customSalt: customSalt,
          customNonce: customNonce,
        );

        final res2 = await encryptionService.encrypt(
          plainText: 'test content',
          password: 'deterministic_password',
          customSalt: customSalt,
          customNonce: customNonce,
        );

        expect(res1.isOk, isTrue);
        expect(res2.isOk, isTrue);
        expect(res1.valueOrNull, equals(res2.valueOrNull));
      },
    );
  });
}
