import 'dart:typed_data';

import 'package:my_sweet_home/features/ocr/domain/models/quality_report.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_quality_port.dart';

/// Fake para testes de [ImageQualityPort] / [ImageQualityChecker] (RN-204).
class FakeImageQualityChecker implements ImageQualityPort {
  QualityReport? reportToReturn;
  Uint8List? lastAssessedRaw;
  int assessCallCount = 0;

  FakeImageQualityChecker({this.reportToReturn});

  @override
  Future<QualityReport> assess(Uint8List raw) async {
    assessCallCount++;
    lastAssessedRaw = raw;
    if (reportToReturn != null) {
      return reportToReturn!;
    }
    return const QualityReport(isAcceptable: true, issues: []);
  }
}
