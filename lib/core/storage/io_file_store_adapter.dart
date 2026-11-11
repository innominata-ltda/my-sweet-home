import 'dart:io';
import 'dart:typed_data';

import 'package:my_sweet_home/core/storage/file_store_port.dart';

/// Production file store adapter for local disk (`dart:io`) (001-architecture.md §6).
final class IoFileStoreAdapter implements FileStorePort {
  const IoFileStoreAdapter();

  @override
  Future<String> save(Uint8List bytes, {required String name}) async {
    final file = File(name);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<Uint8List?> read(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return await file.readAsBytes();
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).existsSync();
  }

  @override
  Future<int> getSize(String path) async {
    final file = File(path);
    if (!file.existsSync()) return 0;
    return await file.length();
  }
}
