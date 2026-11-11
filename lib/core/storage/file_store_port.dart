import 'dart:typed_data';

/// Abstraction port for file storage and manipulation (001-architecture.md §6).
///
/// **Rule ARQ-001:** Everything touching the platform file system must reside behind a port.
abstract interface class FileStorePort {
  /// Saves [bytes] to storage with [name] and returns the complete saved path.
  Future<String> save(Uint8List bytes, {required String name});

  /// Reads bytes from file at [path]. Returns `null` if the file does not exist.
  Future<Uint8List?> read(String path);

  /// Deletes file at [path].
  Future<void> delete(String path);

  /// Returns `true` if file at [path] exists in storage.
  Future<bool> exists(String path);

  /// Returns size in bytes of file at [path]. Returns 0 if file does not exist.
  Future<int> getSize(String path);
}
