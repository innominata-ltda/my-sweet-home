import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/image_preprocessor_adapter.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/ml_kit_text_recognizer_adapter.dart';
import 'package:my_sweet_home/features/ocr/data/sqlite_save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_preprocessor_port.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/text_recognizer_port.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';

final imagePreprocessorProvider = Provider<ImagePreprocessorPort>((ref) {
  return const ImagePreprocessorAdapter();
});

final textRecognizerProvider = Provider<TextRecognizerPort>((ref) {
  final adapter = MlKitTextRecognizerAdapter();
  ref.onDispose(adapter.close);
  return adapter;
});

final saveReceiptUseCaseProvider = Provider<SaveReceiptUseCase>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final idGen = ref.watch(idGeneratorProvider);
  return SqliteSaveReceiptUseCase(db, clock: clock, idGenerator: idGen);
});
