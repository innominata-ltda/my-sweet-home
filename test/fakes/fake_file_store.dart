import 'dart:typed_data';

import 'package:my_sweet_home/core/storage/file_store_port.dart';

/// In-memory deterministic fake of [FileStorePort] for unit and integration tests (004-testing.md §3).
class FakeFileStore implements FileStorePort {
  final Map<String, Uint8List> _files = {};
  bool shouldThrowOnDelete = false;

  /// Returns an immutable map of stored files (path -> bytes).
  Map<String, Uint8List> get files => Map.unmodifiable(_files);

  @override
  Future<String> save(Uint8List bytes, {required String name}) async {
    final path = name.startsWith('/app/storage/') ? name : '/app/storage/$name';
    _files[path] = bytes;
    return path;
  }

  @override
  Future<Uint8List?> read(String path) async {
    return _files[path];
  }

  @override
  Future<void> delete(String path) async {
    if (shouldThrowOnDelete) {
      throw Exception('Simulated FileSystemException: Access denied');
    }
    _files.remove(path);
  }

  @override
  Future<bool> exists(String path) async {
    return _files.containsKey(path);
  }

  @override
  Future<int> getSize(String path) async {
    return _files[path]?.length ?? 0;
  }
}
