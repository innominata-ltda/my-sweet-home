import 'dart:typed_data';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';

class ExportedFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  const ExportedFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

abstract interface class ExpenseExporter {
  Future<Result<ExportedFile, Failure>> toCsv(DateRange range);
  Future<Result<ExportedFile, Failure>> toPdf(DateRange range);
}
