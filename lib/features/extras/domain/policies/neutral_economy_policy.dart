import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';

/// Evaluation result of Economy Mode in neutral language (RN-254).
class NeutralEconomyAssessment {
  final SavingsGoal? goal;
  final MonthSummary monthSummary;
  final Money? actualSaved;
  final double? progressRatio;
  final String statusMessage;
  final List<String> contextualTips;

  const NeutralEconomyAssessment({
    required this.goal,
    required this.monthSummary,
    required this.actualSaved,
    required this.progressRatio,
    required this.statusMessage,
    required this.contextualTips,
  });
}

/// Evaluation policy for Economy Mode with strictly neutral language (RN-254).
///
/// **RN-254:** Economy mode MUST show progress towards the goal with
/// neutral language and MUST NOT use nagging, guilt or social comparison tone.
class NeutralEconomyPolicy {
  /// Evaluates savings goal and monthly summary producing a neutral and factual report.
  static NeutralEconomyAssessment evaluate({
    required SavingsGoal? goal,
    required MonthSummary monthSummary,
  }) {
    // 1. Savings achieved: if total budget exists, saved = budget - spent
    final Money? actualSaved = monthSummary.budget != null
        ? monthSummary.remaining
        : null;

    double? progressRatio;
    if (goal != null && goal.target.cents > 0 && actualSaved != null) {
      progressRatio = actualSaved.cents / goal.target.cents;
    }

    // 2. Factual progress message without nagging/guilt/social comparison (RN-254)
    final String statusMessage;
    if (goal == null || goal.target.cents <= 0) {
      statusMessage = 'Nenhuma meta de economia definida para este mês.';
    } else if (monthSummary.budget == null) {
      statusMessage =
          'Meta definida em ${goal.target.formatPtBr()}. Defina um orçamento total no mês para acompanhar o progresso.';
    } else {
      final ratio = progressRatio ?? 0.0;
      final percentage = (ratio * 100).toStringAsFixed(0);
      if (actualSaved!.cents >= 0) {
        statusMessage =
            'Economia de ${actualSaved.formatPtBr()} alcançada de uma meta de ${goal.target.formatPtBr()} ($percentage%).';
      } else {
        final exceeded = Money(actualSaved.cents.abs()).formatPtBr();
        statusMessage =
            'Gastos realizados excederam o orçamento em $exceeded. Meta de economia: ${goal.target.formatPtBr()}.';
      }
    }

    // 3. Dicas contextuais factuais e neutras (RF-103, RN-254)
    final tips = <String>[];

    // Tip 1: Budget utilization
    if (monthSummary.budget != null && monthSummary.budget!.cents > 0) {
      final usedPct =
          ((monthSummary.actual.cents / monthSummary.budget!.cents) * 100)
              .toStringAsFixed(0);
      tips.add(
        'Foram utilizados $usedPct% do orçamento total do mês (${monthSummary.actual.formatPtBr()} de ${monthSummary.budget!.formatPtBr()}).',
      );
    }

    // Tip 2: Category breakdown if categories have expenses
    if (monthSummary.byCategory.isNotEmpty && monthSummary.actual.cents > 0) {
      final sortedSlices = List<CategorySlice>.from(monthSummary.byCategory)
        ..sort((a, b) => b.actual.cents.compareTo(a.actual.cents));
      final top = sortedSlices.first;
      final topPct = ((top.actual.cents / monthSummary.actual.cents) * 100)
          .toStringAsFixed(0);
      tips.add(
        'A maior proporção dos gastos do mês está na categoria ${top.categoryId.value} ($topPct% do total).',
      );
    }

    // Tip 3: Progress towards goal
    if (goal != null &&
        goal.target.cents > 0 &&
        actualSaved != null &&
        actualSaved.cents >= 0) {
      final remainingToGoal = goal.target.cents - actualSaved.cents;
      if (remainingToGoal > 0) {
        tips.add(
          'Faltam ${Money(remainingToGoal).formatPtBr()} para atingir a meta de economia estabelecida.',
        );
      } else {
        tips.add('A meta de economia estabelecida para o mês foi alcançada.');
      }
    }

    if (tips.isEmpty) {
      tips.add(
        'Registre suas despesas e orçamento para visualizar análises contextuais do mês.',
      );
    }

    return NeutralEconomyAssessment(
      goal: goal,
      monthSummary: monthSummary,
      actualSaved: actualSaved,
      progressRatio: progressRatio,
      statusMessage: statusMessage,
      contextualTips: List.unmodifiable(tips),
    );
  }
}
