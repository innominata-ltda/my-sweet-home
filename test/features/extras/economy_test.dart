import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_savings_goal_repository.dart';
import 'package:my_sweet_home/features/extras/data/repositories/fake_savings_goal_repository.dart';
import 'package:my_sweet_home/features/extras/data/savings_goal_repository_provider.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';
import 'package:my_sweet_home/features/extras/domain/policies/neutral_economy_policy.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_providers.dart';
import 'package:my_sweet_home/features/extras/presentation/economy_screen.dart';

void main() {
  group('T-08 — Meta de economia com linguagem neutra (RF-103, RN-254)', () {
    test('RN-254: Evaluation with null or non-positive goal returns neutral factual message', () {
      final summary = MonthSummary(
        month: const YearMonth('2026-10'),
        actual: const Money(100000),
        budget: const Money(150000),
        remaining: const Money(50000),
        byCategory: const [],
        monthsOfHistory: 1,
      );

      final resultNull = NeutralEconomyPolicy.evaluate(
        goal: null,
        monthSummary: summary,
      );
      expect(
        resultNull.statusMessage,
        contains('Nenhuma meta de economia definida'),
      );
      expect(resultNull.progressRatio, isNull);

      final resultNeg = NeutralEconomyPolicy.evaluate(
        goal: const SavingsGoal(
          month: YearMonth('2026-10'),
          target: Money(-1000),
        ),
        monthSummary: summary,
      );
      expect(
        resultNeg.statusMessage,
        contains('Nenhuma meta de economia definida'),
      );
      expect(resultNeg.progressRatio, isNull);
    });

    test(
      'EconomyState copyWith limpa falha anterior ao passar clearFailure: true',
      () {
        final stateWithFailure = EconomyState(
          month: const YearMonth('2026-10'),
          failure: const StorageFailure(detail: 'Erro no banco'),
        );

        final clearedState = stateWithFailure.copyWith(
          isLoading: true,
          clearFailure: true,
        );

        expect(clearedState.failure, isNull);
        expect(clearedState.isLoading, isTrue);
      },
    );

    test(
      'RN-254: Avaliação com meta e orçamento calcula progresso em tom neutro',
      () {
        final goal = SavingsGoal(
          month: const YearMonth('2026-10'),
          target: const Money(50000), // R$ 500,00
        );

        final summary = MonthSummary(
          month: const YearMonth('2026-10'),
          actual: const Money(100000), // R$ 1.000,00 gastos
          budget: const Money(
            130000,
          ), // R$ 1,300.00 budgeted -> R$ 300.00 saved
          remaining: const Money(30000),
          byCategory: const [
            CategorySlice(
              categoryId: CategoryId('alimentacao'),
              actual: Money(70000),
              budget: Money(80000),
              remaining: Money(10000),
            ),
          ],
          monthsOfHistory: 2,
        );

        final assessment = NeutralEconomyPolicy.evaluate(
          goal: goal,
          monthSummary: summary,
        );

        expect(assessment.actualSaved?.cents, equals(30000));
        expect(assessment.progressRatio, closeTo(0.6, 0.01)); // 300 / 500 = 60%
        expect(
          assessment.statusMessage,
          contains(
            'Economia de R\$ 300,00 alcançada de uma meta de R\$ 500,00 (60%).',
          ),
        );

        // Verify there are no guilt, nagging, or social comparison terms
        final forbiddenWords = [
          'culpa',
          'deveria',
          'errou',
          'ruim',
          'vergonha',
          'outras pessoas',
          'parabéns',
        ];
        for (final word in forbiddenWords) {
          expect(
            assessment.statusMessage.toLowerCase().contains(word),
            isFalse,
          );
        }
      },
    );

    test('RN-254: Expenses over budget are reported factually without guilt or nagging', () {
      final goal = SavingsGoal(
        month: const YearMonth('2026-10'),
        target: const Money(20000), // R$ 200,00
      );

      final summary = MonthSummary(
        month: const YearMonth('2026-10'),
        actual: const Money(150000), // R$ 1.500,00
        budget: const Money(120000), // R$ 1.200,00 -> excedeu em R$ 300,00
        remaining: const Money(-30000),
        byCategory: const [],
        monthsOfHistory: 1,
      );

      final assessment = NeutralEconomyPolicy.evaluate(
        goal: goal,
        monthSummary: summary,
      );

      expect(assessment.actualSaved?.cents, equals(-30000));
      expect(
        assessment.statusMessage,
        contains('Gastos realizados excederam o orçamento em R\$ 300,00'),
      );

      // Testar dicas contextuais neutras
      expect(assessment.contextualTips, isNotEmpty);
      for (final tip in assessment.contextualTips) {
        expect(tip.toLowerCase().contains('culpa'), isFalse);
        expect(tip.toLowerCase().contains('errou'), isFalse);
      }
    });

    test('RF-103: Contextual tips generated point out category proportions and budget usage', () {
      final goal = SavingsGoal(
        month: const YearMonth('2026-10'),
        target: const Money(30000),
      );

      final summary = MonthSummary(
        month: const YearMonth('2026-10'),
        actual: const Money(100000),
        budget: const Money(150000),
        remaining: const Money(50000),
        byCategory: const [
          CategorySlice(
            categoryId: CategoryId('moradia'),
            actual: Money(60000),
            budget: Money(70000),
            remaining: Money(10000),
          ),
        ],
        monthsOfHistory: 3,
      );

      final assessment = NeutralEconomyPolicy.evaluate(
        goal: goal,
        monthSummary: summary,
      );

      expect(assessment.contextualTips.length, greaterThanOrEqualTo(2));
      expect(
        assessment.contextualTips.any((t) => t.contains('moradia')),
        isTrue,
      );
      expect(
        assessment.contextualTips.any((t) => t.contains('meta de economia')),
        isTrue,
      );
    });

    test(
      'FakeSavingsGoalRepository salva e recupera meta de economia por mês',
      () async {
        final repo = FakeSavingsGoalRepository();
        final month = const YearMonth('2026-10');

        final initial = await repo.getGoal(month);
        expect((initial as Ok).value, isNull);

        final saved = await repo.setGoal(month, const Money(40000));
        expect(
          (saved as Ok<SavingsGoal, Failure>).value.target.cents,
          equals(40000),
        );

        final retrieved = await repo.getGoal(month);
        expect(
          (retrieved as Ok<SavingsGoal?, Failure>).value?.target.cents,
          equals(40000),
        );
      },
    );

    test(
      'DriftSavingsGoalRepository armazena meta em tabela settings do SQLite',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final repo = DriftSavingsGoalRepository(db);
        final month = const YearMonth('2026-10');

        final getBefore = await repo.getGoal(month);
        expect((getBefore as Ok).value, isNull);

        final setRes = await repo.setGoal(month, const Money(75000));
        expect(
          (setRes as Ok<SavingsGoal, Failure>).value.target.cents,
          equals(75000),
        );

        final getAfter = await repo.getGoal(month);
        expect(
          (getAfter as Ok<SavingsGoal?, Failure>).value?.target.cents,
          equals(75000),
        );
      },
    );

    testWidgets(
      'EconomyScreen exibe meta de economia e salva nova meta via diálogo',
      (tester) async {
        final fakeSavingsRepo = FakeSavingsGoalRepository();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              savingsGoalRepositoryProvider.overrideWithValue(fakeSavingsRepo),
            ],
            child: const MaterialApp(home: EconomyScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar elementos da tela
        expect(find.text('Modo Economia'), findsOneWidget);
        expect(find.text('Nenhuma meta definida'), findsOneWidget);
        expect(find.text('Dicas Contextuais'), findsOneWidget);

        // Open goal dialog
        await tester.tap(find.text('Definir Meta de Economia'));
        await tester.pumpAndSettle();

        expect(find.text('Definir Meta de Economia'), findsWidgets);

        // Digitar valor 300,00
        await tester.enterText(find.byType(TextField), '300,00');
        await tester.pumpAndSettle();

        // Clicar em Salvar Meta
        await tester.tap(find.text('Salvar Meta'));
        await tester.pumpAndSettle();

        // Verificar meta atualizada na tela
        expect(find.text('R\$ 300,00'), findsOneWidget);
      },
    );
  });
}
