import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/features/backup/domain/kdf_params_policy.dart';

void main() {
  group('CA-1.1, CA-1.2, CA-1.3, CA-1.4 / RN-400, RN-401: KdfParamsPolicy', () {
    const limits = SecurityLimits();
    const policy = KdfParamsPolicy(limits);

    Map<String, Object?> createValidEnvelope({
      int version = 1,
      String algorithm = 'AES-256-GCM',
      String kdf = 'Argon2id',
      int memory = 19456,
      int iterations = 3,
      int parallelism = 1,
      int hashLength = 32,
    }) {
      return {
        'format': 'my_sweet_home_encrypted_backup',
        'version': version,
        'algorithm': algorithm,
        'kdf': kdf,
        'kdf_params': {
          'memory': memory,
          'iterations': iterations,
          'parallelism': parallelism,
          'hash_length': hashLength,
        },
        'salt': 'c2FsdA==',
        'nonce': 'bm9uY2U=',
        'mac': 'bWFj',
        'ciphertext': 'Y2lwaGVydGV4dA==',
      };
    }

    test('CA-1.4: valid envelope with default parameters is accepted', () {
      final envelope = createValidEnvelope();
      final result = policy.validate(envelope);

      expect(result.isOk, isTrue);
      final params = result.valueOrNull!;
      expect(params.memoryKib, equals(19456));
      expect(params.iterations, equals(3));
      expect(params.parallelism, equals(1));
      expect(params.hashLength, equals(32));
    });

    test(
      'CA-1.1 / RN-400: memory above limit (4 GB = 4194304 KiB) is rejected',
      () {
        final envelope = createValidEnvelope(memory: 4194304);
        final result = policy.validate(envelope);

        expect(result.isErr, isTrue);
        final failure = result.failureOrNull!;
        expect(
          failure.fields['format'],
          equals(KdfParamsPolicy.unsupportedFormatMessage),
        );
      },
    );

    test('RN-400: memory below minimum limit (19455 KiB) is rejected', () {
      final envelope = createValidEnvelope(memory: 19455);
      final result = policy.validate(envelope);

      expect(result.isErr, isTrue);
      expect(
        result.failureOrNull!.fields['format'],
        equals(KdfParamsPolicy.unsupportedFormatMessage),
      );
    });

    test(
      'CA-1.2 / RN-400: iterações abaixo do mínimo (1 iteração) é recusada',
      () {
        final envelope = createValidEnvelope(iterations: 1);
        final result = policy.validate(envelope);

        expect(result.isErr, isTrue);
        expect(
          result.failureOrNull!.fields['format'],
          equals(KdfParamsPolicy.unsupportedFormatMessage),
        );
      },
    );

    test('RN-400: iterations above maximum (11 iterations) is rejected', () {
      final envelope = createValidEnvelope(iterations: 11);
      final result = policy.validate(envelope);

      expect(result.isErr, isTrue);
      expect(
        result.failureOrNull!.fields['format'],
        equals(KdfParamsPolicy.unsupportedFormatMessage),
      );
    });

    test('RN-400: parallelism outside 1..4 is rejected', () {
      final under = createValidEnvelope(parallelism: 0);
      expect(policy.validate(under).isErr, isTrue);

      final over = createValidEnvelope(parallelism: 5);
      expect(policy.validate(over).isErr, isTrue);
    });

    test('RN-400: hash_length different from 32 bytes is rejected', () {
      final envelope = createValidEnvelope(hashLength: 64);
      expect(policy.validate(envelope).isErr, isTrue);
    });

    test('CA-1.3 / RN-401: unknown version (version = 99) is rejected before derivation', () {
      final envelope = createValidEnvelope(version: 99);
      final result = policy.validate(envelope);

      expect(result.isErr, isTrue);
      expect(
        result.failureOrNull!.fields['format'],
        equals(KdfParamsPolicy.unsupportedFormatMessage),
      );
    });

    test('RN-401: unknown kdf or algorithm is rejected', () {
      final badKdf = createValidEnvelope(kdf: 'pbkdf2');
      expect(policy.validate(badKdf).isErr, isTrue);

      final badAlgo = createValidEnvelope(algorithm: 'DES');
      expect(policy.validate(badAlgo).isErr, isTrue);
    });

    test('RN-401: parameters with invalid or null types are rejected', () {
      final invalid = {
        'format': 'my_sweet_home_encrypted_backup',
        'version': '1', // string em vez de int
        'algorithm': 'AES-256-GCM',
        'kdf': 'Argon2id',
        'kdf_params': {'memory': '19456'},
      };

      final result = policy.validate(invalid);
      expect(result.isErr, isTrue);
      expect(
        result.failureOrNull!.fields['format'],
        equals(KdfParamsPolicy.unsupportedFormatMessage),
      );
    });
  });
}
