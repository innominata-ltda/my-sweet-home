import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/extras/data/savings_goal_repository_provider.dart';
import 'package:my_sweet_home/features/extras/domain/models/savings_goal.dart';
import 'package:my_sweet_home/features/extras/domain/policies/neutral_economy_policy.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/savings_goal_repository.dart';

class EconomyState {
  final bool isLoading;
  final Failure? failure;
  final YearMonth month;
  final SavingsGoal? goal;
  final MonthSummary? monthSummary;
  final NeutralEconomyAssessment? assessment;

  const EconomyState({
    this.isLoading = false,
    this.failure,
    required this.month,
    this.goal,
    this.monthSummary,
    this.assessment,
  });

  EconomyState copyWith({
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    YearMonth? month,
    SavingsGoal? goal,
    MonthSummary? monthSummary,
    NeutralEconomyAssessment? assessment,
  }) {
    return EconomyState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      month: month ?? this.month,
      goal: goal ?? this.goal,
      monthSummary: monthSummary ?? this.monthSummary,
      assessment: assessment ?? this.assessment,
    );
  }
}

class EconomyController extends ValueNotifier<EconomyState> {
  final SavingsGoalRepository _savingsGoalRepo;
  final MonthSummaryRepository _monthSummaryRepo;

  EconomyController({
    required this._savingsGoalRepo,
    required this._monthSummaryRepo,
    required YearMonth initialMonth,
  }) : super(EconomyState(month: initialMonth)) {
    load(initialMonth);
  }

  Future<void> load(YearMonth month) async {
    value = value.copyWith(isLoading: true, clearFailure: true, month: month);

    final goalResult = await _savingsGoalRepo.getGoal(month);
    final summaryResult = await _monthSummaryRepo.summarize(month);

    if (goalResult is Err) {
      value = value.copyWith(
        isLoading: false,
        failure: (goalResult as Err).failure,
      );
      return;
    }
    if (summaryResult is Err) {
      value = value.copyWith(
        isLoading: false,
        failure: (summaryResult as Err).failure,
      );
      return;
    }

    final goal = (goalResult as Ok<SavingsGoal?, Failure>).value;
    final summary = (summaryResult as Ok<MonthSummary, Failure>).value;

    final assessment = NeutralEconomyPolicy.evaluate(
      goal: goal,
      monthSummary: summary,
    );

    value = value.copyWith(
      isLoading: false,
      goal: goal,
      monthSummary: summary,
      assessment: assessment,
    );
  }

  Future<void> setGoal(Money target) async {
    final month = value.month;
    value = value.copyWith(isLoading: true, clearFailure: true);

    final result = await _savingsGoalRepo.setGoal(month, target);
    if (result is Err) {
      value = value.copyWith(
        isLoading: false,
        failure: (result as Err).failure,
      );
      return;
    }

    await load(month);
  }
}

final economyControllerProvider = Provider.autoDispose<EconomyController>((
  ref,
) {
  final month = ref.watch(currentMonthProvider);
  final savingsGoalRepo = ref.watch(savingsGoalRepositoryProvider);
  final monthSummaryRepo = ref.watch(monthSummaryRepositoryProvider);

  final controller = EconomyController(
    savingsGoalRepo: savingsGoalRepo,
    monthSummaryRepo: monthSummaryRepo,
    initialMonth: month,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
