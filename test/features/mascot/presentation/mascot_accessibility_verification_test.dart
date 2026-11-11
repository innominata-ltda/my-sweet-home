import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_controller.dart';
import 'package:my_sweet_home/features/mascot/presentation/pages/mascot_customization_page.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../../../fakes/fake_bill_payment_repository.dart';
import '../../../fakes/fake_bill_repository.dart';
import '../../../fakes/sequential_id_generator.dart';

class _FakeResolver implements MascotAssetResolver {
  const _FakeResolver();

  @override
  String get fallbackPlaceholderPath => 'assets/mascots/placeholder.webp';

  @override
  String resolveExpressionPath(
    MascotAnimal animal,
    MascotExpression expression,
  ) => fallbackPlaceholderPath;

  @override
  String resolveAnimationPath(String animationName) =>
      'assets/lottie/$animationName.json';

  @override
  bool hasExpressionAsset(MascotAnimal animal, MascotExpression expression) =>
      false;

  @override
  bool hasAnimationAsset(String animationName) => false;
}

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  MonthSummary summary;
  _FakeMonthSummaryRepo(this.summary);

  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async =>
      Ok(summary);
}

class _FakeTaskRepo implements TaskRepository {
  List<task_models.Task> tasks;
  _FakeTaskRepo(this.tasks);

  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async => Ok(tasks);

  @override
  Future<Result<task_models.Task, Failure>> complete(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  Future<Result<task_models.Task, Failure>> uncomplete(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  Future<Result<task_models.Task, Failure>> upsert(
    task_models.NewTask t,
  ) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteLocalPermanently(
    task_models.TaskId id,
  ) async => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShoppingListRepo implements ShoppingListRepository {
  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async => const Ok([]);

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async => const Ok(null);
}

void main() {
  group('SPEC-012/T-V2 — Acessibilidade e Layout Momo (CA-285.2, CA-289.1, CA-290.1, RNF-011, A11Y-2, A11Y-3)', () {
    late FakeMascotRepository fakeMascotRepo;
    late _FakeMonthSummaryRepo fakeMonthRepo;
    late _FakeTaskRepo fakeTaskRepo;
    late BillRepository fakeBillRepo;
    late BillPaymentRepository fakePaymentRepo;
    late _FakeShoppingListRepo fakeShoppingRepo;

    final testMonth = YearMonth('2026-10');

    setUp(() {
      fakeMascotRepo = FakeMascotRepository();
      fakeMonthRepo = _FakeMonthSummaryRepo(
        MonthSummary(
          month: testMonth,
          actual: const Money(45000),
          budget: const Money(100000),
          remaining: const Money(55000),
          byCategory: const [],
          monthsOfHistory: 1,
        ),
      );
      fakeTaskRepo = _FakeTaskRepo([]);
      fakeBillRepo = FakeBillRepository(SequentialIdGenerator());
      fakePaymentRepo = FakeBillPaymentRepository();
      fakeShoppingRepo = _FakeShoppingListRepo();
    });

    tearDown(() {
      fakeMascotRepo.dispose();
    });

    void setScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget wrapWithApp({
      required Widget child,
      double textScaleFactor = 1.0,
      bool disableAnimations = false,
      bool wrapWithScaffold = false,
    }) {
      final effectiveChild = wrapWithScaffold
          ? Scaffold(body: Center(child: child))
          : child;
      return ProviderScope(
        overrides: [
          mascotRepositoryProvider.overrideWithValue(fakeMascotRepo),
          mascotConfigStreamProvider.overrideWith(
            (ref) => fakeMascotRepo.watchConfig(),
          ),
          monthSummaryRepositoryProvider.overrideWithValue(fakeMonthRepo),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          billRepositoryProvider.overrideWithValue(fakeBillRepo),
          billPaymentRepositoryProvider.overrideWithValue(fakePaymentRepo),
          shoppingListRepositoryProvider.overrideWithValue(fakeShoppingRepo),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'BR'),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
              disableAnimations: disableAnimations,
            ),
            child: effectiveChild,
          ),
        ),
      );
    }

    // =========================================================================
    // 1. Escala de fonte a 200% (TextScaler.linear(2.0), CA-285.2, RNF-011)
    // =========================================================================
    group('1. Escala de fonte ampliada a 200% (CA-285.2, RNF-011)', () {
      testWidgets('MascotWidget renders without overflow in multiple sizes', (
        tester,
      ) async {
        setScreenSize(tester);
        await tester.pumpWidget(
          wrapWithApp(
            textScaleFactor: 2.0,
            wrapWithScaffold: true,
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  MascotWidget(
                    config: MascotConfig.defaultMomo,
                    expression: MascotExpression.neutral,
                    size: 32,
                  ),
                  MascotWidget(
                    config: MascotConfig.defaultMomo,
                    expression: MascotExpression.happy,
                    size: 64,
                  ),
                  MascotWidget(
                    config: MascotConfig.defaultMomo,
                    expression: MascotExpression.pointing,
                    size: 96,
                  ),
                  MascotWidget(
                    config: MascotConfig.defaultMomo,
                    expression: MascotExpression.budget,
                    size: 140,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(MascotWidget), findsNWidgets(4));
      });

      testWidgets('CuteCheckbox renderiza sem overflow com textScale 2.0', (
        tester,
      ) async {
        setScreenSize(tester);
        await tester.pumpWidget(
          wrapWithApp(
            textScaleFactor: 2.0,
            wrapWithScaffold: true,
            child: Row(
              children: [
                CuteCheckbox(
                  value: true,
                  onChanged: (_) {},
                  animal: MascotAnimal.cat,
                ),
                CuteCheckbox(
                  value: false,
                  onChanged: (_) {},
                  animal: MascotAnimal.bunny,
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(CuteCheckbox), findsNWidgets(2));
      });

      testWidgets(
        'CelebrationOverlay suporta textScale 2.0 sem RenderFlex overflow',
        (tester) async {
          setScreenSize(tester);
          await tester.pumpWidget(
            wrapWithApp(
              textScaleFactor: 2.0,
              wrapWithScaffold: true,
              child: const CelebrationOverlay(
                title: 'Parabéns por completar todas as tarefas do dia!',
                message: 'Você completou cada compromisso com muito carinho e organização!',
                duration: Duration.zero,
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.byType(CelebrationOverlay), findsOneWidget);
          expect(find.byType(MascotWidget), findsOneWidget);
        },
      );

      testWidgets(
        'OnboardingPage: todos os 7 passos sem RenderFlex overflow em textScale 2.0',
        (tester) async {
          setScreenSize(tester);

          await tester.pumpWidget(
            wrapWithApp(textScaleFactor: 2.0, child: const OnboardingPage()),
          );
          await tester.pumpAndSettle();

          for (var step = 0; step < 7; step++) {
            expect(tester.takeException(), isNull);
            expect(find.byType(MascotWidget), findsAtLeastNWidgets(1));

            if (step < 6) {
              final nextButton = find.byKey(
                const Key('onboarding_next_button'),
              );
              expect(nextButton, findsOneWidget);
              await tester.tap(nextButton);
              await tester.pumpAndSettle();
            }
          }
        },
      );

      testWidgets(
        'MascotCustomizationPage suporta textScale 2.0 sem overflow em tela mobile',
        (tester) async {
          setScreenSize(tester);

          final controller = MascotCustomizationController(
            repository: fakeMascotRepo,
            initialConfig: MascotConfig.defaultMomo,
          );

          await tester.pumpWidget(
            wrapWithApp(
              textScaleFactor: 2.0,
              child: MascotCustomizationPage(
                controller: controller,
                resolver: const _FakeResolver(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('mascot_preview_card')), findsOneWidget);
          expect(find.byKey(const Key('mascot_name_field')), findsOneWidget);
          expect(find.byKey(const Key('mascot_save_button')), findsOneWidget);
          expect(find.byKey(const Key('mascot_cancel_button')), findsOneWidget);

          controller.dispose();
        },
      );

      testWidgets(
        'DashboardScreen suporta textScale 2.0 sem RenderFlex overflow',
        (tester) async {
          setScreenSize(tester);

          await tester.pumpWidget(
            wrapWithApp(textScaleFactor: 2.0, child: const DashboardScreen()),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('dashboard_mascot_greeting_card')),
            findsOneWidget,
          );
          expect(find.byType(MascotWidget), findsAtLeastNWidgets(1));
        },
      );

      testWidgets(
        'AppEmptyState.mascot suporta textScale 2.0 sem RenderFlex overflow',
        (tester) async {
          setScreenSize(tester);
          await tester.pumpWidget(
            wrapWithApp(
              textScaleFactor: 2.0,
              wrapWithScaffold: true,
              child: const AppEmptyState.mascot(
                title: 'Nenhuma despesa registrada ainda',
                description: 'Toque no botão abaixo para adicionar a primeira continha do mês e começar a economizar!',
                mascotExpression: MascotExpression.thinking,
                actionLabel: 'Lançar despesa',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(AppEmptyState), findsOneWidget);
          expect(find.byType(MascotWidget), findsOneWidget);
        },
      );

      testWidgets(
        'Edge case: OnboardingPage suporta viewport estreito (320x640) com textScale 2.0',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithApp(textScaleFactor: 2.0, child: const OnboardingPage()),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('onboarding_skip_button')),
            findsOneWidget,
          );
        },
      );
    });

    // =========================================================================
    // 2. Semantic labels and traits (CA-289.1, CA-290.1, A11Y-3)
    // =========================================================================
    group('2. Semantic labels and traits (CA-289.1, CA-290.1, A11Y-3)', () {
      testWidgets(
        'CA-289.1: MascotWidget em empty state anuncia rótulo contextual contextualizado',
        (tester) async {
          final handle = tester.ensureSemantics();

          const emptyLabel =
              'Momo está pensativa — nenhuma despesa registrada ainda';

          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              child: const MascotWidget(
                config: MascotConfig.defaultMomo,
                expression: MascotExpression.thinking,
                semanticLabel: emptyLabel,
              ),
            ),
          );
          await tester.pump();

          expect(find.bySemanticsLabel(emptyLabel), findsOneWidget);

          handle.dispose();
        },
      );

      testWidgets(
        'RN-289 & A11Y-3: Todas as 10 expressões têm descrições contextuais em pt-BR por padrão',
        (tester) async {
          final handle = tester.ensureSemantics();

          final expectedDescriptions = <MascotExpression, String>{
            MascotExpression.neutral: 'Momo está te acompanhando com atenção',
            MascotExpression.happy: 'Momo está muito feliz com o seu progresso',
            MascotExpression.worried: 'Momo está com carinha de preocupação',
            MascotExpression.sleepy: 'Momo está com soninho e descansando',
            MascotExpression.pointing: 'Momo está apontando para esta seção',
            MascotExpression.waving: 'Momo está dando um oizinho carinhoso',
            MascotExpression.thinking: 'Momo está pensando com carinho',
            MascotExpression.relaxed: 'Momo está relaxando tranquilamente',
            MascotExpression.shopping: 'Momo está animada para as comprinhas',
            MascotExpression.budget: 'Momo está de olho no orçamento',
          };

          for (final entry in expectedDescriptions.entries) {
            await tester.pumpWidget(
              wrapWithApp(
                wrapWithScaffold: true,
                child: MascotWidget(
                  config: MascotConfig.defaultMomo,
                  expression: entry.key,
                ),
              ),
            );
            await tester.pump();

            expect(
              find.bySemanticsLabel(entry.value),
              findsOneWidget,
              reason:
                  'Expressão ${entry.key.name} deve ter descrição contextual correta',
            );
          }

          handle.dispose();
        },
      );

      testWidgets('MascotWidget with onTap exposes accessible button traits', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          wrapWithApp(
            wrapWithScaffold: true,
            child: MascotWidget(
              config: MascotConfig.defaultMomo,
              expression: MascotExpression.happy,
              onTap: () {},
            ),
          ),
        );
        await tester.pump();

        final semantics = tester
            .getSemantics(find.byType(MascotWidget))
            .getSemanticsData();
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(semantics.flagsCollection.isButton, isTrue);

        handle.dispose();
      });

      testWidgets(
        'MascotWidget com isDecorative: true é excluído da árvore semântica',
        (tester) async {
          final handle = tester.ensureSemantics();

          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              child: const MascotWidget(
                config: MascotConfig.defaultMomo,
                expression: MascotExpression.happy,
                isDecorative: true,
              ),
            ),
          );
          await tester.pump();

          expect(
            find.bySemanticsLabel('Momo está muito feliz com o seu progresso'),
            findsNothing,
          );

          handle.dispose();
        },
      );

      testWidgets(
        'CuteCheckbox expõe ação TalkBack pt-BR e traits de checkbox',
        (tester) async {
          final handle = tester.ensureSemantics();

          // Unchecked state
          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              child: CuteCheckbox(
                value: false,
                onChanged: (_) {},
                animal: MascotAnimal.cat,
              ),
            ),
          );
          await tester.pump();

          expect(find.bySemanticsLabel('Marcar (pata)'), findsOneWidget);
          var semanticsData = tester
              .getSemantics(find.byType(CuteCheckbox))
              .getSemanticsData();
          expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
          expect(semanticsData.flagsCollection.isChecked, CheckedState.isFalse);
          expect(semanticsData.flagsCollection.isEnabled, Tristate.isTrue);

          // Checked state with rabbit (heart)
          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              child: CuteCheckbox(
                value: true,
                onChanged: (_) {},
                animal: MascotAnimal.bunny,
              ),
            ),
          );
          await tester.pump();

          expect(find.bySemanticsLabel('Desmarcar (coração)'), findsOneWidget);
          semanticsData = tester
              .getSemantics(find.byType(CuteCheckbox))
              .getSemanticsData();
          expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
          expect(semanticsData.flagsCollection.isChecked, CheckedState.isTrue);
          expect(semanticsData.flagsCollection.isEnabled, Tristate.isTrue);

          handle.dispose();
        },
      );

      testWidgets(
        'CelebrationOverlay anuncia liveRegion acessível com título e mensagem',
        (tester) async {
          final handle = tester.ensureSemantics();

          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              child: const CelebrationOverlay(
                title: 'Tudo pronto!',
                message: 'Você completou tudo com muito carinho!',
                duration: Duration.zero,
              ),
            ),
          );
          await tester.pump();

          final celebrationFinder = find.bySemanticsLabel(
            'Tudo pronto!. Você completou tudo com muito carinho!',
          );
          expect(celebrationFinder, findsOneWidget);

          final semanticsData = tester
              .getSemantics(celebrationFinder)
              .getSemanticsData();
          expect(semanticsData.flagsCollection.isLiveRegion, isTrue);

          handle.dispose();
        },
      );

      testWidgets(
        'CA-290.1: disableAnimations = true mantém MascotWidget e CelebrationOverlay estáticos',
        (tester) async {
          // Animated MascotWidget must stop controller when disableAnimations is true
          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              disableAnimations: true,
              child: const MascotWidget.animated(
                config: MascotConfig.defaultMomo,
              ),
            ),
          );
          await tester.pump();

          final mascotState = tester.state<MascotWidgetState>(
            find.byType(MascotWidget),
          );
          expect(mascotState.isAnimating, isFalse);
          expect(mascotState.animationController.value, 0.0);

          await tester.pump(const Duration(seconds: 1));
          expect(mascotState.isAnimating, isFalse);
          expect(mascotState.animationController.value, 0.0);

          // CelebrationOverlay with disableAnimations: true does not render animated confetti painter
          await tester.pumpWidget(
            wrapWithApp(
              wrapWithScaffold: true,
              disableAnimations: true,
              child: const CelebrationOverlay(
                title: 'Comemoração estática',
                message: 'Sem animações decorativas quando solicitado',
                duration: Duration.zero,
              ),
            ),
          );
          await tester.pump();

          expect(
            find.byKey(const Key('celebration_confetti_painter')),
            findsNothing,
          );
          final overlayState = tester.state<CelebrationOverlayState>(
            find.byType(CelebrationOverlay),
          );
          expect(overlayState.shouldAnimate, isFalse);
        },
      );
    });

    // =========================================================================
    // 3. Accessible touch targets (minimum 48x48 dp) (A11Y-2)
    // =========================================================================
    group('3. Accessible touch targets (minimum 48x48 dp) (A11Y-2)', () {
      testWidgets('CuteCheckbox satisfies minimum 48x48 dp touch target', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          wrapWithApp(
            wrapWithScaffold: true,
            child: Center(
              child: CuteCheckbox(
                value: false,
                onChanged: (_) {},
                animal: MascotAnimal.cat,
              ),
            ),
          ),
        );
        await tester.pump();

        final size = tester.getSize(find.byType(CuteCheckbox));
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        handle.dispose();
      });

      testWidgets(
        'MascotCustomizationPage: ChoiceChips e botões atendem dimensões mínimas >= 48dp',
        (tester) async {
          setScreenSize(tester);

          final controller = MascotCustomizationController(
            repository: fakeMascotRepo,
            initialConfig: MascotConfig.defaultMomo,
          );

          await tester.pumpWidget(
            wrapWithApp(
              child: MascotCustomizationPage(
                controller: controller,
                resolver: const _FakeResolver(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Action buttons
          final saveButtonSize = tester.getSize(
            find.byKey(const Key('mascot_save_button')),
          );
          expect(saveButtonSize.height, greaterThanOrEqualTo(48.0));

          final cancelButtonSize = tester.getSize(
            find.byKey(const Key('mascot_cancel_button')),
          );
          expect(cancelButtonSize.height, greaterThanOrEqualTo(48.0));

          // Chips de animais
          for (final animal in MascotAnimal.values) {
            final chipFinder = find.byKey(Key('mascot_animal_${animal.name}'));
            expect(chipFinder, findsOneWidget);
            final chipSize = tester.getSize(chipFinder);
            expect(chipSize.height, greaterThanOrEqualTo(48.0));
            expect(chipSize.width, greaterThanOrEqualTo(48.0));
          }

          // Chips de paletas
          for (final palette in MascotPalette.values) {
            final chipFinder = find.byKey(
              Key('mascot_palette_${palette.name}'),
            );
            expect(chipFinder, findsOneWidget);
            final chipSize = tester.getSize(chipFinder);
            expect(chipSize.height, greaterThanOrEqualTo(48.0));
            expect(chipSize.width, greaterThanOrEqualTo(48.0));
          }

          // Accessory chips
          for (final accessory in MascotAccessory.values) {
            final chipFinder = find.byKey(
              Key('mascot_accessory_${accessory.name}'),
            );
            expect(chipFinder, findsOneWidget);
            final chipSize = tester.getSize(chipFinder);
            expect(chipSize.height, greaterThanOrEqualTo(48.0));
            expect(chipSize.width, greaterThanOrEqualTo(48.0));
          }

          controller.dispose();
        },
      );

      testWidgets(
        'OnboardingPage: Botões de navegação atendem dimensões mínimas >= 48dp',
        (tester) async {
          setScreenSize(tester);

          await tester.pumpWidget(wrapWithApp(child: const OnboardingPage()));
          await tester.pumpAndSettle();

          final nextButtonSize = tester.getSize(
            find.byKey(const Key('onboarding_next_button')),
          );
          expect(nextButtonSize.height, greaterThanOrEqualTo(48.0));

          final skipButtonFinder = find.byKey(
            const Key('onboarding_skip_button'),
          );
          if (skipButtonFinder.evaluate().isNotEmpty) {
            final skipButtonSize = tester.getSize(skipButtonFinder);
            expect(skipButtonSize.height, greaterThanOrEqualTo(48.0));
          }
        },
      );

      testWidgets('Interactive MascotWidget meets minimum 48x48 dp target', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          wrapWithApp(
            wrapWithScaffold: true,
            child: Center(
              child: MascotWidget(
                config: MascotConfig.defaultMomo,
                expression: MascotExpression.neutral,
                size: 64,
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        final mascotSize = tester.getSize(find.byType(MascotWidget));
        expect(mascotSize.width, greaterThanOrEqualTo(48.0));
        expect(mascotSize.height, greaterThanOrEqualTo(48.0));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        handle.dispose();
      });
    });
  });
}
