import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';

/// Port for reading, creating, and wiping the database encryption key (RN-414, RN-417, RN-418).
abstract interface class DatabaseKeyStorePort {
  /// Reads the 256-bit cryptographic key stored in secure storage.
  ///
  /// Returns [Ok(null)] if the key was never created.
  Future<Result<Uint8List?, Failure>> read();

  /// Creates a new random 32-byte (256-bit) key and persists it in secure storage.
  Future<Result<Uint8List, Failure>> create();

  /// Deletes the key from secure storage.
  Future<Result<void, Failure>> wipe();
}
