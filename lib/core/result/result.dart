/// Result types: [Ok] (success) and [Err] (typed failure).
///
/// Repositories MUST return `Result<S, Failure>` and MUST NOT throw
/// exceptions (RN-006). All infrastructure exceptions are caught at the boundary
/// and converted into typed [Failure] instances.
library;

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

/// Discriminated result: success [Ok] or failure [Err].
sealed class Result<S, F extends Failure> {
  const Result();

  /// Applies [onOk] when successful, [onErr] when failed.
  R fold<R>(R Function(S value) onOk, R Function(F failure) onErr);

  /// `true` if this result is [Ok].
  bool get isOk => this is Ok<S, F>;

  /// `true` if this result is [Err].
  bool get isErr => this is Err<S, F>;

  /// Returns value when [Ok], `null` otherwise.
  S? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Returns failure when [Err], `null` otherwise.
  F? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };
}

/// Success result holding [value].
final class Ok<S, F extends Failure> extends Result<S, F> {
  const Ok(this.value);
  final S value;

  @override
  R fold<R>(R Function(S value) onOk, R Function(F failure) onErr) =>
      onOk(value);

  @override
  String toString() => 'Ok($value)';
}

/// Failure result holding [failure].
final class Err<S, F extends Failure> extends Result<S, F> {
  const Err(this.failure);
  final F failure;

  @override
  R fold<R>(R Function(S value) onOk, R Function(F failure) onErr) =>
      onErr(failure);

  @override
  String toString() => 'Err($failure)';
}

// ---------------------------------------------------------------------------
// Failure hierarchy
// ---------------------------------------------------------------------------

/// Base class for all domain failures.
abstract base class Failure {
  const Failure();
}

/// Storage failure — database, file system, serialization.
final class StorageFailure extends Failure {
  const StorageFailure({required this.detail, this.cause});
  final String detail;
  final Object? cause;

  @override
  String toString() => 'StorageFailure($detail)';
}

/// Invalid data provided by the user or system.
final class ValidationFailure extends Failure {
  const ValidationFailure({required this.fields});

  /// Field name → error message map.
  final Map<String, String> fields;

  @override
  String toString() => 'ValidationFailure($fields)';
}

/// Record not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.what});
  final String what;

  @override
  String toString() => 'NotFoundFailure($what)';
}

/// Permission denied by platform.
final class PermissionFailure extends Failure {
  const PermissionFailure({required this.permission});
  final String permission;

  @override
  String toString() => 'PermissionFailure($permission)';
}

/// Network failure. The app is offline-first; this failure only occurs
/// in optional network features (cloud backup, remote sync).
final class NetworkFailure extends Failure {
  const NetworkFailure({required this.isOffline});
  final bool isOffline;

  @override
  String toString() => 'NetworkFailure(offline=$isOffline)';
}

/// Operation cancelled by user or timeout.
final class CancelledFailure extends Failure {
  const CancelledFailure({this.reason});
  final String? reason;

  @override
  String toString() => 'CancelledFailure($reason)';
}

/// OCR processing or text recognition failure.
final class OcrFailure extends Failure {
  const OcrFailure({required this.message, this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'OcrFailure($message)';
}
