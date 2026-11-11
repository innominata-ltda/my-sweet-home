import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';

import '../../../../test/fakes/fake_clock.dart';
import '../../../../test/fakes/fake_task_from_preset.dart';
import '../../../../test/fakes/fake_task_preset_catalog.dart';

Widget _wrap({required Widget child, FakeMascotRepository? mascotRepo}) {
  return ProviderScope(
    overrides: [
      if (mascotRepo != null)
        mascotRepositoryProvider.overrideWithValue(mascotRepo),
    ],
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
  late FakeMascotRepository fakeMascotRepo;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
    fakeTaskFromPresetPort = FakeTaskFromPreset();
    fakeMascotRepo = FakeMascotRepository();
  });

  tearDown(() {
    fakeMascotRepo.dispose();
  });

  group('CA-8.1..CA-8.4: Passo "Monte sua rotina da casa" no Onboarding', () {
    testWidgets(
      'CA-8.1: Passo "Monte sua rotina da casa" aparece após explicativas e antes da personalização',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: OnboardingPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
            ),
            mascotRepo: fakeMascotRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Advance through first 5 explanatory steps
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
        }

        // At step 6 (index 5): Set up your home routine
        expect(find.text('Monte sua rotina da casa'), findsOneWidget);
        expect(
          find.text(
            'Escolha tarefas comuns para começar sua rotina sem complicação. Você pode mudar tudo depois!',
          ),
          findsOneWidget,
        );
        // "Want to customize my look now?" must NOT be visible yet
        expect(find.text('Quer personalizar meu visual agora?'), findsNothing);

        // Advance from step 6 to step 7 without selecting anything
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();

        // Passo 7: Checklist Primeira Casa (SPEC-015)
        expect(find.text('Está montando sua casa nova?'), findsOneWidget);

        // Advance to step 8
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();

        // Now customization is visible
        expect(
          find.text('Quer personalizar meu visual agora?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CA-8.2: Seleciona 4 predefinições, confirma datas e segue -> 4 tarefas criadas e segue para personalização',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            child: OnboardingPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
              initialStep: 5, // Inicia diretamente no passo da rotina
            ),
            mascotRepo: fakeMascotRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Monte sua rotina da casa'), findsOneWidget);

        // Seleciona 4 checkboxes
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsWidgets);
        for (var i = 0; i < 4; i++) {
          await tester.tap(checkboxes.at(i));
          await tester.pumpAndSettle();
        }

        // Tap Next
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();

        // BatchStartDatesSheet is displayed with "Confirm routine"
        expect(find.text('Confirmar rotina'), findsOneWidget);

        // Confirm start dates
        await tester.tap(find.text('Confirmar rotina'));
        await tester.pumpAndSettle();

        // 4 tasks were recorded in fake repository
        expect(fakeTaskFromPresetPort.created.length, 4);

        // O onboarding continuou para o passo 7 (Checklist)
        expect(find.text('Está montando sua casa nova?'), findsOneWidget);

        // Advance to Momo customization offer (step 8)
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Quer personalizar meu visual agora?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CA-8.3: Tocar em "Pular este passo" não cria tarefas e nenhum dado pessoal é pedido',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: OnboardingPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: fakeTaskFromPresetPort,
              clock: clock,
              initialStep: 5,
            ),
            mascotRepo: fakeMascotRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Monte sua rotina da casa'), findsOneWidget);

        // Seleciona uma tarefa
        final checkboxes = find.byType(Checkbox);
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Toca em "Pular este passo"
        final skipFinder = find.text('Pular este passo');
        expect(skipFinder, findsOneWidget);
        await tester.tap(skipFinder);
        await tester.pumpAndSettle();

        // Nenhuma tarefa criada
        expect(fakeTaskFromPresetPort.created, isEmpty);

        // Segue para o passo 7 (Checklist)
        expect(find.text('Está montando sua casa nova?'), findsOneWidget);

        // Advance to customization (step 8)
        await tester.tap(find.byKey(const Key('onboarding_next_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Quer personalizar meu visual agora?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CA-8.4: Quando "Varrer o chão" já está ativa na rotina, reabrir tutorial exibe a marcação',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final portWithSweep = FakeTaskFromPreset(activeIds: {'sweep-floor'});

        await tester.pumpWidget(
          _wrap(
            child: OnboardingPage(
              catalogPort: fakeCatalogPort,
              taskFromPresetPort: portWithSweep,
              clock: clock,
              initialStep: 5,
            ),
            mascotRepo: fakeMascotRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Verify "Already in your routine" badge appears
        expect(find.text('Varrer o chão'), findsOneWidget);
        expect(find.text('Já na sua rotina'), findsOneWidget);
      },
    );
  });
}
