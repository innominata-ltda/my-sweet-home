import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_photo_cleaner.dart';

import '../../fakes/fake_file_store.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  group('ReceiptPhotoCleaner (T-20, RF-048, RN-202, CA-6.1)', () {
    late FakeFileStore fileStore;
    late FakeSettingsRepository settingsRepository;
    late ReceiptPhotoCleaner cleaner;

    setUp(() {
      fileStore = FakeFileStore();
      settingsRepository = FakeSettingsRepository();
      cleaner = ReceiptPhotoCleaner(
        fileStorePort: fileStore,
        settingsRepository: settingsRepository,
      );
    });

    test('CA-6.1: deletes original file from device when "delete photo" setting is active (default)', () async {
      // Arrange
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final photoPath = await fileStore.save(
        sampleBytes,
        name: 'receipt_01.jpg',
      );

      expect(await fileStore.exists(photoPath), isTrue);
      expect(await settingsRepository.isDeleteReceiptPhotoEnabled(), isTrue);

      // Act
      final result = await cleaner.cleanUpPhoto(photoPath);

      // Assert
      expect(result, equals(PhotoCleanupResult.deleted));
      expect(await fileStore.exists(photoPath), isFalse);
    });

    test('RN-202: retains photo in private directory when "delete photo" setting is inactive', () async {
      // Arrange
      await settingsRepository.setDeleteReceiptPhotoEnabled(false);
      final sampleBytes = Uint8List.fromList([10, 20, 30]);
      final photoPath = await fileStore.save(
        sampleBytes,
        name: 'receipt_02.jpg',
      );

      // Act
      final result = await cleaner.cleanUpPhoto(photoPath);

      // Assert
      expect(result, equals(PhotoCleanupResult.retained));
      expect(await fileStore.exists(photoPath), isTrue);
      final bytes = await fileStore.read(photoPath);
      expect(bytes, equals(sampleBytes));
    });

    test('returns skipped when image path is null or blank', () async {
      final resultNull = await cleaner.cleanUpPhoto(null);
      final resultEmpty = await cleaner.cleanUpPhoto('   ');

      expect(resultNull, equals(PhotoCleanupResult.skipped));
      expect(resultEmpty, equals(PhotoCleanupResult.skipped));
    });

    test('returns skipped when file does not exist in storage', () async {
      const nonExistentPath = '/app/storage/non_existent.jpg';

      final result = await cleaner.cleanUpPhoto(nonExistentPath);

      expect(result, equals(PhotoCleanupResult.skipped));
    });

    test('changing setting at runtime reflects in cleaner behavior', () async {
      final sampleBytes = Uint8List.fromList([7, 8, 9]);
      final photoPath1 = await fileStore.save(sampleBytes, name: 'photo1.jpg');
      final photoPath2 = await fileStore.save(sampleBytes, name: 'photo2.jpg');

      // 1. Disable setting -> photo retained
      await settingsRepository.setDeleteReceiptPhotoEnabled(false);
      final res1 = await cleaner.cleanUpPhoto(photoPath1);
      expect(res1, equals(PhotoCleanupResult.retained));
      expect(await fileStore.exists(photoPath1), isTrue);

      // 2. Re-enable setting -> photo deleted
      await settingsRepository.setDeleteReceiptPhotoEnabled(true);
      final res2 = await cleaner.cleanUpPhoto(photoPath2);
      expect(res2, equals(PhotoCleanupResult.deleted));
      expect(await fileStore.exists(photoPath2), isFalse);
    });

    test(
      'returns failed when I/O error occurs while trying to delete file',
      () async {
        final sampleBytes = Uint8List.fromList([1, 1, 1]);
        final photoPath = await fileStore.save(
          sampleBytes,
          name: 'fail_delete.jpg',
        );

        fileStore.shouldThrowOnDelete = true;

        final result = await cleaner.cleanUpPhoto(photoPath);

        expect(result, equals(PhotoCleanupResult.failed));
        expect(await fileStore.exists(photoPath), isTrue);
      },
    );
  });
}
