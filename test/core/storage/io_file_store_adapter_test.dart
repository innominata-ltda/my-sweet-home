import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/storage/io_file_store_adapter.dart';

void main() {
  group('IoFileStoreAdapter', () {
    late Directory tempDir;
    late IoFileStoreAdapter adapter;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_store_test_');
      adapter = const IoFileStoreAdapter();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'saves, reads, checks existence, and deletes file on real disk',
      () async {
        final filePath =
            '${tempDir.path}${Platform.pathSeparator}test_receipt.jpg';
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        expect(await adapter.exists(filePath), isFalse);

        final savedPath = await adapter.save(bytes, name: filePath);
        expect(savedPath, equals(filePath));
        expect(await adapter.exists(filePath), isTrue);

        final readBytes = await adapter.read(filePath);
        expect(readBytes, equals(bytes));
        expect(await adapter.getSize(filePath), equals(bytes.length));

        await adapter.delete(filePath);
        expect(await adapter.exists(filePath), isFalse);
        expect(await adapter.read(filePath), isNull);
        expect(await adapter.getSize(filePath), equals(0));
      },
    );
  });
}
