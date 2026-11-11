import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

/// Canonical provider of current month based on [clockProvider].
///
/// Maintained as a simple [Provider<YearMonth>] for compatibility with
/// [overrideWithValue] em testes de unidade e testes golden.
final currentMonthProvider = Provider<YearMonth>((ref) {
  final clock = ref.watch(clockProvider);
  return YearMonth.of(clock.nowUtc().toLocal());
});

/// Notifier for manual selection and month navigation on expenses screen.
class SelectedYearMonthNotifier extends Notifier<YearMonth?> {
  @override
  YearMonth? build() => null;

  void setMonth(YearMonth month) => state = month;
  void clear() => state = null;
}

final selectedYearMonthProvider =
    NotifierProvider<SelectedYearMonthNotifier, YearMonth?>(
      SelectedYearMonthNotifier.new,
    );
