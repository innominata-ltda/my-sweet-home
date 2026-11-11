import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/features/sync/data/bundle_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/household_repository_provider.dart';
import 'package:my_sweet_home/features/sync/presentation/bundle/bundle_import_dialog.dart';

class _FakeBundleSyncTransport implements BundleSyncTransport {
  final Result<ApplyReport, Failure> Function(Uint8List) onApply;

  _FakeBundleSyncTransport({required this.onApply});

  @override
  Future<Result<ApplyReport, Failure>> applyBundle(Uint8List bytes) async {
    return onApply(bytes);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BundleImportDialog return messages (RN-409, CA-2.7)', () {
    Widget buildSubject(BundleSyncTransport transport) {
      return ProviderScope(
        overrides: [bundleSyncTransportProvider.overrideWithValue(transport)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_dialog_button'),
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => const BundleImportDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'displays already applied message when applyBundle returns alreadyApplied=true (CA-2.7)',
      (tester) async {
        final transport = _FakeBundleSyncTransport(
          onApply: (_) => const Ok(ApplyReport(alreadyApplied: true)),
        );

        await tester.pumpWidget(buildSubject(transport));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('import_bundle_dialog')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('bundle_input_field')),
          'fake-bundle-payload',
        );
        await tester.tap(find.byKey(const Key('confirm_import_button')));
        await tester.pumpAndSettle();

        // Dialog closed and already applied snackbar appeared
        expect(find.byKey(const Key('import_bundle_dialog')), findsNothing);
        expect(find.text('Este pacote já foi aplicado'), findsOneWidget);
        expect(
          find.byKey(const Key('bundle_already_applied_snack')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays success message when applyBundle returns alreadyApplied=false',
      (tester) async {
        final transport = _FakeBundleSyncTransport(
          onApply: (_) => const Ok(
            ApplyReport(
              appliedChangesCount: 3,
              touchedTables: {'tasks'},
              touchedRowIds: {'task-1'},
              alreadyApplied: false,
            ),
          ),
        );

        await tester.pumpWidget(buildSubject(transport));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('bundle_input_field')),
          'fake-bundle-payload',
        );
        await tester.tap(find.byKey(const Key('confirm_import_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('import_bundle_dialog')), findsNothing);
        expect(find.text('Pacote aplicado com sucesso!'), findsOneWidget);
      },
    );
  });
}
