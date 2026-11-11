import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/domain/kdf_params_policy.dart';

/// Backup encryption service using AES-GCM 256 and Argon2id (ADR-0007, RN-400, RN-401).
class BackupEncryptionService {
  final Argon2id _argon2id;
  final AesGcm _aesGcm;
  final SecurityLimits _limits;
  final KdfParamsPolicy _kdfParamsPolicy;

  static const String formatIdentifier = 'my_sweet_home_encrypted_backup';
  static const int currentVersion = 1;

  BackupEncryptionService({
    Argon2id? argon2id,
    AesGcm? aesGcm,
    SecurityLimits? limits,
    KdfParamsPolicy? kdfParamsPolicy,
  }) : _limits = limits ?? const SecurityLimits(),
       _kdfParamsPolicy =
           kdfParamsPolicy ?? KdfParamsPolicy(limits ?? const SecurityLimits()),
       _argon2id =
           argon2id ??
           Argon2id(
             parallelism: (limits ?? const SecurityLimits()).kdfParallelismMin,
             memory: (limits ?? const SecurityLimits()).kdfMemoryKibMin,
             iterations: 3,
             hashLength: (limits ?? const SecurityLimits()).kdfHashLength,
           ),
       _aesGcm = aesGcm ?? AesGcm.with256bits();

  /// Encrypts plaintext content ([plainText]) with user password ([password]).
  ///
  /// Generates random salt and nonce, returning JSON envelope string.
  Future<Result<String, Failure>> encrypt({
    required String plainText,
    required String password,
    Uint8List? customSalt,
    Uint8List? customNonce,
  }) async {
    if (password.trim().isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {
            'password':
                'A senha para criptografia do backup não pode ser vazia.',
          },
        ),
      );
    }

    try {
      final salt = customSalt ?? _generateRandomBytes(16);
      final nonce = customNonce ?? _generateRandomBytes(12);

      final derivedSecretKey = await _argon2id.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      final clearTextBytes = utf8.encode(plainText);
      final secretBox = await _aesGcm.encrypt(
        clearTextBytes,
        secretKey: derivedSecretKey,
        nonce: nonce,
      );

      final envelope = {
        'format': formatIdentifier,
        'version': currentVersion,
        'algorithm': 'AES-256-GCM',
        'kdf': 'Argon2id',
        'kdf_params': {
          'memory': _limits.kdfMemoryKibMin,
          'iterations': 3,
          'parallelism': _limits.kdfParallelismMin,
          'hash_length': _limits.kdfHashLength,
        },
        'salt': base64Encode(salt),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
        'ciphertext': base64Encode(secretBox.cipherText),
      };

      return Ok(const JsonEncoder.withIndent('  ').convert(envelope));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao criptografar backup: $e', cause: e),
      );
    }
  }

  /// Descriptografa a string JSON do envelope ([encryptedContent]) com a senha fornecida ([password]).
  ///
  /// Returns plaintext content if password is correct and integrity is verified.
  Future<Result<String, Failure>> decrypt({
    required String encryptedContent,
    required String password,
  }) async {
    if (password.trim().isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {
            'password':
                'A senha para descriptografia do backup não pode ser vazia.',
          },
        ),
      );
    }

    try {
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(encryptedContent) as Map<String, dynamic>;
      } catch (e) {
        return const Err(
          ValidationFailure(
            fields: {
              'encryptedContent':
                  'Arquivo de backup criptografado inválido ou malformado.',
            },
          ),
        );
      }

      final format = json['format']?.toString();
      if (format != formatIdentifier) {
        return const Err(
          ValidationFailure(
            fields: {'format': 'Formato de arquivo de backup não reconhecido.'},
          ),
        );
      }

      final policyRes = _kdfParamsPolicy.validate(json);
      if (policyRes.isErr) {
        return Err(policyRes.failureOrNull!);
      }
      final kdfParams = policyRes.valueOrNull!;

      final saltBase64 = json['salt']?.toString();
      final nonceBase64 = json['nonce']?.toString();
      final macBase64 = json['mac']?.toString();
      final ciphertextBase64 = json['ciphertext']?.toString();

      if (saltBase64 == null ||
          nonceBase64 == null ||
          macBase64 == null ||
          ciphertextBase64 == null) {
        return const Err(
          ValidationFailure(
            fields: {
              'structure':
                  'Estrutura de dados do backup criptografado incompleta.',
            },
          ),
        );
      }

      final salt = base64Decode(saltBase64);
      final nonce = base64Decode(nonceBase64);
      final macBytes = base64Decode(macBase64);
      final cipherText = base64Decode(ciphertextBase64);

      final argon2id = Argon2id(
        parallelism: kdfParams.parallelism,
        memory: kdfParams.memoryKib,
        iterations: kdfParams.iterations,
        hashLength: kdfParams.hashLength,
      );

      final derivedSecretKey = await argon2id.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      final clearTextBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: derivedSecretKey,
      );

      return Ok(utf8.decode(clearTextBytes));
    } catch (e) {
      return const Err(
        ValidationFailure(
          fields: {
            'password': 'Senha incorreta ou arquivo de backup corrompido.',
          },
        ),
      );
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}
