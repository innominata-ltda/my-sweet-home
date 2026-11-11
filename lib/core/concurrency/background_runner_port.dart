library;

import 'dart:async';

/// Port for executing CPU-intensive tasks off the main UI thread (RN-424).
///
/// In production, uses [Isolate.run]. In tests, uses synchronous/inline execution via fake.
abstract interface class BackgroundRunnerPort {
  Future<R> run<R>(FutureOr<R> Function() task);
}
