// Smoke test: app does not throw exception on initialization.
// Real tests will be added in T-16 when public App exists.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp instantiates without exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
