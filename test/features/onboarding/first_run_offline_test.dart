import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/app.dart';
import 'package:my_sweet_home/app/bootstrap.dart';
import 'package:my_sweet_home/app/error_boundary.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/app/router.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_payment_repository.dart';
import 'package:my_sweet_home/features/bills/data/repositories/drift_bill_repository.dart';
import 'package:my_sweet_home/features/bills/domain/bill_materializer.dart';
import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/data/recurrence/expense_materializer.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_page.dart';

/// Deterministic HttpOverrides that blocks any network connection attempt,
/// simulating a device in airplane mode (CA-6.1).
class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Modo avião ativo (CA-6.1): nenhuma requisição de rede é permitida.',
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('T-V1 - App opens in airplane mode, no network, skippable onboarding (CA-6.1)', () {
    test('HttpOverrides blocks network calls with SocketException in airplane mode', () {
      expect(
        () =>
            HttpClient().openUrl('GET', Uri.parse('https://innominata.com.br')),
        throwsA(isA<SocketException>()),
      );
    });

    test('Complete bootstrap and database initialization execute in airplane mode without network', () async {
      final db = AppDatabase.memory();
      const clock = SystemClock();
      const idGen = UuidV7Generator();

      final expenseMat = ExpenseMaterializer(db: db, idGenerator: idGen);
      final billRepo = DriftBillRepository(db, idGenerator: idGen);
      final paymentRepo = DriftBillPaymentRepository(db);
      final billMat = BillMaterializer(
        billRepo: billRepo,
        paymentRepo: paymentRepo,
        dueDatePolicy: const StandardDueDatePolicy(),
      );

      final materializerUseCase = DefaultMaterializeRecurrences(
        materializers: [expenseMat, billMat],
        clock: clock,
      );
      final trashPolicy = DriftTrashPolicy.system(db: db);

      // Executes full bootstrap in airplane mode without network requests
      await bootstrap(materializerUseCase, trashPolicy: trashPolicy);
      await db.close();
    });

    testWidgets(
      'Integrated first run: opens onboarding with real router in airplane mode and Skip navigates to main screen in 1 tap (CA-6.1, RN-012)',
      (tester) async {
        final originalBuilder = ErrorWidget.builder;
        final db = AppDatabase.memory();
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });

        try {
          setupGlobalErrorHandling();

          // Configura a rota inicial para /onboarding via router real
          final router = container.read(appRouterProvider);
          router.go('/onboarding');

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MySweetHomeApp(),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Verifies Onboarding page is displayed on first run
          expect(find.byType(OnboardingPage), findsOneWidget);
          expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);
          expect(
            find.text(
              'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!',
            ),
            findsOneWidget,
          );

          // 2. No personal data input field exists (RN-012)
          expect(find.byType(TextField), findsNothing);
          expect(find.byType(TextFormField), findsNothing);
          expect(find.byType(EditableText), findsNothing);

          // 3. Locates "Skip" button
          final skipButton = find.byKey(const Key('onboarding_skip_button'));
          expect(skipButton, findsOneWidget);
          expect(find.text('Pular introdução'), findsOneWidget);

          // 4. Taps "Skip" (skippable in a single tap - RN-012, CA-6.1)
          await tester.tap(skipButton);
          await tester.pumpAndSettle();

          // 5. Verifies transition to main screen (Dashboard) without network errors
          expect(find.byType(OnboardingPage), findsNothing);
          expect(find.text('My Sweet Home'), findsOneWidget);
        } finally {
          ErrorWidget.builder = originalBuilder;
        }
      },
    );

    testWidgets(
      'Integrated first run: navigates through screens in airplane mode and Get Started button completes onboarding to Dashboard (CA-6.1)',
      (tester) async {
        final originalBuilder = ErrorWidget.builder;
        final db = AppDatabase.memory();
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });

        try {
          setupGlobalErrorHandling();

          final router = container.read(appRouterProvider);
          router.go('/onboarding');

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MySweetHomeApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Passo 1: Boas-vindas
          expect(find.text('Oi! Eu sou a Momo 💕'), findsOneWidget);
          final nextButton = find.byKey(const Key('onboarding_next_button'));
          expect(nextButton, findsOneWidget);
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 2: Despesas
          expect(
            find.text('Aqui a gente cuida do dinheirinho juntas'),
            findsOneWidget,
          );
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 3: Comprinhas
          expect(find.text('E também das comprinhas!'), findsOneWidget);
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 4: Tarefas
          expect(
            find.text('Não esquece das tarefinhas do dia'),
            findsOneWidget,
          );
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 5: Contas
          expect(
            find.text('Eu te aviso quando algo precisa de atenção'),
            findsOneWidget,
          );
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 6: Rotina da casa (SPEC-014)
          expect(find.text('Monte sua rotina da casa'), findsOneWidget);
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Passo 7: Checklist da Primeira Casa (SPEC-015)
          expect(find.text('Está montando sua casa nova?'), findsOneWidget);
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Step 8: Customization
          expect(
            find.text('Pode personalizar meu visual quando quiser!'),
            findsOneWidget,
          );
          expect(
            find.text('Quer personalizar meu visual agora?'),
            findsOneWidget,
          );
          final startButton = find.byKey(const Key('onboarding_start_button'));
          expect(startButton, findsOneWidget);

          // Tap Start
          await tester.tap(startButton);
          await tester.pumpAndSettle();

          // Completed successfully on main screen (Dashboard) without network requests
          expect(find.byType(OnboardingPage), findsNothing);
          expect(find.text('My Sweet Home'), findsOneWidget);
        } finally {
          ErrorWidget.builder = originalBuilder;
        }
      },
    );

    testWidgets(
      'Integrated first run: Skip button on second screen also navigates to Dashboard without network requests (CA-6.1)',
      (tester) async {
        final originalBuilder = ErrorWidget.builder;
        final db = AppDatabase.memory();
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });

        try {
          setupGlobalErrorHandling();

          final router = container.read(appRouterProvider);
          router.go('/onboarding');

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MySweetHomeApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Advance to second screen
          await tester.tap(find.byKey(const Key('onboarding_next_button')));
          await tester.pumpAndSettle();
          expect(
            find.text('Aqui a gente cuida do dinheirinho juntas'),
            findsOneWidget,
          );

          // Pula a partir da segunda tela
          await tester.tap(find.byKey(const Key('onboarding_skip_button')));
          await tester.pumpAndSettle();

          // Chega no Dashboard sem erros de rede
          expect(find.byType(OnboardingPage), findsNothing);
          expect(find.text('My Sweet Home'), findsOneWidget);
        } finally {
          ErrorWidget.builder = originalBuilder;
        }
      },
    );
  });
}
