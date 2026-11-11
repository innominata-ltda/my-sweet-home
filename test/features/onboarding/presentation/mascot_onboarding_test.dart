import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';
import 'package:my_sweet_home/features/task_presets/presentation/onboarding_routine_step.dart';

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
      theme: lightTheme(),
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
  late FakeMascotRepository fakeMascotRepo;
  late FakeClock clock;
  late FakeTaskPresetCatalog fakeCatalogPort;
  late FakeTaskFromPreset fakeTaskFromPresetPort;

  setUp(() {
    fakeMascotRepo = FakeMascotRepository();
    clock = FakeClock(DateTime.utc(2026, 3, 10));
    fakeCatalogPort = FakeTaskPresetCatalog.defaultFixture();
    fakeTaskFromPresetPort = FakeTaskFromPreset();
  });

  tearDown(() {
    fakeMascotRepo.dispose();
  });

  group(
    'CA-009.1 & SPEC-014: 7 passos no Onboarding com rotina no passo 6',
    () {
      testWidgets(
        'Os 7 passos da SPEC-012 continuam nesta ordem com o catálogo de rotina no passo 6',
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

          final pageView = tester.widget<PageView>(find.byType(PageView));
          final delegate = pageView.childrenDelegate as SliverChildListDelegate;
          expect(delegate.children.length, equals(8));

          // Passo 1: waving
          expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);
          var mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.waving));

          // Passo 2: pointing
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(
            find.text('Aqui a gente cuida do dinheirinho juntas'),
            findsOneWidget,
          );
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.pointing));

          // Passo 3: shopping
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(find.text('E também das comprinhas!'), findsOneWidget);
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.shopping));

          // Passo 4: happy
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(
            find.text('Não esquece das tarefinhas do dia'),
            findsOneWidget,
          );
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.happy));

          // Passo 5: budget
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(
            find.text('Eu te aviso quando algo precisa de atenção'),
            findsOneWidget,
          );
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.budget));

          // Step 6: OnboardingRoutineStep (home catalog)
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(find.byType(OnboardingRoutineStep), findsOneWidget);
          expect(find.text('Monte sua rotina da casa'), findsOneWidget);

          // Passo 7: Checklist da Primeira Casa (SPEC-015)
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(find.text('Está montando sua casa nova?'), findsOneWidget);
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.happy));

          // Passo 8: relaxed
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(
            find.text('Pode personalizar meu visual quando quiser!'),
            findsOneWidget,
          );
          expect(
            find.text('Quer personalizar meu visual agora?'),
            findsOneWidget,
          );
          mascotWidget = tester.widget<MascotWidget>(
            find.byType(MascotWidget).first,
          );
          expect(mascotWidget.expression, equals(MascotExpression.relaxed));
        },
      );
    },
  );
}
