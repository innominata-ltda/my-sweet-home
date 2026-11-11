import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/expenses/domain/models/month_summary.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/month_summary_repository.dart';

sealed class MonthBalanceWidgetState {}

class MonthBalanceWidgetLoading extends MonthBalanceWidgetState {}

class MonthBalanceWidgetSuccess extends MonthBalanceWidgetState {
  final MonthSummary summary;
  final bool hideValues;

  MonthBalanceWidgetSuccess({required this.summary, this.hideValues = false});
}

class MonthBalanceWidgetError extends MonthBalanceWidgetState {
  final Failure failure;

  MonthBalanceWidgetError(this.failure);
}

/// Controller for month balance widget (RF-102, RN-253, CA-3.2).
class MonthBalanceWidgetController
    extends ValueNotifier<MonthBalanceWidgetState> {
  MonthBalanceWidgetController({
    required this._monthSummaryRepository,
    Clock? clock,
    this._hideValues = false,
  }) : _clock = clock ?? const SystemClock(),
       super(MonthBalanceWidgetLoading()) {
    unawaited(load());
  }

  final MonthSummaryRepository _monthSummaryRepository;
  final Clock _clock;
  bool _hideValues;
  bool _disposed = false;

  bool get hideValues => _hideValues;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(MonthBalanceWidgetState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  void setHideValues(bool value) {
    if (_hideValues != value) {
      _hideValues = value;
      if (this.value is MonthBalanceWidgetSuccess) {
        final current = this.value as MonthBalanceWidgetSuccess;
        this.value = MonthBalanceWidgetSuccess(
          summary: current.summary,
          hideValues: _hideValues,
        );
      }
    }
  }

  Future<void> load() async {
    value = MonthBalanceWidgetLoading();

    final now = _clock.nowUtc();
    final result = await _monthSummaryRepository.summarize(YearMonth.of(now));

    if (result is Err) {
      value = MonthBalanceWidgetError((result as Err).failure);
      return;
    }

    final summary = (result as Ok<MonthSummary, Failure>).value;
    value = MonthBalanceWidgetSuccess(
      summary: summary,
      hideValues: _hideValues,
    );
  }
}
