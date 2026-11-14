import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/presentation/onboarding_routine_step.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/preset_tile.dart';

class _StubCatalogPort implements TaskPresetCatalogPort {
  _StubCatalogPort(this.responses);

  final List<Result<TaskPresetCatalog, Failure>> responses;
  int calls = 0;

  @override
  Future<Result<TaskPresetCatalog, Failure>> load() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}

class _StubTaskFromPresetPort implements TaskFromPresetPort {
  @override
  Future<Result<Set<String>, Failure>> activeOriginPresetIds() async =>
      const Ok({'wash-dishes'});

  @override
  Future<Result<CreatedTask, Failure>> create(TaskDraft draft) async =>
      const Err(StorageFailure(detail: 'unused'));

  @override
  Future<Result<List<CreatedTask>, Failure>> createBatch(
    List<TaskDraft> drafts,
  ) async => const Ok([]);

  @override
  Future<Result<void, Failure>> undoBatch(List<TrashTicket> tickets) async =>
      const Ok(null);
}

void main() {
  group('pubspec.yaml flutter section', () {
    test('declares assets and fonts under flutter, separate from hooks', () {
      final lines = File('pubspec.yaml').readAsLinesSync();
      String? currentTopLevel;
      final flutterChildren = <String>[];
      final hooksChildren = <String>[];

      for (final rawLine in lines) {
        final line = rawLine.trimRight();
        if (line.isEmpty || line.trimLeft().startsWith('#')) {
          continue;
        }
        if (!line.startsWith(' ') && line.endsWith(':')) {
          currentTopLevel = line.substring(0, line.length - 1);
          continue;
        }
        if (line.startsWith('  ') && !line.startsWith('    ')) {
          final key = line.trim().split(':').first;
          if (currentTopLevel == 'flutter') {
            flutterChildren.add(key);
          } else if (currentTopLevel == 'hooks') {
            hooksChildren.add(key);
          }
        }
      }

      expect(flutterChildren, containsAll(['assets', 'fonts']));
      expect(hooksChildren, contains('user_defines'));
      expect(hooksChildren, isNot(contains('assets')));
      expect(hooksChildren, isNot(contains('fonts')));
    });
  });

  group('OnboardingRoutineStep', () {
    const sampleCatalog = TaskPresetCatalog(
      version: 1,
      presets: [
        TaskPreset(
          id: 'wash-dishes',
          area: TaskPresetArea.kitchen,
          title: 'Lavar louça',
          recommendedRrule: 'FREQ=DAILY;INTERVAL=1',
          rationale: 'Evita acúmulo.',
        ),
        TaskPreset(
          id: 'clean-sink',
          area: TaskPresetArea.bathroom,
          title: 'Limpar pia',
          recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
          rationale: 'Higiene básica.',
        ),
      ],
    );

    testWidgets('renders presets and reports selection changes', (
      tester,
    ) async {
      List<TaskPreset> selected = [];
      final catalogPort = _StubCatalogPort([const Ok(sampleCatalog)]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OnboardingRoutineStep(
                catalogPort: catalogPort,
                taskFromPresetPort: _StubTaskFromPresetPort(),
                onSelectionChanged: (items) => selected = items,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TaskPresetTile), findsNWidgets(2));
      expect(find.text('Lavar louça'), findsOneWidget);
      expect(find.text('Limpar pia'), findsOneWidget);

      await tester.tap(find.text('Limpar pia'));
      await tester.pumpAndSettle();

      expect(selected.map((p) => p.id), ['clean-sink']);
    });

    testWidgets('shows error and recovers on retry when catalog fails', (
      tester,
    ) async {
      final catalogPort = _StubCatalogPort([
        const Err(StorageFailure(detail: 'Asset missing')),
        const Ok(sampleCatalog),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OnboardingRoutineStep(
                catalogPort: catalogPort,
                taskFromPresetPort: _StubTaskFromPresetPort(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_routine_error')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_routine_retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_routine_retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_routine_error')), findsNothing);
      expect(find.byType(TaskPresetTile), findsNWidgets(2));
    });
  });
}
