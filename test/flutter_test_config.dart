import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden comparator with tolerance for antialiasing and font rendering
/// entre diferentes sistemas operacionais (Windows vs Linux no CI).
class TolerantGoldenFileComparator extends LocalFileComparator {
  final double tolerance;

  TolerantGoldenFileComparator(super.testFile, {this.tolerance = 0.035});

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final original = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = TolerantGoldenFileComparator(
      original.basedir.resolve('test.dart'),
      tolerance: 0.035,
    );
  }
  await testMain();
}
