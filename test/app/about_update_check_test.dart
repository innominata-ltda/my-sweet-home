import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/dashboard_screen.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';
import 'package:my_sweet_home/core/update/app_update_providers.dart';
import 'package:my_sweet_home/data/database/database.dart' hide ShoppingList;
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/bills/data/bills_repository_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/due_bills_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/month_balance_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_controller.dart';
import 'package:my_sweet_home/features/extras/presentation/today_tasks_widget_providers.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/settings/presentation/about_page.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/tasks/data/task_repository_provider.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart' as task_models;
import 'package:my_sweet_home/features/tasks/domain/repositories.dart';

import '../fakes/fake_app_update_port.dart';
import '../fakes/fake_bill_payment_repository.dart';
import '../fakes/fake_bill_repository.dart';
import '../fakes/fake_clock.dart';
import '../fakes/sequential_id_generator.dart';

class _FakeMonthSummaryRepo implements MonthSummaryRepository {
  @override
  Future<Result<MonthSummary, Failure>> summarize(YearMonth m) async => Ok(
    MonthSummary(
      month: m,
      actual: const Money(1000),
      budget: const Money(5000),
      remaining: const Money(4000),
      byCategory: const [],
      monthsOfHistory: 1,
    ),
  );
}

class _FakeTaskRepo implements TaskRepository {
  @override
  Future<Result<List<task_models.Task>, Failure>> inRange(
    task_models.DateTimeRange r,
  ) async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShoppingRepo implements ShoppingListRepository {
  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async => const Ok([]);

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async => const Ok(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BlockingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException('Airplane mode: network blocked');
  }
}

void main() {
  group('SPEC-001 / T-G05 — App Update Integration Tests', () {
    late AppDatabase db;
    late FakeClock clock;
    late FakeAppUpdatePort fakePort;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 10, 24, 10));
      fakePort = FakeAppUpdatePort(
        updateAvailable: true,
        availableVersionLabel: '0.2.0',
        availableVersionCode: 20,
      );
    });

    Widget createTestApp({required Widget home}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          appUpdatePortProvider.overrideWithValue(fakePort),
          mascotConfigStreamProvider.overrideWith(
            (ref) => Stream.value(MascotConfig.defaultMomo),
          ),
          monthSummaryRepositoryProvider.overrideWithValue(
            _FakeMonthSummaryRepo(),
          ),
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepo()),
          billRepositoryProvider.overrideWithValue(
            FakeBillRepository(SequentialIdGenerator()),
          ),
          billPaymentRepositoryProvider.overrideWithValue(
            FakeBillPaymentRepository(),
          ),
          shoppingListRepositoryProvider.overrideWithValue(_FakeShoppingRepo()),
          monthBalanceWidgetControllerProvider.overrideWith(
            (ref, params) => MonthBalanceWidgetController(
              monthSummaryRepository: params.monthSummaryRepository,
            ),
          ),
          dueBillsWidgetControllerProvider.overrideWith(
            (ref, params) => DueBillsWidgetController(
              billRepository: params.billRepository,
              paymentRepository: params.paymentRepository,
            ),
          ),
          todayTasksWidgetControllerProvider.overrideWith(
            (ref, params) => TodayTasksWidgetController(
              taskRepository: params.taskRepository,
            ),
          ),
          shoppingListWidgetControllerProvider.overrideWith(
            (ref, params) => ShoppingListWidgetController(
              shoppingListRepository: params.shoppingListRepository,
            ),
          ),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );
    }

    testWidgets(
      'CA-12.1: When Dashboard opens with update available, displays post-first-frame dialog and Update now triggers startUpdate',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp(home: const DashboardScreen()));
        // Primeiro frame do Dashboard
        await tester.pump();
        // Post frame callback triggers check and opens dialog
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsOneWidget);
        expect(find.textContaining('0.2.0'), findsOneWidget);
        expect(find.text('Atualizar agora'), findsOneWidget);
        expect(find.text('Agora não'), findsOneWidget);

        // Toca em "Atualizar agora"
        await tester.tap(find.text('Atualizar agora'));
        await tester.pumpAndSettle();

        expect(fakePort.startUpdateCallCount, 1);
        expect(find.text('Atualização disponível'), findsNothing);
      },
    );

    testWidgets(
      'CA-12.2: Tapping Not now closes dialog and does not re-display before 24h; after 24h displays again',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp(home: const DashboardScreen()));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsOneWidget);

        // Taps not-now button
        await tester.tap(find.text('Agora não'));
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsNothing);
        expect(fakePort.startUpdateCallCount, 0);

        // Reabre o Dashboard 12 horas depois (cooldown ainda ativo)
        clock.advance(const Duration(hours: 12));
        await tester.pumpWidget(
          createTestApp(home: const DashboardScreen(key: Key('dash_2'))),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsNothing);

        // Advances another 13 hours (total 25 hours > 24h cooldown)
        clock.advance(const Duration(hours: 13));
        await tester.pumpWidget(
          createTestApp(home: const DashboardScreen(key: Key('dash_3'))),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsOneWidget);
      },
    );

    testWidgets(
      'CA-12.3: Device in airplane mode / store unavailable with blocking HttpOverrides opens without error and without dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;

        fakePort.failure = const AppUpdateStoreUnavailable();

        await HttpOverrides.runWithHttpOverrides(() async {
          await tester.pumpWidget(createTestApp(home: const DashboardScreen()));
          await tester.pump();
          await tester.pumpAndSettle();

          expect(find.text('Atualização disponível'), findsNothing);
          expect(find.byType(DashboardScreen), findsOneWidget);
        }, _BlockingHttpOverrides());
      },
    );

    testWidgets(
      'CA-12.4: In Settings → About, Check for updates displays clear feedback',
      (tester) async {
        // Case 1: Latest version already installed
        fakePort.updateAvailable = false;

        await tester.pumpWidget(createTestApp(home: const AboutPage()));
        await tester.pumpAndSettle();

        final checkButton = find.text('Verificar atualizações');
        expect(checkButton, findsOneWidget);

        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Você já está na versão mais recente'),
          findsOneWidget,
        );

        // Case 2: New version available in store
        fakePort.updateAvailable = true;
        fakePort.availableVersionLabel = '0.3.0';

        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsOneWidget);
        expect(find.textContaining('0.3.0'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-Play Store install suppresses Dashboard dialog and disables About update tile with notice',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakePort.installedFromPlayStore = false;
        fakePort.updateAvailable = true;

        await tester.pumpWidget(createTestApp(home: const DashboardScreen()));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Atualização disponível'), findsNothing);

        await tester.pumpWidget(createTestApp(home: const AboutPage()));
        await tester.pumpAndSettle();

        final updateTileFinder = find.byKey(const Key('about_update_tile'));
        expect(updateTileFinder, findsOneWidget);
        final updateTile = tester.widget<ListTile>(updateTileFinder);
        expect(updateTile.enabled, isFalse);
        expect(
          find.text(
            'Disponível apenas para instalações feitas pela Google Play',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AboutPage GitHub tile opens repository URL and falls back to clipboard on failure',
      (tester) async {
        await tester.pumpWidget(createTestApp(home: const AboutPage()));
        await tester.pumpAndSettle();

        final githubTile = find.byKey(const Key('about_github_tile'));
        expect(githubTile, findsOneWidget);
        expect(find.text('Código-fonte no GitHub'), findsOneWidget);

        await tester.tap(githubTile);
        await tester.pumpAndSettle();

        expect(fakePort.openedUrls, [AboutPage.githubRepoUrl]);

        // Fallback: openExternalUrl fails -> copies to clipboard + SnackBar
        String? copiedText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        fakePort.openExternalUrlFailure = const AppUpdateFailed('No browser');
        await tester.tap(githubTile);
        await tester.pumpAndSettle();

        expect(copiedText, AboutPage.githubRepoUrl);
        expect(
          find.text('Link do GitHub copiado para a área de transferência.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AboutPage wiki tile opens documentation URL and falls back to clipboard on failure',
      (tester) async {
        await tester.pumpWidget(createTestApp(home: const AboutPage()));
        await tester.pumpAndSettle();

        final wikiTile = find.byKey(const Key('about_wiki_tile'));
        expect(wikiTile, findsOneWidget);
        expect(find.text('Documentação e privacidade'), findsOneWidget);

        await tester.tap(wikiTile);
        await tester.pumpAndSettle();

        expect(fakePort.openedUrls, [AboutPage.wikiUrl]);

        String? copiedText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        fakePort.openExternalUrlFailure = const AppUpdateFailed('No browser');
        await tester.tap(wikiTile);
        await tester.pumpAndSettle();

        expect(copiedText, AboutPage.wikiUrl);
        expect(
          find.text(
            'Link da documentação copiado para a área de transferência.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
