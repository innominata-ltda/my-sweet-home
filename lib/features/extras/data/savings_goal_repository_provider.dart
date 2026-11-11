import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_savings_goal_repository.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/savings_goal_repository.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return DriftSavingsGoalRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  );
});
