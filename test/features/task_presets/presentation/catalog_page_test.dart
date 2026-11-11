import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/features/task_presets/presentation/task_preset_catalog_page.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/fake_task_from_preset.dart';
import '../../../fakes/fake_task_preset_catalog.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: child,
    ),
  );
}

void main() {
  late FakeClock clock;
  late FakeTaskPresetCatalog fakeCatalogPort;
  late FakeTaskFromPreset fakeTaskFromPresetPort;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
    fakeTaskFromPresetPort = FakeTaskFromPreset();
  });

  group('CA-1.4 & CA-2.2: TaskPresetCatalogPage widget tests', () {
    testWidgets(
      'CA-1.4: Abre criação pré-preenchida e cancela -> create não é chamado',
      (tester) async {
        TaskDraft? openedDraft;

        await tester.pumpWidget(
          _wrap(
            TaskPresetCatalogPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
              onOpenDraft: (draft) {
                openedDraft = draft;
                // Simulates user cancelled and did not call create
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Finds task and taps
        expect(find.text('Varrer o chão'), findsOneWidget);
        await tester.ensureVisible(find.text('Varrer o chão'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Varrer o chão'));
        await tester.pumpAndSettle();

        // Confirma que o rascunho correto foi aberto
        expect(openedDraft, isNotNull);
        expect(openedDraft!.title, 'Varrer o chão');
        expect(openedDraft!.sourcePresetId, 'sweep-floor');
        expect(openedDraft!.rrule, 'FREQ=DAILY;INTERVAL=3');

        // Since user cancelled, fakeTaskFromPresetPort.create was not called
        expect(fakeTaskFromPresetPort.created, isEmpty);
        expect(fakeTaskFromPresetPort.receivedDrafts, isEmpty);
      },
    );

    testWidgets(
      'CA-2.2: Busca "limpar aquário" exibe CTA e cria com esse título e sem recorrência',
      (tester) async {
        TaskDraft? openedDraft;

        await tester.pumpWidget(
          _wrap(
            TaskPresetCatalogPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
              onOpenDraft: (draft) {
                openedDraft = draft;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Types search query
        await tester.enterText(find.byType(TextField), 'limpar aquário');
        await tester.pumpAndSettle();

        // Sweep floor and others should no longer appear
        expect(find.text('Varrer o chão'), findsNothing);

        // Deve aparecer o CTA "Criar tarefa personalizada"
        expect(find.text('Criar tarefa personalizada'), findsOneWidget);

        // Toca no CTA
        await tester.tap(find.text('Criar tarefa personalizada'));
        await tester.pumpAndSettle();

        // Verifica o rascunho gerado
        expect(openedDraft, isNotNull);
        expect(openedDraft!.title, 'limpar aquário');
        expect(openedDraft!.rrule, isNull);
        expect(openedDraft!.sourcePresetId, isNull);
      },
    );
  });
}
