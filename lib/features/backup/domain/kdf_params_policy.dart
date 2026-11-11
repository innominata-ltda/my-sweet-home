library;

import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';

/// Validated Argon2id key derivation parameters (RN-400).
final class KdfParams {
  const KdfParams({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
    required this.hashLength,
  });

  final int memoryKib;
  final int iterations;
  final int parallelism;
  final int hashLength;
}

/// Validation policy for KDF parameters and encrypted backup envelope (RN-400, RN-401).
///
/// Ensures that excessive or invalid parameters, or unknown versions are
/// rejected BEFORE any key derivation in memory.
final class KdfParamsPolicy {
  const KdfParamsPolicy([this.limits = const SecurityLimits()]);

  final SecurityLimits limits;

  /// Mandatory message per RN-401 for invalid parameters or unsupported versions.
  static const String unsupportedFormatMessage =
      'Este backup usa um formato não suportado por esta versão do app';

  /// Validates the envelope (version, algorithm, KDF and parameters) before any derivation.
  Result<KdfParams, ValidationFailure> validate(Map<String, Object?> envelope) {
    final version = envelope['version'];
    if (version is! int || version != 1) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    final algorithm = envelope['algorithm'];
    final kdf = envelope['kdf'];
    if (algorithm != 'AES-256-GCM' || kdf != 'Argon2id') {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    final kdfParams = envelope['kdf_params'];
    if (kdfParams is! Map) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    final memory = kdfParams['memory'];
    final iterations = kdfParams['iterations'];
    final parallelism = kdfParams['parallelism'];
    final hashLength = kdfParams['hash_length'];

    if (memory is! int ||
        memory < limits.kdfMemoryKibMin ||
        memory > limits.kdfMemoryKibMax) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    if (iterations is! int ||
        iterations < limits.kdfIterationsMin ||
        iterations > limits.kdfIterationsMax) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    if (parallelism is! int ||
        parallelism < limits.kdfParallelismMin ||
        parallelism > limits.kdfParallelismMax) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    if (hashLength is! int || hashLength != limits.kdfHashLength) {
      return const Err(
        ValidationFailure(fields: {'format': unsupportedFormatMessage}),
      );
    }

    return Ok(
      KdfParams(
        memoryKib: memory,
        iterations: iterations,
        parallelism: parallelism,
        hashLength: hashLength,
      ),
    );
  }
}
