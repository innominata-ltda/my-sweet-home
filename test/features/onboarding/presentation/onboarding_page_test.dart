import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_providers.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';

import '../../../../test/fakes/fake_dashboard_layout_repository.dart';
import '../../../../test/fakes/fake_settings_repository.dart';

void main() {
  group(
    'T-B01: Passo 7 do Onboarding sob escala de fonte 200% (CA-285.2, RNF-006)',
    () {
      late FakeMascotRepository fakeMascotRepo;
      late FakeSettingsRepository fakeSettingsRepo;
      late FakeDashboardLayoutRepository fakeDashboardRepo;

      setUp(() {
        fakeMascotRepo = FakeMascotRepository();
        fakeSettingsRepo = FakeSettingsRepository();
        fakeDashboardRepo = FakeDashboardLayoutRepository(
          initialConfig: const DashboardLayoutConfig(visibleItems: []),
        );
      });

      tearDown(() {
        fakeMascotRepo.dispose();
      });

      Widget buildSubject({
        VoidCallback? onComplete,
        VoidCallback? onCustomize,
        int initialStep = 7,
        double textScaleFactor = 2.0,
      }) {
        return ProviderScope(
          overrides: [
            mascotRepositoryProvider.overrideWithValue(fakeMascotRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            dashboardLayoutRepositoryProvider.overrideWithValue(
              fakeDashboardRepo,
            ),
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
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: true,
              ),
              child: Consumer(
                builder: (context, ref, _) => OnboardingPage(
                  onComplete: onComplete,
                  onCustomize: onCustomize,
                  initialStep: initialStep,
                  disableAnimations: true,
                  onCompleteWithChecklist: (activate) async {
                    if (activate) {
                      await ref
                          .read(dashboardLayoutControllerProvider)
                          .show(DashboardItemKind.firstHomeChecklist);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      }

      testWidgets(
        'Botão secundário "Personalizar agora" e botão principal "Começar" são visíveis e acionáveis com fonte 200%',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          var customized = false;
          var completed = false;

          await tester.pumpWidget(
            buildSubject(
              initialStep: 7,
              textScaleFactor: 2.0,
              onCustomize: () => customized = true,
              onComplete: () => completed = true,
            ),
          );
          await tester.pumpAndSettle();

          // 1. Sem overflow
          expect(tester.takeException(), isNull);

          // 2. Verify secondary tonal button "Customize now" exists
          final customizeBtn = find.byKey(
            const Key('onboarding_customize_button'),
          );
          expect(customizeBtn, findsOneWidget);
          expect(find.text('Personalizar agora'), findsOneWidget);

          // 3. Ensure visibility and trigger of secondary button
          await tester.ensureVisible(customizeBtn);
          await tester.pumpAndSettle();
          await tester.tap(customizeBtn);
          await tester.pumpAndSettle();
          expect(customized, isTrue);

          // 4. Verify primary button "Start" exists and can be triggered
          final startBtn = find.byKey(const Key('onboarding_start_button'));
          expect(startBtn, findsOneWidget);
          expect(find.text('Começar'), findsOneWidget);

          await tester.tap(startBtn);
          await tester.pumpAndSettle();
          expect(completed, isTrue);
        },
      );

      testWidgets(
        'CA-2.1: Optar por ativar Checklist da Primeira Casa no passo 7 ativa o item e grava onboarding_completed',
        (tester) async {
          var completed = false;
          await tester.pumpWidget(
            buildSubject(
              initialStep: 6, // Step 7 (index 6): "Setting up your new home?"
              textScaleFactor: 1.0,
              onComplete: () => completed = true,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Está montando sua casa nova?'), findsOneWidget);

          // Click button to activate checklist
          final enableBtn = find.byKey(
            const Key('onboarding_enable_checklist_button'),
          );
          expect(enableBtn, findsOneWidget);
          await tester.ensureVisible(enableBtn);
          await tester.pumpAndSettle();
          await tester.tap(enableBtn);
          await tester.pumpAndSettle();

          // Agora deve estar no passo 8
          expect(
            find.text('Pode personalizar meu visual quando quiser!'),
            findsOneWidget,
          );

          // Conclui o onboarding
          final startBtn = find.byKey(const Key('onboarding_start_button'));
          await tester.tap(startBtn);
          await tester.pumpAndSettle();

          expect(completed, isTrue);
          expect(await fakeSettingsRepo.isOnboardingCompleted(), isTrue);

          final layoutRes = await fakeDashboardRepo.load();
          expect(
            layoutRes.valueOrNull?.visibleItems.contains(
              DashboardItemKind.firstHomeChecklist,
            ),
            isTrue,
          );
        },
      );

      testWidgets(
        'CA-2.2: Escolher "Já tenho tudo / Pular" no passo 7 conclui sem forçar checklist',
        (tester) async {
          var completed = false;
          await tester.pumpWidget(
            buildSubject(
              initialStep: 6,
              textScaleFactor: 1.0,
              onComplete: () => completed = true,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Está montando sua casa nova?'), findsOneWidget);

          final skipBtn = find.byKey(
            const Key('onboarding_skip_checklist_button'),
          );
          expect(skipBtn, findsOneWidget);
          await tester.ensureVisible(skipBtn);
          await tester.pumpAndSettle();
          await tester.tap(skipBtn);
          await tester.pumpAndSettle();

          // Agora deve estar no passo 8
          expect(
            find.text('Pode personalizar meu visual quando quiser!'),
            findsOneWidget,
          );

          // Conclui o onboarding
          final startBtn = find.byKey(const Key('onboarding_start_button'));
          await tester.tap(startBtn);
          await tester.pumpAndSettle();

          expect(completed, isTrue);
          expect(await fakeSettingsRepo.isOnboardingCompleted(), isTrue);

          final layoutRes = await fakeDashboardRepo.load();
          expect(
            layoutRes.valueOrNull?.visibleItems.contains(
              DashboardItemKind.firstHomeChecklist,
            ),
            isFalse,
          );
        },
      );
    },
  );
}
